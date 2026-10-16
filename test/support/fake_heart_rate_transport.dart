import 'dart:async';

import 'package:aergrow/data/sources/ble/ble_transport.dart';
import 'package:aergrow/data/sources/ble/heart_rate_transport.dart';

/// A [HeartRateTransport] whose answers are set by the test.
class FakeHeartRateTransport implements HeartRateTransport {
  FakeHeartRateTransport({this.readinessValue = BluetoothReadiness.ready, this.found = const [], this.connectError});

  BluetoothReadiness readinessValue;
  List<FoundHeartRateMonitor> found;

  /// Thrown by every connect attempt while set, e.g. a strap busy at a watch.
  HeartRateConnectException? connectError;

  /// Monitors of all connect attempts, successful or not.
  final attempts = <FoundHeartRateMonitor>[];

  /// The links handed out, the latest last.
  final links = <FakeHeartRateLink>[];

  @override
  Future<BluetoothReadiness> readiness() async => readinessValue;

  @override
  Stream<List<FoundHeartRateMonitor>> scanHeartRateMonitors({Duration timeout = const Duration(seconds: 15)}) async* {
    if (found.isNotEmpty) yield found;
    await Future<void>.delayed(timeout);
  }

  @override
  Future<HeartRateLink> connectHeartRateMonitor(FoundHeartRateMonitor monitor) async {
    attempts.add(monitor);
    final error = connectError;
    if (error != null) throw error;
    final link = FakeHeartRateLink(monitor);
    links.add(link);
    return link;
  }
}

/// A strap connection the test feeds and drops.
class FakeHeartRateLink implements HeartRateLink {
  FakeHeartRateLink(this.monitor);

  final FoundHeartRateMonitor monitor;
  final _notifications = StreamController<(String, List<int>)>.broadcast();
  final _lost = Completer<void>();
  var disconnected = false;

  @override
  Stream<(String, List<int>)> get notifications => _notifications.stream;

  /// Sends a Heart Rate Measurement.
  void notify(List<int> bytes) => _notifications.add((HeartRateIds.measurement, bytes));

  /// Drops the connection unexpectedly.
  void drop() {
    if (!_lost.isCompleted) _lost.complete();
  }

  @override
  Future<void> get lost => _lost.future;

  @override
  Future<void> disconnect() async => disconnected = true;
}
