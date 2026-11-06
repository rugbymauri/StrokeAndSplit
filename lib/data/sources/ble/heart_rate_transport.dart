import 'ble_transport.dart';

export 'package:erg_protocol/erg_protocol.dart' show HeartRateIds;

/// A heart rate strap found during a scan.
class FoundHeartRateMonitor {
  const FoundHeartRateMonitor({required this.id, required this.name});

  /// Platform device id (MAC address on Android and Linux).
  final String id;

  /// Advertised name, e.g. `Polar H10 1A2B3C4D`.
  final String name;

  @override
  bool operator ==(Object other) =>
      other is FoundHeartRateMonitor && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Why a strap could not be connected.
enum HeartRateConnectError {
  /// The strap could not be reached or set up, e.g. because it already hangs
  /// on a watch or the rower.
  failed,

  /// The device offers no Heart Rate service.
  noHeartRateService,
}

/// The connection to a strap could not be established.
class HeartRateConnectException implements Exception {
  const HeartRateConnectException(this.error, {this.message = ''});

  final HeartRateConnectError error;

  /// A technical detail for the log, not shown to the user.
  final String message;

  @override
  String toString() =>
      'HeartRateConnectException: ${error.name}${message.isEmpty ? '' : ' ($message)'}';
}

/// Bluetooth access to heart rate straps, independent of the BLE plugin in
/// use and separate from [BleTransport] (Design D2).
///
/// The method names differ from those of [BleTransport], so one class can
/// implement both and share the readiness check.
abstract interface class HeartRateTransport {
  Future<BluetoothReadiness> readiness();

  /// Emits the growing list of straps in range, only devices offering the
  /// Heart Rate service, and closes after [timeout].
  Stream<List<FoundHeartRateMonitor>> scanHeartRateMonitors({Duration timeout});

  /// Connects and subscribes to the Heart Rate Measurement.
  ///
  /// Throws [HeartRateConnectException] when the strap cannot be reached or
  /// offers no Heart Rate service.
  Future<HeartRateLink> connectHeartRateMonitor(FoundHeartRateMonitor monitor);
}

/// An established connection to a strap.
abstract interface class HeartRateLink {
  /// Measurements as (short characteristic id, bytes), i.e. `2a37`.
  Stream<(String, List<int>)> get notifications;

  /// Completes when the connection drops without [disconnect] being called.
  Future<void> get lost;

  Future<void> disconnect();
}
