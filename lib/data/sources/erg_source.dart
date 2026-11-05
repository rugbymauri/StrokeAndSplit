import 'package:erg_protocol/erg_protocol.dart';

import 'resistance_control.dart';

/// Where rowing data comes from. Shown to the user so simulated or replayed
/// data is never mistaken for a live erg.
enum ErgSourceKind { pm5, ftms, simulator, replay }

enum ErgConnectionState { disconnected, scanning, connecting, connected, reconnecting }

/// A source of rowing notifications: a real PM5, an FTMS rower, the
/// simulator or a replay.
///
/// All sources deliver raw bytes of their [protocol], so every one of them
/// goes through the decoder of that protocol.
abstract interface class ErgSource {
  ErgSourceKind get kind;

  /// Protocol of the [packets]; picks the decoder.
  ErgProtocol get protocol;

  /// Whether [packets] carry a force curve per stroke (force-curve, Design D3): a PM5 and the
  /// simulator speaking PM5 do, an FTMS rower does not.
  bool get providesForceCurves;

  /// Sets the resistance level of the connected rower; null for a PM5, a replay
  /// and rowers that cannot (Change resistance-control, Design D1). It may
  /// change when the rower reconnects.
  ResistanceControl? get resistanceControl;

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
