import 'dart:async';

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

  /// A strap is paired, but no rower over Bluetooth is connected.
  ready,
  connecting,
  connected,
  reconnecting,

  /// The connection failed or could not be restored; see the failure.
  disconnected,
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
/// Connects the strap as soon as a rower over Bluetooth, PM5 or FTMS, is
/// connected and feeds it into that source; never with the simulator or a
/// replay. Disconnects the strap when the rower is stopped, the source
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
  });

  final Duration reconnectWindow;
  final Duration retryDelay;

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
      reconnectWindow: reconnectWindow,
      retryDelay: retryDelay,
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
}

/// The strap connection that belongs to one rower source; replaced as soon
/// as the strap or the source changes.
class _StrapConnection {
  _StrapConnection({
    required this.transport,
    required this.monitor,
    required this.source,
    required this.reconnectWindow,
    required this.retryDelay,
    required this._emit,
  });

  final HeartRateTransport transport;
  final FoundHeartRateMonitor monitor;
  final BleRowerSource source;
  final Duration reconnectWindow;
  final Duration retryDelay;
  final void Function(
    HeartRateMonitorPhase phase, [
    HeartRateMonitorFailure? failure,
  ])
  _emit;

  var _phase = HeartRateMonitorPhase.ready;
  HeartRateLink? _link;
  StreamSubscription<ErgConnectionState>? _rowerStates;

  /// Counts the attempts; an attempt whose number is outdated gives up.
  var _attempt = 0;
  var _closed = false;

  void follow() {
    if (_closed) return;
    _rowerStates = source.connectionStates.listen(_onRowerState);
    _onRowerState(source.connectionState);
  }

  void _onRowerState(ErgConnectionState rower) {
    switch (rower) {
      case ErgConnectionState.connected:
        if (_phase == HeartRateMonitorPhase.ready) unawaited(_connect());
      case ErgConnectionState.reconnecting:
        break;
      case ErgConnectionState.disconnected ||
          ErgConnectionState.scanning ||
          ErgConnectionState.connecting:
        _drop();
        _set(HeartRateMonitorPhase.ready);
    }
  }

  Future<void> retry() async {
    if (_closed || _phase != HeartRateMonitorPhase.disconnected) return;
    if (source.connectionState != ErgConnectionState.connected) return;
    await _connect();
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
    final link = _link;
    _link = null;
    source.detachHeartRate();
    if (link != null) unawaited(link.disconnect());
  }

  void close() {
    _closed = true;
    _rowerStates?.cancel();
    _drop();
  }

  void _set(HeartRateMonitorPhase phase, [HeartRateMonitorFailure? failure]) {
    _phase = phase;
    if (!_closed) _emit(phase, failure);
  }
}
