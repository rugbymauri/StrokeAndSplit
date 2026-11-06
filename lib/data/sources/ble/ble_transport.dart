import 'package:erg_protocol/erg_protocol.dart';

import '../resistance_control.dart';

/// Whether Bluetooth can be used right now.
enum BluetoothReadiness { ready, off, unauthorized, unsupported }

/// A rower found during a scan: a PM5 or an FTMS rower.
class FoundRower {
  const FoundRower({
    required this.id,
    required this.name,
    this.protocol = ErgProtocol.pm5,
  });

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

/// Why a connection could not be established; the screens put it into words
/// (Design D4 of translations).
enum RowerConnectError {
  /// The device could not be reached or set up.
  failed,

  /// The device offers no rowing service.
  noRowingService,

  /// A PM5 on a SkiErg or a BikeErg.
  skiErg,
  bikeErg,

  /// An FTMS machine that sends no rower data.
  noRowerData,
}

/// The connection could not be established.
class RowerConnectException implements Exception {
  const RowerConnectException(this.error, {this.message = ''});

  final RowerConnectError error;

  /// A technical detail for the log, not shown to the user.
  final String message;

  /// The device was reached but is no rower, e.g. a PM5 on a SkiErg.
  bool get notARower => switch (error) {
    RowerConnectError.skiErg ||
    RowerConnectError.bikeErg ||
    RowerConnectError.noRowerData => true,
    RowerConnectError.failed || RowerConnectError.noRowingService => false,
  };

  @override
  String toString() =>
      'RowerConnectException: ${error.name}${message.isEmpty ? '' : ' ($message)'}';
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

  /// Sets the resistance level; null when the rower cannot (Change resistance-control, D2).
  ResistanceControl? get resistanceControl;

  Future<void> disconnect();
}
