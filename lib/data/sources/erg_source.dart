import 'package:erg_protocol/erg_protocol.dart';

/// Where rowing data comes from. Shown to the user so simulated or replayed
/// data is never mistaken for a live erg.
enum ErgSourceKind { pm5, simulator, replay }

enum ErgConnectionState { disconnected, scanning, connecting, connected, reconnecting }

/// A source of PM5 notifications: a real PM5, the simulator or a replay.
///
/// All sources deliver raw PM5 bytes, so every one of them goes through the
/// same decoder.
abstract interface class ErgSource {
  ErgSourceKind get kind;

  /// Name shown to the user, e.g. `PM5 430000001 Row`.
  String get name;

  /// Broadcast stream of received notifications.
  Stream<RawPacket> get packets;

  ErgConnectionState get connectionState;

  /// Broadcast stream of connection state changes.
  Stream<ErgConnectionState> get connectionStates;

  /// Connects to the erg or starts producing data.
  Future<void> start();

  /// Disconnects on purpose; a stopped source does not reconnect.
  Future<void> stop();
}
