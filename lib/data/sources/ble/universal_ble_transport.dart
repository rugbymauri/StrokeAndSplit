import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:universal_ble/universal_ble.dart';

import 'ble_transport.dart';
import 'heart_rate_scan_filter.dart';
import 'heart_rate_transport.dart';
import 'rower_connector.dart';
import 'rower_scan_filter.dart';

/// What a failed scan says about the Bluetooth prerequisites, or null when
/// it is some other error.
///
/// universal_ble reports most causes as an error code; a denied Android
/// permission may still arrive as a [PlatformException] such as
/// "Permission android.permission.BLUETOOTH_SCAN required to scan devices".
BluetoothReadiness? readinessForScanError(Object error) {
  if (error is UniversalBleException) {
    switch (error.code) {
      case UniversalBleErrorCode.bluetoothUnauthorized ||
          UniversalBleErrorCode.bluetoothNotAllowed:
        return BluetoothReadiness.unauthorized;
      case UniversalBleErrorCode.bluetoothNotEnabled ||
          UniversalBleErrorCode.bluetoothNotAvailable:
        return BluetoothReadiness.off;
      default:
    }
  }
  final message = switch (error) {
    UniversalBleException(:final message) => message,
    PlatformException(:final message) => message,
    _ => null,
  }?.toLowerCase();
  if (message == null) return null;
  if (message.contains('permission')) return BluetoothReadiness.unauthorized;
  if (message.contains('must be turned on')) return BluetoothReadiness.off;
  return null;
}

/// The id [GattConnection] uses for a characteristic: `0031` for a PM5
/// characteristic, `2ad1` for a standard one.
///
/// universal_ble reports every UUID in its 128-bit, lower-case form, so the
/// id is always the second group of four digits.
String shortCharacteristicId(String uuid) =>
    BleUuidParser.string(uuid).substring(4, 8);

/// The id the scan filters compare: `180d` for a UUID on the Bluetooth base
/// UUID, the full 128-bit UUID in lower case otherwise.
String shortServiceId(String uuid) {
  final full = BleUuidParser.string(uuid);
  return full.startsWith('0000') && full.endsWith(_bluetoothBaseSuffix)
      ? full.substring(4, 8)
      : full;
}

const _bluetoothBaseSuffix = '-0000-1000-8000-00805f9b34fb';

/// [BleTransport] and [HeartRateTransport] on top of universal_ble (BSD-3).
/// Both share the readiness check and the [GattConnection].
class UniversalBleTransport implements BleTransport, HeartRateTransport {
  static final _rowingService = BleUuidParser.string(
    Pm5Characteristics.uuid('0030'),
  );
  static final _ftmsService = BleUuidParser.string(FtmsIds.service);
  static final _heartRateService = BleUuidParser.string(HeartRateIds.service);

