import '../raw_packet.dart';
import '../rowing_event.dart';
import 'ftms_ids.dart';
import 'rower_data.dart';

/// Produces Rower Data notifications, for the simulator in FTMS mode and to
/// turn PM5 recordings into FTMS recordings.
class FtmsEncoder {
  const FtmsEncoder();

  RawPacket encode(RowerData data, {required Duration at}) => RawPacket(
    time: at,
    characteristicId: FtmsIds.rowerData,
    bytes: data.toBytes(),
  );

  /// One complete record with the fields a typical rower sends: stroke rate
  /// and count, distance, pace, power, energy and the device's own time, plus
  /// the resistance level when [tick] has one.
  RawPacket encodeStatus(
    StatusTick tick, {
    required int strokeCount,
    required Duration at,
  }) => encode(
    RowerData(
      strokeRate: (tick.strokeRate ?? 0).toDouble(),
      strokeCount: strokeCount,
      totalDistance: tick.distanceMeters.floor(),
      pace: tick.pace ?? Duration.zero,
      power: tick.watts ?? 0,
      totalEnergy: tick.calories ?? RowerData.energyNotAvailable,
      energyPerHour: RowerData.energyNotAvailable,
      energyPerMinute: 0xFF,
      elapsedTime: tick.elapsed,
      resistanceLevel: tick.resistanceLevel,
    ),
    at: at,
  );
}
