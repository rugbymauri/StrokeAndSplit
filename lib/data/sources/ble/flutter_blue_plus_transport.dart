import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:erg_protocol/erg_protocol.dart';

import 'ble_transport.dart';
import 'heart_rate_scan_filter.dart';
import 'heart_rate_transport.dart';
import 'rower_connector.dart';
import 'rower_scan_filter.dart';

/// What a failed scan says about the Bluetooth prerequisites, or null when
/// it is some other error.
///
/// On Android a denied permission arrives as a [PlatformException] such as
/// "Permission android.permission.BLUETOOTH_SCAN required to scan devices".
BluetoothReadiness? readinessForScanError(Object error) {
  final message = switch (error) {
    PlatformException(:final message) => message,
    FlutterBluePlusException(:final description) => description,
    _ => null,
  }
      ?.toLowerCase();
  if (message == null) return null;
  if (message.contains('permission')) return BluetoothReadiness.unauthorized;
  if (message.contains('must be turned on')) return BluetoothReadiness.off;
  return null;
}

/// [BleTransport] and [HeartRateTransport] on top of flutter_blue_plus, used
/// under its nonprofit license (see design decision D4). Both share the
/// readiness check and the [GattConnection].
class FlutterBluePlusTransport implements BleTransport, HeartRateTransport {
  static final _rowingService = Guid(Pm5Characteristics.uuid('0030'));
  static final _ftmsService = Guid(FtmsIds.service);
  static final _heartRateService = Guid(HeartRateIds.service);

  @override
  Future<BluetoothReadiness> readiness() async {
    if (!await FlutterBluePlus.isSupported) return BluetoothReadiness.unsupported;
    final state = await FlutterBluePlus.adapterState
        .firstWhere((s) => s != BluetoothAdapterState.unknown)
        .timeout(const Duration(seconds: 3), onTimeout: () => BluetoothAdapterState.unknown);
    return switch (state) {
      BluetoothAdapterState.on => BluetoothReadiness.ready,
      BluetoothAdapterState.unauthorized => BluetoothReadiness.unauthorized,
      BluetoothAdapterState.unavailable => BluetoothReadiness.unsupported,
      _ => BluetoothReadiness.off,
    };
  }

  @override
  Stream<List<FoundRower>> scan({Duration timeout = const Duration(seconds: 15)}) => _scan(
        timeout: timeout,
        // No platform filter: Android cannot combine the PM5 keyword with the
        // FTMS service, and Linux ignores filters; [rowerFromAdvertisement]
        // filters on all platforms.
        withServices: const [],
        cachedServices: [_rowingService, _ftmsService],
        recognise: rowerFromAdvertisement,
      );

  @override
  Stream<List<FoundHeartRateMonitor>> scanHeartRateMonitors({Duration timeout = const Duration(seconds: 15)}) =>
      _scan(
        timeout: timeout,
        withServices: [_heartRateService],
        cachedServices: [_heartRateService],
        recognise: heartRateMonitorFromAdvertisement,
      );

  /// Scans for the devices [recognise] accepts and emits the growing list.
  Stream<List<T>> _scan<T extends Object>({
    required Duration timeout,
    required List<Guid> withServices,
    required List<Guid> cachedServices,
    required T? Function({
      required String id,
      required String name,
      Iterable<String> serviceIds,
      Map<String, List<int>> serviceData,
    }) recognise,
  }) async* {
    final readiness = await this.readiness();
    if (readiness != BluetoothReadiness.ready) throw BluetoothNotReadyException(readiness);

    final found = <T>{};
    final updates = StreamController<List<T>>();
    void add(Iterable<T?> devices) {
      final before = found.length;
      found.addAll(devices.nonNulls);
      if (found.length != before) updates.add(found.toList());
    }

    final results = FlutterBluePlus.scanResults.listen((results) => add(results.map((r) => recognise(
          id: r.device.remoteId.str,
          name: r.device.platformName.isNotEmpty ? r.device.platformName : r.advertisementData.advName,
          serviceIds: [for (final uuid in r.advertisementData.serviceUuids) uuid.str.toLowerCase()],
          serviceData: {
            for (final MapEntry(:key, :value) in r.advertisementData.serviceData.entries) key.str.toLowerCase(): value,
          },
        ))));
    try {
      await FlutterBluePlus.startScan(withServices: withServices, timeout: timeout);
    } on Exception catch (e) {
      await results.cancel();
      final readiness = readinessForScanError(e);
      if (readiness != null) throw BluetoothNotReadyException(readiness);
      rethrow;
    }
    // The Linux backend only reports devices BlueZ discovers anew; a device in
    // the BlueZ cache is only listed among the system devices. These come
    // without advertisement, so only a PM5 is recognised there, by its name,
    // and a strap by the service it was asked for.
    if (Platform.isLinux) {
      final cached = await FlutterBluePlus.systemDevices(cachedServices);
      add(cached.map((d) => recognise(
            id: d.remoteId.str,
            name: d.platformName,
            serviceIds: [for (final uuid in withServices) uuid.str.toLowerCase()],
          )));
    }

    unawaited(FlutterBluePlus.isScanning.firstWhere((scanning) => !scanning).then((_) async {
      await results.cancel();
      await updates.close();
    }));
    yield* updates.stream;
  }

