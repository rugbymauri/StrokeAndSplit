import 'dart:typed_data';

/// One Rower Data notification (`0x2AD1`) as defined by FTMS 1.0.
///
/// Only the fields whose flag is set are present; all others are null. Units
/// are converted: stroke rates in strokes per minute, distance in metres,
/// paces per 500 m, energy in kcal.
class RowerData {
  const RowerData({
    this.moreData = false,
    this.strokeRate,
    this.strokeCount,
    this.averageStrokeRate,
    this.totalDistance,
    this.pace,
    this.averagePace,
    this.power,
    this.averagePower,
    this.resistanceLevel,
    this.totalEnergy,
    this.energyPerHour,
    this.energyPerMinute,
    this.heartRate,
    this.metabolicEquivalent,
    this.elapsedTime,
    this.remainingTime,
  });

  /// True when more parts of the same record follow; then [strokeRate] and
  /// [strokeCount] are missing (flag bit 0 is inverted).
  final bool moreData;
  final double? strokeRate;
  final int? strokeCount;
  final double? averageStrokeRate;
  final int? totalDistance;
  final Duration? pace;
  final Duration? averagePace;
  final int? power;
  final int? averagePower;
  final int? resistanceLevel;

  /// `0xFFFF` means "not available", as defined by the specification.
  final int? totalEnergy;
  final int? energyPerHour;
  final int? energyPerMinute;
  final int? heartRate;
  final double? metabolicEquivalent;
  final Duration? elapsedTime;
  final Duration? remainingTime;

  /// Value of [totalEnergy] and [energyPerHour] for "not available".
  static const energyNotAvailable = 0xFFFF;

  /// Parses [bytes]; null when the packet is shorter than its flags announce.
  static RowerData? parse(Uint8List bytes) {
    if (bytes.length < 2) return null;
    final reader = _Reader(bytes);
    final flags = reader.u16();
    bool has(int bit) => flags & (1 << bit) != 0;
    final moreData = has(0);
    try {
      return RowerData(
        moreData: moreData,
        strokeRate: moreData ? null : reader.u8() / 2,
        strokeCount: moreData ? null : reader.u16(),
        averageStrokeRate: has(1) ? reader.u8() / 2 : null,
        totalDistance: has(2) ? reader.u24() : null,
        pace: has(3) ? Duration(seconds: reader.u16()) : null,
        averagePace: has(4) ? Duration(seconds: reader.u16()) : null,
        power: has(5) ? reader.s16() : null,
        averagePower: has(6) ? reader.s16() : null,
        resistanceLevel: has(7) ? reader.s16() : null,
        totalEnergy: has(8) ? reader.u16() : null,
        energyPerHour: has(8) ? reader.u16() : null,
        energyPerMinute: has(8) ? reader.u8() : null,
        heartRate: has(9) ? reader.u8() : null,
        metabolicEquivalent: has(10) ? reader.u8() / 10 : null,
        elapsedTime: has(11) ? Duration(seconds: reader.u16()) : null,
        remainingTime: has(12) ? Duration(seconds: reader.u16()) : null,
      );
    } on RangeError {
      return null;
    }
  }

  /// The notification bytes, with a flag set for every field that is not
  /// null. Energy needs all three energy fields.
  Uint8List toBytes() {
    final out = BytesBuilder();
    void u8(int v) => out.addByte(v & 0xFF);
    void u16(int v) => out.add([v & 0xFF, v >> 8 & 0xFF]);
    void u24(int v) => out.add([v & 0xFF, v >> 8 & 0xFF, v >> 16 & 0xFF]);

    final hasEnergy = totalEnergy != null || energyPerHour != null || energyPerMinute != null;
    final flags = (moreData ? 1 : 0) |
        (averageStrokeRate != null ? 1 << 1 : 0) |
        (totalDistance != null ? 1 << 2 : 0) |
        (pace != null ? 1 << 3 : 0) |
        (averagePace != null ? 1 << 4 : 0) |
        (power != null ? 1 << 5 : 0) |
        (averagePower != null ? 1 << 6 : 0) |
        (resistanceLevel != null ? 1 << 7 : 0) |
        (hasEnergy ? 1 << 8 : 0) |
        (heartRate != null ? 1 << 9 : 0) |
        (metabolicEquivalent != null ? 1 << 10 : 0) |
        (elapsedTime != null ? 1 << 11 : 0) |
        (remainingTime != null ? 1 << 12 : 0);
    u16(flags);
    if (!moreData) {
      u8(((strokeRate ?? 0) * 2).round());
      u16(strokeCount ?? 0);
    }
    if (averageStrokeRate case final v?) u8((v * 2).round());
    if (totalDistance case final v?) u24(v);
    if (pace case final v?) u16(v.inSeconds);
    if (averagePace case final v?) u16(v.inSeconds);
    if (power case final v?) u16(v);
    if (averagePower case final v?) u16(v);
    if (resistanceLevel case final v?) u16(v);
    if (hasEnergy) {
      u16(totalEnergy ?? energyNotAvailable);
      u16(energyPerHour ?? energyNotAvailable);
      u8(energyPerMinute ?? 0xFF);
    }
    if (heartRate case final v?) u8(v);
    if (metabolicEquivalent case final v?) u8((v * 10).round());
    if (elapsedTime case final v?) u16(v.inSeconds);
    if (remainingTime case final v?) u16(v.inSeconds);
    return out.toBytes();
  }
}

class _Reader {
  _Reader(this._bytes);

  final Uint8List _bytes;
  var _offset = 0;

  int u8() => _bytes[_take(1)];

  int u16() {
    final o = _take(2);
    return _bytes[o] | _bytes[o + 1] << 8;
  }

  int s16() => u16().toSigned(16);

  int u24() {
    final o = _take(3);
    return _bytes[o] | _bytes[o + 1] << 8 | _bytes[o + 2] << 16;
  }

  int _take(int length) {
    if (_offset + length > _bytes.length) throw RangeError('Rower Data ends at ${_bytes.length} bytes');
    final offset = _offset;
    _offset += length;
    return offset;
  }
}
