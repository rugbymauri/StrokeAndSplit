import 'dart:async';

import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/sources/ble/ble_transport.dart';

/// A [BleTransport] whose answers are set by the test.
class FakeBleTransport implements BleTransport {
  FakeBleTransport({
    this.readinessValue = BluetoothReadiness.ready,
    this.found = const [],
    this.connectError,
    this.scanError,
  });

  BluetoothReadiness readinessValue;
  List<FoundRower> found;
  RowerConnectException? connectError;

  /// Thrown by [scan] after the readiness check passed.
  Object? scanError;

  @override
  Future<BluetoothReadiness> readiness() async => readinessValue;

  @override
  Stream<List<FoundRower>> scan({Duration timeout = const Duration(seconds: 15)}) async* {
    final error = scanError;
    if (error != null) throw error;
    if (found.isNotEmpty) yield found;
    await Future<void>.delayed(timeout);
  }

  @override
  Future<RowerLink> connect(FoundRower device) async {
    final error = connectError;
    if (error != null) throw error;
    return _IdleLink();
  }
}

class _IdleLink implements RowerLink {
  @override
  Stream<(String, List<int>)> get notifications => const Stream.empty();

  @override
  Future<void> get lost => Completer<void>().future;

  @override
  Future<void> disconnect() async {}
}

/// Records whether the screen is kept on.
class FakeWakelock implements Wakelock {
  var enabled = false;

  @override
  Future<void> enable() async => enabled = true;

  @override
  Future<void> disable() async => enabled = false;
}
