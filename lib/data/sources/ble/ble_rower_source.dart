import 'dart:async';

import 'package:clock/clock.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../erg_source.dart';
import '../resistance_control.dart';
import 'ble_transport.dart';
import 'reconnect.dart';

/// A real rower, PM5 or FTMS, connected over Bluetooth LE.
///
/// When the connection drops unexpectedly it keeps trying to reconnect to the
/// same rower for [reconnectWindow]; after a deliberate [stop] it does not.
class BleRowerSource implements ErgSource {
  BleRowerSource({
    required this._transport,
    required this.device,
    this.reconnectWindow = const Duration(seconds: 30),
    this.retryDelay = const Duration(seconds: 2),
  });

  final BleTransport _transport;
  final FoundRower device;
  final Duration reconnectWindow;
  final Duration retryDelay;

  final _packets = StreamController<RawPacket>.broadcast();
  final _states = StreamController<ErgConnectionState>.broadcast();
  ErgConnectionState _state = ErgConnectionState.disconnected;
  RowerLink? _link;
  StreamSubscription<(String, List<int>)>? _notifications;
  StreamSubscription<(String, List<int>)>? _heartRate;
  DateTime? _startedAt;
  var _stopped = false;

  @override
  ErgSourceKind get kind => switch (protocol) {
        ErgProtocol.pm5 => ErgSourceKind.pm5,
        ErgProtocol.ftms => ErgSourceKind.ftms,
      };

  @override
  ErgProtocol get protocol => device.protocol;

  @override
  bool get providesForceCurves => protocol == ErgProtocol.pm5;

  @override
  ResistanceControl? get resistanceControl => _link?.resistanceControl;

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

  /// Feeds the measurements of a heart rate strap into [packets], stamped
  /// with the clock of this source (Design D1).
  ///
  /// Replaces a strap attached before. The strap stays attached while the
  /// rower reconnects; only [detachHeartRate] ends it.
  void attachHeartRate(Stream<(String, List<int>)> notifications) {
    _heartRate?.cancel();
    _startedAt ??= clock.now();
    _heartRate = notifications.listen(_forward);
  }

  /// Stops feeding the strap attached with [attachHeartRate].
  void detachHeartRate() {
    _heartRate?.cancel();
    _heartRate = null;
  }

  void _forward((String, List<int>) notification) {
    final (id, bytes) = notification;
    _packets.add(RawPacket(time: clock.now().difference(_startedAt!), characteristicId: id, bytes: bytes));
  }

  void _attach(RowerLink link) {
    _link = link;
    _notifications = link.notifications.listen(_forward);
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
    final link = await reconnectWithin(
      connect: () => _transport.connect(device),
      window: reconnectWindow,
      retryDelay: retryDelay,
      cancelled: () => _stopped,
      discard: (link) => link.disconnect(),
    );
    if (link != null) {
      _attach(link);
    } else if (!_stopped) {
      _setState(ErgConnectionState.disconnected);
    }
  }

  void _setState(ErgConnectionState state) {
    if (_state == state) return;
    _state = state;
    _states.add(state);
  }
}