  @override
  Future<RowerLink> connect(FoundRower found) async {
    final GattConnection connection;
    try {
      connection = await _open(found.id, {_rowingService, _ftmsService});
    } catch (e) {
      throw RowerConnectException(RowerConnectError.failed, message: '$e');
    }
    return setUpRower(connection, found, onWarning: (message) => debugPrint('${found.protocol.name}: $message'));
  }

  @override
  Future<HeartRateLink> connectHeartRateMonitor(FoundHeartRateMonitor monitor) async {
    final GattConnection connection;
    try {
      connection = await _open(monitor.id, {_heartRateService});
    } catch (e) {
      throw HeartRateConnectException(HeartRateConnectError.failed, message: '$e');
    }
    return setUpHeartRateMonitor(connection);
  }

  /// Connects to the device [id] and discovers the characteristics of
  /// [services]; disconnects again when that fails.
  Future<GattConnection> _open(String id, Set<Guid> services) async {
    final device = BluetoothDevice.fromId(id);
    try {
      await FlutterBluePlus.stopScan();
      await device.connect(license: License.nonprofit, timeout: const Duration(seconds: 10));
      final discovered = await device.discoverServices();
      return _FlutterBluePlusConnection(device, {
        for (final service in discovered)
          if (services.contains(service.uuid))
            for (final c in service.characteristics) _shortId(c.uuid): c,
      });
    } catch (_) {
      await device.disconnect();
      rethrow;
    }
  }

  /// `0031` for a PM5 characteristic, `2ad1` for a standard one.
  static String _shortId(Guid uuid) {
    final full = uuid.str128;
    return full.startsWith('ce06') ? full.substring(4, 8) : uuid.str.toLowerCase();
  }
}

class _FlutterBluePlusConnection implements GattConnection {
  _FlutterBluePlusConnection(this._device, this._characteristics) {
    _connection = _device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected && !_disconnecting && !_lost.isCompleted) {
        _cleanUp();
        _lost.complete();
      }
    });
  }

  final BluetoothDevice _device;
  final Map<String, BluetoothCharacteristic> _characteristics;
  final _notifications = StreamController<(String, List<int>)>.broadcast();
  final _subscriptions = <StreamSubscription<List<int>>>[];
  final _lost = Completer<void>();
  late final StreamSubscription<BluetoothConnectionState> _connection;
  var _disconnecting = false;

  @override
  Set<String> get characteristics => _characteristics.keys.toSet();

  @override
  Stream<(String, List<int>)> get notifications => _notifications.stream;

  @override
  Future<void> subscribe(String id) async {
    final c = _characteristics[id]!;
    _subscriptions.add(c.onValueReceived.listen((bytes) => _notifications.add((id, bytes))));
    await c.setNotifyValue(true);
  }

  @override
  Future<void> write(String id, List<int> bytes) => _characteristics[id]!.write(bytes);

  @override
  Future<void> get lost => _lost.future;

  @override
  Future<void> disconnect() async {
    if (_disconnecting) return;
    _disconnecting = true;
    _cleanUp();
    await _device.disconnect();
  }

  void _cleanUp() {
    _connection.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _notifications.close();
  }
}
