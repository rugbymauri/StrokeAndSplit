import 'dart:async';

import 'package:clock/clock.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/foundation.dart' show debugPrint, immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/platform_providers.dart';
import 'ble/ble_rower_source.dart';
import 'ble/heart_rate_transport.dart';
import 'ble/reconnect.dart';
import 'erg_source.dart';
import 'erg_source_providers.dart';
import 'heart_rate_choice.dart';

enum HeartRateMonitorPhase {
  /// No strap is paired.
  notPaired,

  /// A strap is paired, but no rower over Bluetooth is connected, or the
  /// rower is connected and the app waits for its heart rate.
  ready,
  connecting,
  connected,
  reconnecting,

  /// The connection failed or could not be restored; see the failure.
  disconnected,

  /// The rower reports the heart rate, so the strap is not connected
  /// (Change heart-rate-from-rower, Design D1).
  fromRower,

  /// The user or the timeout gave the strap up until the rower connects anew
  /// (Change heart-rate-from-rower, Design D4).
  cancelled,
}

/// Why the strap is disconnected.
enum HeartRateMonitorFailure {
  /// The strap could not be reached, e.g. because it hangs on a watch.
  unreachable,

  /// The device offers no Heart Rate service.
  noHeartRateService,

  /// The connection dropped and could not be restored within 30 seconds.
  lost,
}

/// Where the paired strap stands (Design D7).
@immutable
class HeartRateMonitorState {
  const HeartRateMonitorState._(this.phase, this.monitor, [this.failure]);

  const HeartRateMonitorState.notPaired()
    : this._(HeartRateMonitorPhase.notPaired, null);

  /// The paired strap; null when none is paired.
  final FoundHeartRateMonitor? monitor;

  final HeartRateMonitorPhase phase;

  /// Why the strap is [HeartRateMonitorPhase.disconnected]; null otherwise.
  final HeartRateMonitorFailure? failure;

  @override
  bool operator ==(Object other) =>
      other is HeartRateMonitorState &&
      other.phase == phase &&
      other.monitor == monitor &&
      other.failure == failure;

  @override
  int get hashCode => Object.hash(phase, monitor, failure);

  @override
  String toString() =>
      'HeartRateMonitorState(${phase.name}, ${monitor?.name}${failure == null ? '' : ', $failure'})';
}

/// The paired strap and its connection.
///
/// Connects the strap once a rower over Bluetooth, PM5 or FTMS, is connected
/// and reported no heart rate of its own within [rowerHeartRateWait], and
/// feeds it into that source; never with the simulator or a replay. Disconnects the strap when the rower is stopped, the source
/// changes or the strap is forgotten. A failing strap never touches the
/// rower.
final heartRateMonitorProvider =
    NotifierProvider<HeartRateMonitorNotifier, HeartRateMonitorState>(
      HeartRateMonitorNotifier.new,
    );

class HeartRateMonitorNotifier extends Notifier<HeartRateMonitorState> {
  HeartRateMonitorNotifier({
    this.reconnectWindow = const Duration(seconds: 30),
    this.retryDelay = const Duration(seconds: 2),
    this.rowerHeartRateWait = const Duration(seconds: 5),
    this.cancelAfter = const Duration(seconds: 60),
  });

  final Duration reconnectWindow;
  final Duration retryDelay;

  /// How long the app waits for the rower's heart rate before it connects the
  /// strap (Design D3).
  final Duration rowerHeartRateWait;

  /// How long the notice of a disconnected strap waits for the user before
  /// the strap is given up (Design D4).
  final Duration cancelAfter;

  _StrapConnection? _connection;

  @override
  HeartRateMonitorState build() {
    _connection = null;
    final monitor = ref.watch(chosenHeartRateMonitorProvider);
    if (monitor == null) return const HeartRateMonitorState.notPaired();
    final source = ref.watch(activeErgSourceProvider);
    if (source is! BleRowerSource) {
      return HeartRateMonitorState._(HeartRateMonitorPhase.ready, monitor);
    }

    final connection = _StrapConnection(
      transport: ref.watch(heartRateTransportProvider),
      monitor: monitor,
      source: source,
      events: ref.watch(rowingEventsProvider),
      reconnectWindow: reconnectWindow,
      retryDelay: retryDelay,
      rowerHeartRateWait: rowerHeartRateWait,
      cancelAfter: cancelAfter,
      emit: (phase, [failure]) =>
          state = HeartRateMonitorState._(phase, monitor, failure),
    );
    _connection = connection;
    ref.onDispose(connection.close);
    // Starts after build, so the first state change happens outside of it.
    scheduleMicrotask(connection.follow);
    return HeartRateMonitorState._(HeartRateMonitorPhase.ready, monitor);
  }

  /// Tries again to connect the strap after it is disconnected, as long as
  /// the rower is connected.
  Future<void> retry() async => _connection?.retry();

  /// Gives the disconnected strap up until the rower connects anew.
  void cancel() => _connection?.cancel();
}

/// The strap connection that belongs to one rower source; replaced as soon
/// as the strap or the source changes.
class _StrapConnection {
  _StrapConnection({
    required this.transport,
    required this.monitor,
    required this.source,
    required this.events,
    required this.reconnectWindow,
    required this.retryDelay,
    required this.rowerHeartRateWait,
    required this.cancelAfter,
    required this._emit,
  });

  final HeartRateTransport transport;
  final FoundHeartRateMonitor monitor;
  final BleRowerSource source;

