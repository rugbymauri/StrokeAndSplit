import 'dart:async';

import 'package:strokesplit/app/platform_providers.dart';
import 'package:strokesplit/data/sources/ble/ble_transport.dart';
import 'package:strokesplit/data/sources/resistance_control.dart';

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

  /// The links handed out, the latest last.
  final links = <FakeRowerLink>[];

  @override
  Future<BluetoothReadiness> readiness() async => readinessValue;

  @override
  Stream<List<FoundRower>> scan({
    Duration timeout = const Duration(seconds: 15),
  }) async* {
    final error = scanError;
    if (error != null) throw error;
    if (found.isNotEmpty) yield found;
    await Future<void>.delayed(timeout);
  }

  @override
  Future<RowerLink> connect(FoundRower device) async {
    final error = connectError;
    if (error != null) throw error;
    final link = FakeRowerLink();
    links.add(link);
    return link;
  }
}

/// A rower connection that stays up and sends what the test feeds it.
class FakeRowerLink implements RowerLink {
  final _notifications = StreamController<(String, List<int>)>.broadcast();

  @override
  ResistanceControl? get resistanceControl => null;

  @override
  Stream<(String, List<int>)> get notifications => _notifications.stream;

  /// Sends [bytes] as a notification of [characteristicId].
  void notify(String characteristicId, List<int> bytes) =>
      _notifications.add((characteristicId, bytes));

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

/// Records whether the status bar is hidden.
class FakeSystemBars implements SystemBars {
  var statusBarHidden = false;

  @override
  Future<void> hideStatusBar() async => statusBarHidden = true;

  @override
  Future<void> show() async => statusBarHidden = false;
}
