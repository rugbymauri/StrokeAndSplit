import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:erg_protocol/erg_protocol.dart';

import 'ble_transport.dart';
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
    try {
      await FlutterBluePlus.stopScan();
      await device.connect(license: License.nonprofit, timeout: const Duration(seconds: 10));
      final services = await device.discoverServices();
      final rowing = services.where((s) => s.uuid == _rowingService).firstOrNull;
      if (rowing == null) throw const RowerConnectException('Das Gerät bietet keinen Rudern-Service an.');

      BluetoothCharacteristic? characteristic(String id) =>
          rowing.characteristics.where((c) => c.uuid == Guid(Pm5Characteristics.uuid(id))).firstOrNull;

      await characteristic(Pm5Characteristics.sampleRate)?.write([Pm5Characteristics.sampleRate250ms]);

      final link = _FlutterBluePlusLink(device);
      for (final id in Pm5Characteristics.subscribed) {
        final c = characteristic(id);
        if (c == null) continue;
        link._subscriptions.add(c.onValueReceived.listen((bytes) => link._notifications.add((id, bytes))));
        await c.setNotifyValue(true);
      }
      return link;
    } on RowerConnectException {
      await device.disconnect();
      rethrow;
    } catch (e) {
      await device.disconnect();
      throw RowerConnectException('$e');
    }
  }
}

class _FlutterBluePlusLink implements RowerLink {
  _FlutterBluePlusLink(this._device) {
    _connection = _device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected && !_disconnecting && !_lost.isCompleted) {
        _cleanUp();
        _lost.complete();
      }
    });
  }

  final BluetoothDevice _device;
  final _notifications = StreamController<(String, List<int>)>.broadcast();
  final _subscriptions = <StreamSubscription<List<int>>>[];
  final _lost = Completer<void>();
  late final StreamSubscription<BluetoothConnectionState> _connection;
  var _disconnecting = false;

  @override
  Stream<(String, List<int>)> get notifications => _notifications.stream;

  @override
  Future<void> get lost => _lost.future;

  @override
  Future<void> disconnect() async {
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
