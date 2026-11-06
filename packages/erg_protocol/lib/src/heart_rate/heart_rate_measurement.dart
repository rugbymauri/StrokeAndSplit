import 'dart:typed_data';

/// One Heart Rate Measurement notification (`0x2A37`) of a chest strap.
///
/// Flags in byte 0: bit 0 selects uint8 or uint16 for the heart rate, bit 3
/// announces Energy Expended (skipped), bit 4 RR intervals. The sensor
/// contact bits are ignored.
class HeartRateMeasurement {
  HeartRateMeasurement({
    required this.heartRate,
    List<int> intervalsMs = const [],
  }) : intervalsMs = List.unmodifiable(intervalsMs);

  /// Beats per minute as sent by the strap.
  final int heartRate;

  /// RR intervals in milliseconds, oldest first; empty when the strap sent none.
  final List<int> intervalsMs;

  static const wideHeartRateFlag = 0x01;
  static const energyExpendedFlag = 0x08;
  static const intervalsFlag = 0x10;

  /// Parses [bytes]; null when the packet is shorter than its flags announce.
  static HeartRateMeasurement? parse(Uint8List bytes) {
    if (bytes.isEmpty) return null;
    final flags = bytes[0];
    final wide = flags & wideHeartRateFlag != 0;
    var offset = 1;
    final heartRateEnd = offset + (wide ? 2 : 1);
    if (bytes.length < heartRateEnd) return null;
    final heartRate = wide ? _u16(bytes, offset) : bytes[offset];
    offset = heartRateEnd;

    if (flags & energyExpendedFlag != 0) {
      offset += 2;
      if (bytes.length < offset) return null;
    }

    final intervals = <int>[];
    if (flags & intervalsFlag != 0) {
      // A trailing odd byte is a cut off interval. The flag without any
      // interval is accepted, the heart rate is still valid then.
      if ((bytes.length - offset).isOdd) return null;
      for (; offset < bytes.length; offset += 2) {
        intervals.add((_u16(bytes, offset) * 1000 / 1024).round());
      }
    }
    return HeartRateMeasurement(heartRate: heartRate, intervalsMs: intervals);
  }

  @override
  String toString() => 'HeartRateMeasurement(hr: $heartRate, rr: $intervalsMs)';
}

int _u16(Uint8List b, int offset) => b[offset] | b[offset + 1] << 8;
