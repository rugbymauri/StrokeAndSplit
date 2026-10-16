import 'dart:async';
import 'dart:typed_data';

import 'package:erg_protocol/erg_protocol.dart';

import 'ble_transport.dart';

/// A connected device with its services discovered: the thin part that
/// depends on the BLE plugin.
abstract interface class GattConnection {
  /// Short ids of the characteristics of the PM5 rowing service and of the
  /// Fitness Machine Service, e.g. `0031` or `2ad1`.
  Set<String> get characteristics;

  /// Values of subscribed characteristics as (short id, bytes).
  Stream<(String, List<int>)> get notifications;

  /// Enables notifications or indications of a characteristic.
  Future<void> subscribe(String id);

  Future<void> write(String id, List<int> bytes);

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
    throw RowerConnectException('$e');
  }
}

const _onlyRowers = 'Nur Rudergeräte werden unterstützt.';

Future<RowerLink> _setUpPm5(GattConnection connection, Duration ergTypeTimeout) async {
  final characteristics = connection.characteristics;
  if (!characteristics.contains(Pm5Characteristics.generalStatus)) {
    throw const RowerConnectException('Das Gerät bietet keinen Rudern-Service an.');
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
    final erg = kind == Pm5ErgKind.skiErg ? 'SkiErg' : 'BikeErg';
    throw RowerConnectException('$_onlyRowers Dieser PM5 gehört zu einem $erg.', notARower: true);
  }
  return _GattRowerLink(connection, Pm5Characteristics.subscribed.toSet());
}

Future<RowerLink> _setUpFtms(
  GattConnection connection,
  Duration controlTimeout,
  void Function(String message)? onWarning,
) async {
  final characteristics = connection.characteristics;
  if (!characteristics.contains(FtmsIds.rowerData)) {
    throw const RowerConnectException('$_onlyRowers Das Gerät liefert keine Rudern-Daten.', notARower: true);
  }
  await connection.subscribe(FtmsIds.rowerData);
  if (characteristics.contains(FtmsIds.controlPoint)) await _requestStart(connection, controlTimeout, onWarning);
  return _GattRowerLink(connection, {FtmsIds.rowerData});
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

/// Forwards the rowing data of a set-up connection.
class _GattRowerLink implements RowerLink {
  _GattRowerLink(this._connection, this._ids);

  final GattConnection _connection;
  final Set<String> _ids;

  @override
  Stream<(String, List<int>)> get notifications => _connection.notifications.where((n) => _ids.contains(n.$1));

  @override
  Future<void> get lost => _connection.lost;

  @override
  Future<void> disconnect() => _connection.disconnect();
}
