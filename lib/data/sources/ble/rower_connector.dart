import 'dart:async';
import 'dart:typed_data';

import 'package:erg_protocol/erg_protocol.dart';

import '../resistance_control.dart';
import 'ble_transport.dart';
import 'heart_rate_transport.dart';

/// A connected device with its services discovered: the thin part that
/// depends on the BLE plugin.
abstract interface class GattConnection {
  /// Short ids of the characteristics of the services looked for: the PM5
  /// rowing service and the Fitness Machine Service for a rower, the Heart
  /// Rate service for a strap, e.g. `0031`, `2ad1` or `2a37`.
  Set<String> get characteristics;

  /// Values of subscribed characteristics as (short id, bytes).
  Stream<(String, List<int>)> get notifications;

  /// Enables notifications or indications of a characteristic.
  Future<void> subscribe(String id);

  Future<void> write(String id, List<int> bytes);

  /// Reads the value of a characteristic.
  Future<List<int>> read(String id);

  /// Completes when the connection drops without [disconnect] being called.
  Future<void> get lost;

  Future<void> disconnect();
}

/// Sets up a freshly connected rower for its protocol and returns the link
/// (Design D5 to D7).
///
/// Disconnects and throws [RowerConnectException] when the device offers no
/// rowing data or is no rower.
Future<RowerLink> setUpRower(
  GattConnection connection,
  FoundRower rower, {
  void Function(String message)? onWarning,
  Duration ergTypeTimeout = const Duration(seconds: 3),
  Duration controlTimeout = const Duration(seconds: 2),
}) async {
  try {
    return switch (rower.protocol) {
      ErgProtocol.pm5 => await _setUpPm5(connection, ergTypeTimeout),
      ErgProtocol.ftms => await _setUpFtms(connection, controlTimeout, onWarning),
    };
  } catch (e) {
    await connection.disconnect();
    if (e is RowerConnectException) rethrow;
    throw RowerConnectException(RowerConnectError.failed, message: '$e');
  }
}

Future<RowerLink> _setUpPm5(GattConnection connection, Duration ergTypeTimeout) async {
  final characteristics = connection.characteristics;
  if (!characteristics.contains(Pm5Characteristics.generalStatus)) {
    throw const RowerConnectException(RowerConnectError.noRowingService);
  }
  if (characteristics.contains(Pm5Characteristics.sampleRate)) {
    await connection.write(Pm5Characteristics.sampleRate, [Pm5Characteristics.sampleRate250ms]);
  }
  final firstStatus = _first(connection, Pm5Characteristics.additionalStatus, ergTypeTimeout);
  for (final id in Pm5Characteristics.subscribed) {
    if (characteristics.contains(id)) await connection.subscribe(id);
  }
  // Without the packet the PM5 is let through, so no RowErg gets blocked (D6).
  final status = await firstStatus;
  final kind = status == null ? null : Pm5ErgType.fromAdditionalStatus(Uint8List.fromList(status));
  if (kind == Pm5ErgKind.skiErg || kind == Pm5ErgKind.bikeErg) {
    throw RowerConnectException(kind == Pm5ErgKind.skiErg ? RowerConnectError.skiErg : RowerConnectError.bikeErg);
  }
  return _GattLink(connection, Pm5Characteristics.subscribed.toSet());
}

Future<RowerLink> _setUpFtms(
  GattConnection connection,
  Duration controlTimeout,
  void Function(String message)? onWarning,
) async {
  final characteristics = connection.characteristics;
  if (!characteristics.contains(FtmsIds.rowerData)) {
    throw const RowerConnectException(RowerConnectError.noRowerData);
  }
  await connection.subscribe(FtmsIds.rowerData);
  if (!characteristics.contains(FtmsIds.controlPoint)) return _GattLink(connection, {FtmsIds.rowerData});
  await _requestStart(connection, controlTimeout, onWarning);
  final range = await _resistanceRange(connection, onWarning);
  return _GattLink(
    connection,
    {FtmsIds.rowerData},
    resistanceControl: range == null ? null : FtmsResistanceControl(connection, range, timeout: controlTimeout),
  );
}

/// The levels an FTMS rower lets the app set, or null when it cannot (D2):
/// its features must allow it and its range must make sense.
Future<ResistanceRange?> _resistanceRange(GattConnection connection, void Function(String message)? onWarning) async {
  final characteristics = connection.characteristics;
  if (!characteristics.contains(FtmsIds.feature) ||
      !characteristics.contains(FtmsIds.supportedResistanceLevelRange)) {
    return null;
  }
  try {
    final features = FtmsFeatures.parse(await connection.read(FtmsIds.feature));
    if (features == null || !features.setsResistanceLevel) return null;
    final range = ResistanceRange.parse(await connection.read(FtmsIds.supportedResistanceLevelRange));
    if (range == null) onWarning?.call('resistance: no usable level range');
    return range;
  } catch (e) {
    onWarning?.call('resistance: $e');
    return null;
  }
}

