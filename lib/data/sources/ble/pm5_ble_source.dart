import 'dart:async';

import 'package:clock/clock.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../erg_source.dart';
import 'ble_transport.dart';

/// A real PM5 connected over Bluetooth LE.
///
/// When the connection drops unexpectedly it keeps trying to reconnect to the
/// same PM5 for [reconnectWindow]; after a deliberate [stop] it does not.
class Pm5BleSource implements ErgSource {
  Pm5BleSource({
    required this._transport,
    required this.device,
    this.reconnectWindow = const Duration(seconds: 30),
    this.retryDelay = const Duration(seconds: 2),
  });

  final BleTransport _transport;
  final FoundPm5 device;
  final Duration reconnectWindow;
  final Duration retryDelay;

  final _packets = StreamController<RawPacket>.broadcast();
  final _states = StreamController<ErgConnectionState>.broadcast();
  ErgConnectionState _state = ErgConnectionState.disconnected;
  Pm5Link? _link;
  StreamSubscription<(String, List<int>)>? _notifications;
  DateTime? _startedAt;
  var _stopped = false;

  @override
  ErgSourceKind get kind => ErgSourceKind.pm5;

  @override
  String get name => device.name;

  @override
  Stream<RawPacket> get packets => _packets.stream;

  @override
  ErgConnectionState get connectionState => _state;

  @override
  Stream<ErgConnectionState> get connectionStates => _states.stream;

  @override
  Future<void> start() async {
    _stopped = false;
    _startedAt ??= clock.now();
    _setState(ErgConnectionState.connecting);
    try {
      _attach(await _transport.connect(device));
    } catch (_) {
      _setState(ErgConnectionState.disconnected);
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    final link = _link;
    _detach();
    await link?.disconnect();
    _setState(ErgConnectionState.disconnected);
  }

  void _attach(Pm5Link link) {
    _link = link;
    _notifications = link.notifications.listen((notification) {
      final (id, bytes) = notification;
      _packets.add(RawPacket(time: clock.now().difference(_startedAt!), characteristicId: id, bytes: bytes));
    });
    _setState(ErgConnectionState.connected);
    link.lost.then((_) {
      if (!_stopped && identical(_link, link)) _reconnect();
    });
  }

  void _detach() {
    _notifications?.cancel();
    _notifications = null;
    _link = null;
  }

  Future<void> _reconnect() async {
    _detach();
    _setState(ErgConnectionState.reconnecting);
    final deadline = clock.now().add(reconnectWindow);

    while (!_stopped) {
      final remaining = deadline.difference(clock.now());
      if (remaining <= Duration.zero) break;
      try {
        final link = await _transport.connect(device).timeout(remaining);
        if (_stopped) {
          await link.disconnect();
          return;
        }
        _attach(link);
        return;
      } catch (_) {
        final left = deadline.difference(clock.now());
        if (left <= Duration.zero) break;
        await Future<void>.delayed(left < retryDelay ? left : retryDelay);
      }
    }
    if (!_stopped) _setState(ErgConnectionState.disconnected);
  }

  void _setState(ErgConnectionState state) {
    if (_state == state) return;
    _state = state;
    _states.add(state);
  }
}
