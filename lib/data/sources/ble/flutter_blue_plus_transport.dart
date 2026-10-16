import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:erg_protocol/erg_protocol.dart';

import 'ble_transport.dart';
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

/// [BleTransport] on top of flutter_blue_plus, used under its nonprofit
/// license (see design decision D4).
class FlutterBluePlusTransport implements BleTransport {
  static final _rowingService = Guid(Pm5Characteristics.uuid('0030'));
  static final _ftmsService = Guid(FtmsIds.service);

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
  Stream<List<FoundRower>> scan({Duration timeout = const Duration(seconds: 15)}) async* {
    final readiness = await this.readiness();
    if (readiness != BluetoothReadiness.ready) throw BluetoothNotReadyException(readiness);

    final found = <FoundRower>{};
    final updates = StreamController<List<FoundRower>>();
    void add(Iterable<FoundRower?> rowers) {
      final before = found.length;
      found.addAll(rowers.nonNulls);
      if (found.length != before) updates.add(found.toList());
    }

    final results = FlutterBluePlus.scanResults.listen((results) => add(results.map((r) => rowerFromAdvertisement(
          id: r.device.remoteId.str,
          name: r.device.platformName.isNotEmpty ? r.device.platformName : r.advertisementData.advName,
          serviceIds: [for (final uuid in r.advertisementData.serviceUuids) uuid.str.toLowerCase()],
          serviceData: {
            for (final MapEntry(:key, :value) in r.advertisementData.serviceData.entries) key.str.toLowerCase(): value,
          },
        ))));
    try {
      // No platform filter: Android cannot combine the PM5 keyword with the
      // FTMS service, and Linux ignores filters; [rowerFromAdvertisement]
      // filters on all platforms.
      await FlutterBluePlus.startScan(timeout: timeout);
    } on Exception catch (e) {
      await results.cancel();
      final readiness = readinessForScanError(e);
      if (readiness != null) throw BluetoothNotReadyException(readiness);
      rethrow;
    }
    // The Linux backend only reports devices BlueZ discovers anew; a rower in
    // the BlueZ cache is only listed among the system devices. These come
    // without advertisement, so only a PM5 is recognised there, by its name.
    if (Platform.isLinux) {
      final cached = await FlutterBluePlus.systemDevices([_rowingService, _ftmsService]);
      add(cached.map((d) => rowerFromAdvertisement(id: d.remoteId.str, name: d.platformName)));
    }

    unawaited(FlutterBluePlus.isScanning.firstWhere((scanning) => !scanning).then((_) async {
      await results.cancel();
      await updates.close();
    }));
    yield* updates.stream;
  }

  @override
  Future<RowerLink> connect(FoundRower found) async {
    final device = BluetoothDevice.fromId(found.id);
    final _FlutterBluePlusConnection connection;
    try {
      await FlutterBluePlus.stopScan();
      await device.connect(license: License.nonprofit, timeout: const Duration(seconds: 10));
      final services = await device.discoverServices();
      connection = _FlutterBluePlusConnection(device, {
        for (final service in services)
          if (service.uuid == _rowingService || service.uuid == _ftmsService)
            for (final c in service.characteristics) _shortId(c.uuid): c,
      });
    } catch (e) {
      await device.disconnect();
      throw RowerConnectException('$e');
    }
    return setUpRower(connection, found, onWarning: (message) => debugPrint('${found.protocol.name}: $message'));
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