/// Sets up a freshly connected heart rate strap: subscribes to the Heart Rate
/// Measurement and returns the link (Design D2).
///
/// Disconnects and throws [HeartRateConnectException] when the device offers
/// no Heart Rate service or the subscription fails.
Future<HeartRateLink> setUpHeartRateMonitor(GattConnection connection) async {
  try {
    if (!connection.characteristics.contains(HeartRateIds.measurement)) {
      throw const HeartRateConnectException(HeartRateConnectError.noHeartRateService);
    }
    await connection.subscribe(HeartRateIds.measurement);
    return _GattLink(connection, {HeartRateIds.measurement});
  } catch (e) {
    await connection.disconnect();
    if (e is HeartRateConnectException) rethrow;
    throw HeartRateConnectException(HeartRateConnectError.failed, message: '$e');
  }
}

/// Asks an FTMS rower to send: Request Control, then Start or Resume (D7).
/// Never sends Reset or Stop; a refusal or no answer leaves the connection
/// as it is.
Future<void> _requestStart(
  GattConnection connection,
  Duration timeout,
  void Function(String message)? onWarning,
) async {
  const requestControl = 0x00, startOrResume = 0x07, response = 0x80, success = 0x01;
  try {
    await connection.subscribe(FtmsIds.controlPoint);
    bool isAnswer(List<int> b) => b.length >= 3 && b[0] == response && b[1] == requestControl;
    final answer = _first(connection, FtmsIds.controlPoint, timeout, isAnswer);
    await connection.write(FtmsIds.controlPoint, [requestControl]);
    final result = await answer;
    if (result == null) {
      onWarning?.call('control point: no answer to Request Control');
      return;
    }
    if (result[2] != success) {
      onWarning?.call('control point: Request Control refused with result ${result[2]}');
      return;
    }
    await connection.write(FtmsIds.controlPoint, [startOrResume]);
  } catch (e) {
    onWarning?.call('control point: $e');
  }
}

/// The first value of [id] matching [test] within [timeout], or null.
Future<List<int>?> _first(
  GattConnection connection,
  String id,
  Duration timeout, [
  bool Function(List<int> bytes)? test,
]) {
  final result = Completer<List<int>?>();
  late final StreamSubscription<(String, List<int>)> subscription;
  final timer = Timer(timeout, () {
    subscription.cancel();
    if (!result.isCompleted) result.complete(null);
  });
  subscription = connection.notifications.listen((notification) {
    final (from, bytes) = notification;
    if (from != id || !(test?.call(bytes) ?? true) || result.isCompleted) return;
    timer.cancel();
    subscription.cancel();
    result.complete(bytes);
  });
  return result.future;
}

/// Sets the resistance level over the control point of an FTMS rower, which
/// stays subscribed after the set-up (Design D2, D3).
///
/// Commands go out one after the other, so every answer belongs to the
/// command before it.
class FtmsResistanceControl implements ResistanceControl {
  FtmsResistanceControl(this._connection, this.range, {this.timeout = const Duration(seconds: 2)});

  final GattConnection _connection;

  @override
  final ResistanceRange range;

  final Duration timeout;

  /// Whether this rower takes the level as 16 bits; learnt from its first
  /// "invalid parameter".
  var _wide = false;

  /// Completes when the command on the way is answered; null when none is.
  Future<void>? _busy;

  @override
  Future<ResistanceResult> setLevel(int level) async {
    while (_busy != null) {
      await _busy;
    }
    final done = Completer<void>();
    _busy = done.future;
    try {
      return await _setLevel(level);
    } finally {
      _busy = null;
      done.complete();
    }
  }

  Future<ResistanceResult> _setLevel(int level) async {
    var result = await _send(FtmsControl.setResistanceLevel(level, wide: _wide));
    if (result == FtmsControl.controlNotPermitted &&
        await _send([FtmsControl.requestControl]) == FtmsControl.success) {
      result = await _send(FtmsControl.setResistanceLevel(level, wide: _wide));
    }
    if (result == FtmsControl.invalidParameter && !_wide && !FtmsControl.needsWide(level)) {
      result = await _send(FtmsControl.setResistanceLevel(level, wide: true));
      if (result == FtmsControl.success) _wide = true;
    }
    return switch (result) {
      FtmsControl.success => ResistanceResult.accepted,
      null => ResistanceResult.noAnswer,
      _ => ResistanceResult.rejected,
    };
  }

  /// Writes [command] and returns the result of its answer, null without one.
  Future<int?> _send(List<int> command) async {
    bool isAnswer(List<int> bytes) => FtmsControlResponse.parse(bytes)?.requestOpCode == command.first;
    final answer = _first(_connection, FtmsIds.controlPoint, timeout, isAnswer);
    try {
      await _connection.write(FtmsIds.controlPoint, command);
    } catch (_) {
      return null;
    }
    final bytes = await answer;
    return bytes == null ? null : FtmsControlResponse.parse(bytes)!.result;
  }
}

/// Forwards the data of a set-up connection: rowing data or heart rate.
class _GattLink implements RowerLink, HeartRateLink {
  _GattLink(this._connection, this._ids, {this.resistanceControl});

  final GattConnection _connection;
  final Set<String> _ids;

  @override
  final ResistanceControl? resistanceControl;

  @override
  Stream<(String, List<int>)> get notifications => _connection.notifications.where((n) => _ids.contains(n.$1));

  @override
  Future<void> get lost => _connection.lost;

  @override
  Future<void> disconnect() => _connection.disconnect();
}
