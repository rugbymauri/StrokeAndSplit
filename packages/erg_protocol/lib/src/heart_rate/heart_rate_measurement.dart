import 'dart:typed_data';

/// One Heart Rate Measurement notification (`0x2A37`) of a chest strap.
///
/// Flags in byte 0: bit 0 selects uint8 or uint16 for the heart rate, bit 3
/// announces Energy Expended, bit 4 RR intervals; both are only checked for
/// their length (Change remove-rr-intervals, Design D1). The sensor contact
/// bits are ignored.
class HeartRateMeasurement {
  const HeartRateMeasurement({required this.heartRate});

  /// Beats per minute as sent by the strap.
  final int heartRate;

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

    // A trailing odd byte is a cut off RR interval. The flag without any
    // interval is accepted, the heart rate is still valid then.
    if (flags & intervalsFlag != 0 && (bytes.length - offset).isOdd) {
      return null;
    }
    return HeartRateMeasurement(heartRate: heartRate);
  }

  @override
  String toString() => 'HeartRateMeasurement(hr: $heartRate)';
}

int _u16(Uint8List b, int offset) => b[offset] | b[offset + 1] << 8;