  /// The decoded events of [source], carrying the rower's heart rate.
  final Stream<RowingEvent> events;
  final Duration reconnectWindow;
  final Duration retryDelay;
  final Duration rowerHeartRateWait;
  final Duration cancelAfter;
  final void Function(
    HeartRateMonitorPhase phase, [
    HeartRateMonitorFailure? failure,
  ])
  _emit;

  var _phase = HeartRateMonitorPhase.ready;
  HeartRateLink? _link;
  StreamSubscription<ErgConnectionState>? _rowerStates;
  StreamSubscription<RowingEvent>? _events;

  /// Runs while the app waits for the rower's heart rate.
  Timer? _wait;

  /// Runs while the strap is disconnected and the notice waits for the user.
  Timer? _cancelTimer;

  /// When the last attached strap was detached; until [HeartRateDecoder.strapTimeout]
  /// later a heart rate may still be the strap's (Design D2).
  DateTime? _detachedAt;

  /// Counts the attempts; an attempt whose number is outdated gives up.
  var _attempt = 0;
  var _closed = false;

  void follow() {
    if (_closed) return;
    _rowerStates = source.connectionStates.listen(_onRowerState);
    _events = events.listen(_onEvent);
    _onRowerState(source.connectionState);
  }

  void _onRowerState(ErgConnectionState rower) {
    switch (rower) {
      case ErgConnectionState.connected:
        if (_phase == HeartRateMonitorPhase.ready && _wait == null) {
          _wait = Timer(rowerHeartRateWait, () {
            _wait = null;
            if (_phase == HeartRateMonitorPhase.ready &&
                source.connectionState == ErgConnectionState.connected) {
              unawaited(_connect());
            }
          });
        }
      case ErgConnectionState.reconnecting:
        break;
      case ErgConnectionState.disconnected ||
          ErgConnectionState.scanning ||
          ErgConnectionState.connecting:
        _drop();
        _set(HeartRateMonitorPhase.ready);
    }
  }

  /// A heart rate above 0 that is not the strap's ends every attempt to
  /// connect the strap (Design D2).
  void _onEvent(RowingEvent event) {
    if (event is! StatusTick || (event.heartRate ?? 0) <= 0) return;
    if (_link != null) return;
    final detachedAt = _detachedAt;
    if (detachedAt != null &&
        clock.now().difference(detachedAt) <= HeartRateDecoder.strapTimeout) {
      return;
    }
    final waiting = _phase == HeartRateMonitorPhase.ready && _wait != null;
    final trying = switch (_phase) {
      HeartRateMonitorPhase.connecting ||
      HeartRateMonitorPhase.reconnecting ||
      HeartRateMonitorPhase.disconnected => true,
      _ => false,
    };
    if (!waiting && !trying) return;
    _drop();
    _set(HeartRateMonitorPhase.fromRower);
  }

  Future<void> retry() async {
    if (_closed || _phase != HeartRateMonitorPhase.disconnected) return;
    if (source.connectionState != ErgConnectionState.connected) return;
    await _connect();
  }

  void cancel() {
    if (_closed || _phase != HeartRateMonitorPhase.disconnected) return;
    _set(HeartRateMonitorPhase.cancelled);
  }

  Future<void> _connect() async {
    final attempt = ++_attempt;
    _set(HeartRateMonitorPhase.connecting);
    try {
      final link = await transport.connectHeartRateMonitor(monitor);
      if (attempt != _attempt) {
        await link.disconnect();
        return;
      }
      _attach(link);
    } catch (e) {
      debugPrint('heart rate: $e');
      if (attempt != _attempt) return;
      _set(HeartRateMonitorPhase.disconnected, switch (e) {
        HeartRateConnectException(
          error: HeartRateConnectError.noHeartRateService,
        ) =>
          HeartRateMonitorFailure.noHeartRateService,
        _ => HeartRateMonitorFailure.unreachable,
      });
    }
  }

  void _attach(HeartRateLink link) {
    _link = link;
    source.attachHeartRate(link.notifications);
    _set(HeartRateMonitorPhase.connected);
    final attempt = _attempt;
    link.lost.then((_) {
      if (attempt == _attempt && identical(_link, link)) {
        unawaited(_reconnect());
      }
    });
  }

  Future<void> _reconnect() async {
    final attempt = ++_attempt;
    _link = null;
    _detachedAt = clock.now();
    source.detachHeartRate();
    _set(HeartRateMonitorPhase.reconnecting);
    final link = await reconnectWithin(
      connect: () => transport.connectHeartRateMonitor(monitor),
      window: reconnectWindow,
      retryDelay: retryDelay,
      cancelled: () => attempt != _attempt,
      discard: (link) => link.disconnect(),
    );
    if (attempt != _attempt) return;
    if (link != null) {
      _attach(link);
    } else {
      _set(HeartRateMonitorPhase.disconnected, HeartRateMonitorFailure.lost);
    }
  }

  /// Ends the strap connection and every attempt running.
  void _drop() {
    _attempt++;
    _wait?.cancel();
    _wait = null;
    final link = _link;
    _link = null;
    source.detachHeartRate();
    if (link != null) {
      _detachedAt = clock.now();
      unawaited(link.disconnect());
    }
  }

  void close() {
    _closed = true;
    _rowerStates?.cancel();
    _events?.cancel();
    _drop();
    _cancelTimer?.cancel();
  }

  void _set(HeartRateMonitorPhase phase, [HeartRateMonitorFailure? failure]) {
    _phase = phase;
    // The notice of a disconnected strap gives up by itself (Design D4).
    _cancelTimer?.cancel();
    _cancelTimer = phase == HeartRateMonitorPhase.disconnected
        ? Timer(cancelAfter, cancel)
        : null;
    if (!_closed) _emit(phase, failure);
  }
}