  @override
  Future<BluetoothReadiness> readiness() async {
    bool known(AvailabilityState s) =>
        s != AvailabilityState.unknown && s != AvailabilityState.resetting;

    var state = await UniversalBle.getBluetoothAvailabilityState();
    if (!known(state)) {
      state = await UniversalBle.availabilityStream
          .firstWhere(known)
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => AvailabilityState.unknown,
          );
    }
    return switch (state) {
      AvailabilityState.poweredOn => BluetoothReadiness.ready,
      AvailabilityState.unauthorized => BluetoothReadiness.unauthorized,
      AvailabilityState.unsupported => BluetoothReadiness.unsupported,
      _ => BluetoothReadiness.off,
    };
  }

  @override
  Stream<List<FoundRower>> scan({
    Duration timeout = const Duration(seconds: 15),
  }) => _scan(
    timeout: timeout,
    // No platform filter: Android cannot combine the PM5 keyword with the
    // FTMS service; [rowerFromAdvertisement] filters on all platforms.
    withServices: const [],
    recognise: rowerFromAdvertisement,
  );

  @override
  Stream<List<FoundHeartRateMonitor>> scanHeartRateMonitors({
    Duration timeout = const Duration(seconds: 15),
  }) => _scan(
    timeout: timeout,
    withServices: [_heartRateService],
    recognise: heartRateMonitorFromAdvertisement,
  );

  /// Scans for the devices [recognise] accepts and emits the growing list
  /// until [timeout] or until the listener cancels.
  ///
  /// On Linux the scan also reports the devices BlueZ already knows, so a
  /// PM5 in the BlueZ cache shows up without a separate lookup.
  Stream<List<T>> _scan<T extends Object>({
    required Duration timeout,
    required List<String> withServices,
    required T? Function({
      required String id,
      required String name,
      Iterable<String> serviceIds,
      Map<String, List<int>> serviceData,
    })
    recognise,
  }) async* {
    final readiness = await this.readiness();
    if (readiness != BluetoothReadiness.ready) {
      throw BluetoothNotReadyException(readiness);
    }

    final found = <T>{};
    final updates = StreamController<List<T>>();
    final results = UniversalBle.scanStream.listen((device) {
      final recognised = recognise(
        id: device.deviceId,
        name: device.name ?? '',
        serviceIds: device.services.map(shortServiceId),
        serviceData: {
          for (final MapEntry(:key, :value) in device.serviceData.entries)
            shortServiceId(key): value,
        },
      );
      if (recognised != null && found.add(recognised)) {
        updates.add(found.toList());
      }
    });
    Timer? stop;
    Future<void> finish() async {
      stop?.cancel();
      await results.cancel();
      await UniversalBle.stopScan();
      if (!updates.isClosed) await updates.close();
    }

    try {
      await UniversalBle.startScan(
        scanFilter: withServices.isEmpty
            ? null
            : ScanFilter(withServices: withServices),
      );
    } on Exception catch (e) {
      await results.cancel();
      final readiness = readinessForScanError(e);
      if (readiness != null) throw BluetoothNotReadyException(readiness);
      rethrow;
    }
    stop = Timer(timeout, () => unawaited(finish()));
    try {
      yield* updates.stream;
    } finally {
      await finish();
    }
  }

  @override
  Future<RowerLink> connect(FoundRower found) async {
    final GattConnection connection;
    try {
      connection = await _open(found.id, {_rowingService, _ftmsService});
    } catch (e) {
      throw RowerConnectException(RowerConnectError.failed, message: '$e');
    }
    return setUpRower(
      connection,
      found,
      onWarning: (message) => debugPrint('${found.protocol.name}: $message'),
    );
  }

  @override
  Future<HeartRateLink> connectHeartRateMonitor(
    FoundHeartRateMonitor monitor,
  ) async {
    final GattConnection connection;
    try {
      connection = await _open(monitor.id, {_heartRateService});
    } catch (e) {
      throw HeartRateConnectException(
        HeartRateConnectError.failed,
        message: '$e',
      );
    }
    return setUpHeartRateMonitor(connection);
  }

  /// Connects to the device [id] and discovers the characteristics of
  /// [services]; disconnects again when that fails.
  Future<GattConnection> _open(String id, Set<String> services) async {
    try {
      await UniversalBle.stopScan();
      await UniversalBle.connect(id, timeout: const Duration(seconds: 10));
      final discovered = await UniversalBle.discoverServices(
        id,
        timeout: const Duration(seconds: 10),
      );
      return _UniversalBleConnection(id, {
        for (final service in discovered)
          if (services.contains(service.uuid))
            for (final c in service.characteristics)
              shortCharacteristicId(c.uuid): (
                service: service.uuid,
                characteristic: c.uuid,
              ),
      });
    } catch (_) {
      await UniversalBle.disconnect(id);
      rethrow;
    }
  }
}

typedef _Characteristic = ({String service, String characteristic});

class _UniversalBleConnection implements GattConnection {
  _UniversalBleConnection(this._deviceId, this._characteristics) {
    _connection = UniversalBle.connectionStream(_deviceId).listen((connected) {
      if (!connected && !_disconnecting && !_lost.isCompleted) {
        _cleanUp();
        _lost.complete();
      }
    });
  }

  final String _deviceId;
  final Map<String, _Characteristic> _characteristics;
  final _notifications = StreamController<(String, List<int>)>.broadcast();
  final _subscriptions = <StreamSubscription<List<int>>>[];
  final _lost = Completer<void>();
  late final StreamSubscription<bool> _connection;
  var _disconnecting = false;

  @override
  Set<String> get characteristics => _characteristics.keys.toSet();

  @override
  Stream<(String, List<int>)> get notifications => _notifications.stream;

  @override
  Future<void> subscribe(String id) async {
    final c = _characteristics[id]!;
    _subscriptions.add(
      UniversalBle.characteristicValueStream(
        _deviceId,
        c.characteristic,
      ).listen((bytes) => _notifications.add((id, bytes))),
    );
    await UniversalBle.subscribeNotifications(
      _deviceId,
      c.service,
      c.characteristic,
    );
  }

  @override
  Future<void> write(String id, List<int> bytes) {
    final c = _characteristics[id]!;
    return UniversalBle.write(
      _deviceId,
      c.service,
      c.characteristic,
      Uint8List.fromList(bytes),
    );
  }

  @override
  Future<List<int>> read(String id) {
    final c = _characteristics[id]!;
    return UniversalBle.read(_deviceId, c.service, c.characteristic);
  }

  @override
  Future<void> get lost => _lost.future;

  @override
  Future<void> disconnect() async {
    if (_disconnecting) return;
    _disconnecting = true;
    _cleanUp();
    await UniversalBle.disconnect(_deviceId);
  }

  void _cleanUp() {
    _connection.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _notifications.close();
  }
}
