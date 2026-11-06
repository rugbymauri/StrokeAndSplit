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

  group('HeartBeatIntervals', () {
    test('lets the last interval end at the receive time and earlier ones before it', () {
      final event = HeartBeatIntervals(
        elapsed: const Duration(seconds: 10),
        time: const Duration(seconds: 12),
        intervalsMs: [812, 790],
      );

      expect(event.intervalEnds, [
        const Duration(milliseconds: 11210),
        const Duration(seconds: 12),
      ]);
    });

    test('keeps its own copy of the intervals', () {
      final intervals = [800];
      final event = HeartBeatIntervals(
        elapsed: Duration.zero,
        time: Duration.zero,
        intervalsMs: intervals,
      );
      intervals.add(900);

      expect(event.intervalsMs, [800]);
      expect(() => event.intervalsMs.add(1), throwsUnsupportedError);
    });
  });
}
