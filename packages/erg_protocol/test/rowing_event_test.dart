import 'package:erg_protocol/erg_protocol.dart';
import 'package:test/test.dart';

const _tick = StatusTick(
  elapsed: Duration(seconds: 61),
  distanceMeters: 250.5,
  workoutType: WorkoutType.justRowSplits,
  workoutState: WorkoutState.workoutRow,
  isRowing: true,
  pace: Duration(minutes: 2),
  watts: 203,
  strokeRate: 24,
  heartRate: 140,
  calories: 17,
  resistanceLevel: 7,
);

void main() {
  group('StatusTick.copyWith', () {
    test('replaces the heart rate and keeps every other field', () {
      final copy = _tick.copyWith(heartRate: 142);

      expect(copy.heartRate, 142);
      expect(
        copy.toString(),
        _tick.toString().replaceFirst('hr: 140', 'hr: 142'),
      );
    });

    test('marks the heart rate as missing with null', () {
      final copy = _tick.copyWith(heartRate: null);

      expect(copy.heartRate, isNull);
      expect(
        copy.toString(),
        _tick.toString().replaceFirst('hr: 140', 'hr: null'),
      );
    });

    test('keeps the heart rate when none is given', () {
      expect(_tick.copyWith().heartRate, 140);
    });

    test('keeps the resistance level', () {
      expect(_tick.copyWith(heartRate: 142).resistanceLevel, 7);
    });
  });
}
