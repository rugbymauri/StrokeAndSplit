import 'dart:typed_data';

/// What a Fitness Machine Feature (`0x2ACC`) says about the resistance level
/// (FTMS 1.0, 4.3).
class FtmsFeatures {
  const FtmsFeatures({required this.reportsResistanceLevel, required this.setsResistanceLevel});

  /// Machine feature bit 7: the level is part of the measurements.
  final bool reportsResistanceLevel;

  /// Target setting bit 2: the level can be set over the control point.
  final bool setsResistanceLevel;

  /// Parses the eight bytes of the characteristic; null when they are fewer.
  static FtmsFeatures? parse(List<int> bytes) {
    if (bytes.length < 8) return null;
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    final machine = data.getUint32(0, Endian.little);
    final targets = data.getUint32(4, Endian.little);
    return FtmsFeatures(
      reportsResistanceLevel: machine & (1 << 7) != 0,
      setsResistanceLevel: targets & (1 << 2) != 0,
    );
  }

  @override
  String toString() => 'FtmsFeatures(reports: $reportsResistanceLevel, sets: $setsResistanceLevel)';
}

/// The resistance levels a rower accepts, in whole levels (Change
/// resistance-control, Design D2).
class ResistanceRange {
  const ResistanceRange({required this.min, required this.max, this.step = 1});

  final int min;
  final int max;
  final int step;

  /// Parses a Supported Resistance Level Range (`0x2AD6`): minimum and maximum
  /// as s16, increment as u16, all in tenths. Null when the bytes are too few
  /// or the range makes no sense, so the app never sends a guessed level.
  static ResistanceRange? parse(List<int> bytes) {
    if (bytes.length < 6) return null;
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    final minTenths = data.getInt16(0, Endian.little);
    final maxTenths = data.getInt16(2, Endian.little);
    final stepTenths = data.getUint16(4, Endian.little);
    if (stepTenths == 0 || minTenths < 0 || minTenths > maxTenths) return null;
    final min = (minTenths + 9) ~/ 10;
    final max = maxTenths ~/ 10;
    final step = (stepTenths + 9) ~/ 10;
    if (min > max) return null;
    return ResistanceRange(min: min, max: max, step: step);
  }

  /// [level] moved into the range and onto its steps.
  int clamp(int level) {
    final inside = level.clamp(min, max);
    final steps = ((inside - min) / step).round();
    return (min + steps * step).clamp(min, max);
  }

  /// A reported level as a whole level: some rowers report tenths, e.g. 60
  /// for level 6 (Design, Risks). Levels inside the range stay as they are.
  int wholeLevel(int reported) {
    if (reported > max && reported % 10 == 0 && reported ~/ 10 >= min && reported ~/ 10 <= max) {
      return reported ~/ 10;
    }
    return reported;
  }

  @override
  bool operator ==(Object other) => other is ResistanceRange && other.min == min && other.max == max && other.step == step;

  @override
  int get hashCode => Object.hash(min, max, step);

  @override
  String toString() => 'ResistanceRange($min–$max, step $step)';
}

/// Op codes and results of the Fitness Machine Control Point (`0x2AD9`).
abstract final class FtmsControl {
  static const requestControl = 0x00;
  static const setTargetResistanceLevel = 0x04;
  static const startOrResume = 0x07;
  static const responseCode = 0x80;

  static const success = 0x01;
  static const notSupported = 0x02;
  static const invalidParameter = 0x03;
  static const failed = 0x04;
  static const controlNotPermitted = 0x05;

  /// Largest level in tenths that fits the single byte of FTMS 1.0.
  static const maxNarrowTenths = 0xFF;

  /// Set Target Resistance Level with [level] in tenths: one unsigned byte as
  /// in FTMS 1.0, which the Domyos Woodrower expects, or with [wide] a signed
  /// 16-bit value as some rowers expect (Design D3).
  static List<int> setResistanceLevel(int level, {bool wide = false}) {
    final tenths = level * 10;
    if (wide || tenths > maxNarrowTenths) {
      final data = ByteData(2)..setInt16(0, tenths, Endian.little);
      return [setTargetResistanceLevel, data.getUint8(0), data.getUint8(1)];
    }
    return [setTargetResistanceLevel, tenths];
  }

  /// Whether a level needs the 16-bit form anyway.
  static bool needsWide(int level) => level * 10 > maxNarrowTenths;
}

/// An answer of the control point: `80 <request op code> <result>`.
class FtmsControlResponse {
  const FtmsControlResponse(this.requestOpCode, this.result);

  final int requestOpCode;
  final int result;

  bool get succeeded => result == FtmsControl.success;

  /// Null when [bytes] are no answer.
  static FtmsControlResponse? parse(List<int> bytes) {
    if (bytes.length < 3 || bytes[0] != FtmsControl.responseCode) return null;
    return FtmsControlResponse(bytes[1], bytes[2]);
  }

  @override
  String toString() => 'FtmsControlResponse(op $requestOpCode, result $result)';
}
