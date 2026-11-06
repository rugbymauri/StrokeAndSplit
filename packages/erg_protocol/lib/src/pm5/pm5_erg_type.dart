import 'dart:typed_data';

/// The kind of erg a PM5 sits on.
enum Pm5ErgKind { rowErg, skiErg, bikeErg, unknown }

/// Erg machine type as reported in Additional Status 1 (`0x0032`), byte 16.
///
/// Codes follow the `ERGMACHINE_TYPE` list of the Concept2 PM5 Bluetooth
/// Smart Interface Definition. Only known SkiErg and BikeErg codes are
/// rejected, so a new RowErg variant with an unknown code still connects.
abstract final class Pm5ErgType {
  /// Byte of Additional Status 1 with the machine type.
  static const offset = 16;

  static const rowErgCodes = {
    0,
    1,
    2,
    3,
    5,
    7,
    8,
    16,
    17,
    18,
    19,
    20,
    32,
    64,
    224,
  };
  static const skiErgCodes = {128, 143, 225};
  static const bikeErgCodes = {192, 193, 194, 207, 226};

  static Pm5ErgKind classify(int code) => switch (code) {
    _ when rowErgCodes.contains(code) => Pm5ErgKind.rowErg,
    _ when skiErgCodes.contains(code) => Pm5ErgKind.skiErg,
    _ when bikeErgCodes.contains(code) => Pm5ErgKind.bikeErg,
    _ => Pm5ErgKind.unknown,
  };

  /// The kind from the bytes of an Additional Status 1 notification; null
  /// when the packet is too short to tell.
  static Pm5ErgKind? fromAdditionalStatus(Uint8List bytes) =>
      bytes.length > offset ? classify(bytes[offset]) : null;
}
