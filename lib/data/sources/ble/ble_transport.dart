/// Whether Bluetooth can be used right now.
enum BluetoothReadiness { ready, off, unauthorized, unsupported }

/// A PM5 found during a scan.
class FoundPm5 {
  const FoundPm5({required this.id, required this.name});

  /// Platform device id (MAC address on Android and Linux).
  final String id;

  /// Advertised name, e.g. `PM5 430000001 Row`.
  final String name;

  @override
  bool operator ==(Object other) => other is FoundPm5 && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Bluetooth is not usable, e.g. switched off or permission denied.
class BluetoothNotReadyException implements Exception {
  const BluetoothNotReadyException(this.readiness);

  final BluetoothReadiness readiness;

  @override
  String toString() => 'BluetoothNotReadyException: ${readiness.name}';
}

/// The connection could not be established.
class Pm5ConnectException implements Exception {
  const Pm5ConnectException(this.message);

  final String message;

  @override
  String toString() => 'Pm5ConnectException: $message';
}

/// Bluetooth access to PM5 ergs, independent of the BLE plugin in use.
abstract interface class BleTransport {
  Future<BluetoothReadiness> readiness();

  /// Emits the growing list of PM5s in range and closes after [timeout].
  Stream<List<FoundPm5>> scan({Duration timeout});

  /// Connects, sets the sample rate and subscribes to the rowing data.
  ///
  /// Throws [Pm5ConnectException] when the PM5 cannot be reached or is not a
  /// PM5 with rowing service.
  Future<Pm5Link> connect(FoundPm5 device);
}

/// An established connection to a PM5.
abstract interface class Pm5Link {
  /// Notifications as (short characteristic id, bytes).
  Stream<(String, List<int>)> get notifications;

  /// Completes when the connection drops without [disconnect] being called.
  Future<void> get lost;

  Future<void> disconnect();
}
