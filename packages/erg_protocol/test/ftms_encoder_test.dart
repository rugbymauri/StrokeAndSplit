import 'package:erg_protocol/erg_protocol.dart';
import 'package:test/test.dart';

void main() {
  const encoder = FtmsEncoder();

  test('writes Rower Data that reads back the same', () {
    const data = RowerData(
      strokeRate: 22.5,
      strokeCount: 298,
      averageStrokeRate: 21,
      totalDistance: 66012,
      pace: Duration(seconds: 125),
      averagePace: Duration(seconds: 130),
      power: 203,
      averagePower: 190,
      resistanceLevel: 5,
      totalEnergy: 300,
      energyPerHour: 900,
      energyPerMinute: 15,
      heartRate: 151,
      metabolicEquivalent: 8.7,
      elapsedTime: Duration(seconds: 300),
      remainingTime: Duration(seconds: 60),
    );
    final packet = encoder.encode(data, at: const Duration(seconds: 3));
    expect((packet.characteristicId, packet.time), (FtmsIds.rowerData, const Duration(seconds: 3)));

    final read = RowerData.parse(packet.bytes)!;
    expect(read.moreData, isFalse);
    expect((read.strokeRate, read.strokeCount, read.averageStrokeRate), (22.5, 298, 21.0));
    expect((read.totalDistance, read.pace, read.averagePace), (66012, data.pace, data.averagePace));
    expect((read.power, read.averagePower, read.resistanceLevel), (203, 190, 5));
    expect((read.totalEnergy, read.energyPerHour, read.energyPerMinute), (300, 900, 15));
    expect((read.heartRate, read.metabolicEquivalent), (151, 8.7));
    expect((read.elapsedTime, read.remainingTime), (data.elapsedTime, data.remainingTime));
  });

  test('writes the part of a split record without stroke rate and count', () {
    final packet = encoder.encode(const RowerData(moreData: true, heartRate: 140), at: Duration.zero);
    final read = RowerData.parse(packet.bytes)!;
    expect((read.moreData, read.strokeCount, read.heartRate), (true, null, 140));
  });

  test('writes a status as the fields of a typical rower', () {
    const tick = StatusTick(
      elapsed: Duration(minutes: 4),
      distanceMeters: 1000.7,
      workoutType: WorkoutType.justRowSplits,
      workoutState: WorkoutState.workoutRow,
      isRowing: true,
      pace: Duration(minutes: 2),
      watts: 203,
      strokeRate: 22,
      calories: 50,
    );
    final read = RowerData.parse(encoder.encodeStatus(tick, strokeCount: 88, at: Duration.zero).bytes)!;
    expect((read.strokeRate, read.strokeCount, read.totalDistance), (22.0, 88, 1000));
    expect((read.pace, read.power, read.totalEnergy), (const Duration(minutes: 2), 203, 50));
    expect(read.elapsedTime, const Duration(minutes: 4));
    expect(read.heartRate, isNull);
  });
}
