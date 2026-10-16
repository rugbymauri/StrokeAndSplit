import 'dart:typed_data';

import '../raw_packet.dart';
import 'heart_rate_ids.dart';
import 'heart_rate_measurement.dart';

/// Produces chest strap Heart Rate Measurement notifications, so tests can
/// build strap packets. The simulators send no heart rate.
class HeartRateEncoder {
  const HeartRateEncoder();

  /// A measurement with [heartRate] and optional RR [intervalsMs].
  ///
  /// The heart rate is written as uint16 when [wide] is set or it does not fit
  /// in one byte. [energyExpended] adds the field that readers have to skip.
  RawPacket encode({
    required int heartRate,
    List<int> intervalsMs = const [],
    bool wide = false,
    int? energyExpended,
    required Duration at,
  }) {
    final useWide = wide || heartRate > 0xFF;
    final bytes = BytesBuilder()
      ..addByte((useWide ? HeartRateMeasurement.wideHeartRateFlag : 0) |
          (energyExpended != null ? HeartRateMeasurement.energyExpendedFlag : 0) |
          (intervalsMs.isNotEmpty ? HeartRateMeasurement.intervalsFlag : 0));
    useWide ? _u16(bytes, heartRate) : bytes.addByte(heartRate);
    if (energyExpended != null) _u16(bytes, energyExpended);
    for (final interval in intervalsMs) {
      _u16(bytes, (interval * 1024 / 1000).round());
    }
    return RawPacket(time: at, characteristicId: HeartRateIds.measurement, bytes: bytes.takeBytes());
  }

  static void _u16(BytesBuilder bytes, int value) => bytes
    ..addByte(value & 0xFF)
    ..addByte(value >> 8 & 0xFF);
}
