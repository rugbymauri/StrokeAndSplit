import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/sources/ble/ble_transport.dart';
import '../data/sources/ble/flutter_blue_plus_transport.dart';

/// Bluetooth access; replaced by a fake in tests.
final bleTransportProvider = Provider<BleTransport>((ref) => FlutterBluePlusTransport());

/// Keeps the screen on; replaced by a fake in tests.
final wakelockProvider = Provider<Wakelock>((ref) => const PluginWakelock());

abstract interface class Wakelock {
  Future<void> enable();
  Future<void> disable();
}

class PluginWakelock implements Wakelock {
  const PluginWakelock();

  @override
  Future<void> enable() => WakelockPlus.enable();

  @override
  Future<void> disable() => WakelockPlus.disable();
}
