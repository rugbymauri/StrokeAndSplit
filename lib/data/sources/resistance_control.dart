import 'package:erg_protocol/erg_protocol.dart';

export 'package:erg_protocol/erg_protocol.dart' show ResistanceRange;

/// How a rower answered a new resistance level (Change resistance-control, Design D1).
enum ResistanceResult {
  accepted,

  /// The rower refused, e.g. because another client has control.
  rejected,

  /// The rower did not answer in time or the write failed.
  noAnswer,
}

/// Sets the resistance level of a rower that supports it.
abstract interface class ResistanceControl {
  /// The levels the rower accepts.
  ResistanceRange get range;

  /// Asks the rower for [level], a whole level within [range].
  Future<ResistanceResult> setLevel(int level);
}
