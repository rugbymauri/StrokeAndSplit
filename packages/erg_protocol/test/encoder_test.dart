import 'package:erg_protocol/erg_protocol.dart';
import 'package:test/test.dart';

const _encoder = Pm5Encoder();

List<RowingEvent> _decode(List<RawPacket> packets) {
  final decoder = Pm5Decoder(onWarning: (w) => fail(w));
  return [for (final p in packets) ...decoder.decode(p)];
}

void main() {
  test('round-trips a status tick', () {
    const tick = StatusTick(
      elapsed: Duration(minutes: 3, seconds: 12, milliseconds: 340),
      distanceMeters: 812.3,
      workoutType: WorkoutType.justRowSplits,
      workoutState: WorkoutState.workoutRow,
      isRowing: true,
      pace: Duration(minutes: 1, seconds: 58, milliseconds: 70),
      strokeRate: 24,
      heartRate: 142,
      calories: 47,
    );

    final decoded = _decode(_encoder.encodeStatus(tick, at: Duration.zero)).whereType<StatusTick>().single;

    expect(decoded.elapsed, tick.elapsed);
    expect(decoded.distanceMeters, tick.distanceMeters);
    expect(decoded.workoutType, tick.workoutType);
    expect(decoded.workoutState, tick.workoutState);
    expect(decoded.isRowing, isTrue);
    expect(decoded.pace, tick.pace);
    expect(decoded.watts, wattsForPace(tick.pace!));
    expect(decoded.strokeRate, 24);
    expect(decoded.heartRate, 142);
    expect(decoded.calories, 47);
  });

  test('round-trips an idle status tick without heart rate', () {
    const tick = StatusTick(
      elapsed: Duration(seconds: 30),
      distanceMeters: 100,
      workoutType: WorkoutType.justRowSplits,
      workoutState: WorkoutState.waitToBegin,
      isRowing: false,
    );

    final decoded = _decode(_encoder.encodeStatus(tick, at: Duration.zero)).whereType<StatusTick>().single;

    expect(decoded.isRowing, isFalse);
    expect(decoded.workoutState, WorkoutState.waitToBegin);
    expect(decoded.pace, isNull);
    expect(decoded.heartRate, isNull);
  });

  test('round-trips a stroke through drive end and recovery end', () {
    const stroke = Stroke(
      elapsed: Duration(seconds: 42, milliseconds: 170),
      strokeNumber: 17,
      distanceMeters: 160.4,
      driveLengthMeters: 1.38,
      driveTime: Duration(milliseconds: 820),
      recoveryTime: Duration(milliseconds: 1640),
      peakForceNewtons: 712.5,
      averageForceNewtons: 431.0,
      watts: 211,
    );

    final decoded = _decode([
      ..._encoder.encodeDriveEnd(stroke, at: Duration.zero),
      _encoder.encodeRecoveryEnd(stroke, at: Duration.zero),
    ]).whereType<Stroke>().single;

    expect(decoded.elapsed, stroke.elapsed);
    expect(decoded.strokeNumber, 17);
    expect(decoded.distanceMeters, stroke.distanceMeters);
    expect(decoded.driveLengthMeters, stroke.driveLengthMeters);
    expect(decoded.driveTime, stroke.driveTime);
    expect(decoded.recoveryTime, stroke.recoveryTime);
    // Forces travel in 0.1 lbf steps.
    expect(decoded.peakForceNewtons, closeTo(stroke.peakForceNewtons, 0.45));
    expect(decoded.averageForceNewtons, closeTo(stroke.averageForceNewtons, 0.45));
    expect(decoded.watts, 211);
  });

  test('produces packets the size of real PM5 notifications', () {
    const stroke = Stroke(
      elapsed: Duration.zero,
      strokeNumber: 1,
      distanceMeters: 0,
      driveLengthMeters: 1,
      driveTime: Duration.zero,
      recoveryTime: Duration.zero,
      peakForceNewtons: 0,
      averageForceNewtons: 0,
    );
    const tick = StatusTick(
      elapsed: Duration.zero,
      distanceMeters: 0,
      workoutType: WorkoutType.justRowSplits,
      workoutState: WorkoutState.workoutRow,
      isRowing: true,
    );
    final packets = [
      ..._encoder.encodeStatus(tick, at: Duration.zero),
      ..._encoder.encodeDriveEnd(stroke, at: Duration.zero),
    ];

    expect(
      {for (final p in packets) p.characteristicId: p.bytes.length},
      {'0031': 19, '0032': 17, '0033': 20, '0035': 20, '0036': 15},
    );
  });
}
