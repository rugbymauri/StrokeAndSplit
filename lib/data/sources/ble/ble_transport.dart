import 'package:erg_protocol/erg_protocol.dart';

/// Whether Bluetooth can be used right now.
enum BluetoothReadiness { ready, off, unauthorized, unsupported }

/// A rower found during a scan: a PM5 or an FTMS rower.
class FoundRower {
  const FoundRower({required this.id, required this.name, this.protocol = ErgProtocol.pm5});

  /// Platform device id (MAC address on Android and Linux).
  final String id;

  /// Advertised name, e.g. `PM5 430000001 Row`.
  final String name;

  /// How the rower talks: Concept2 PM5 or FTMS.
  final ErgProtocol protocol;

  @override
  bool operator ==(Object other) => other is FoundRower && other.id == id;

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
class RowerConnectException implements Exception {
  const RowerConnectException(this.message, {this.notARower = false});

  final String message;

  /// The device was reached but is no rower, e.g. a PM5 on a SkiErg.
  final bool notARower;

  @override
  String toString() => 'RowerConnectException: $message';
}

/// Bluetooth access to rowers, independent of the BLE plugin in use.
abstract interface class BleTransport {
  Future<BluetoothReadiness> readiness();

  /// Emits the growing list of rowers in range and closes after [timeout].
  Stream<List<FoundRower>> scan({Duration timeout});

  /// Connects, sets the sample rate and subscribes to the rowing data.
  ///
  /// Throws [RowerConnectException] when the rower cannot be reached or does
  /// not offer rowing data.
  Future<RowerLink> connect(FoundRower device);
}

/// An established connection to a rower.
abstract interface class RowerLink {
  /// Notifications as (short characteristic id, bytes).
  Stream<(String, List<int>)> get notifications;

  /// Completes when the connection drops without [disconnect] being called.
  Future<void> get lost;

  Future<void> disconnect();
}
