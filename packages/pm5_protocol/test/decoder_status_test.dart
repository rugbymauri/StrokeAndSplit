import 'package:pm5_protocol/pm5_protocol.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  final recording = loadFixture('just_row');
  final ticks = decodeAll(recording.packets).whereType<StatusTick>().toList();

  test('emits one status tick per general status notification', () {
    expect(ticks, hasLength(countPackets(recording, Pm5Characteristics.generalStatus)));
  });

  test('decodes the metrics of a rowing moment', () {
    final tick = ticks.firstWhere((t) => t.elapsed == const Duration(milliseconds: 5580));

    expect(tick.distanceMeters, 11.8);
    expect(tick.workoutType, WorkoutType.justRowSplits);
    expect(tick.workoutState, WorkoutState.workoutRow);
    expect(tick.isRowing, isTrue);
    expect(tick.pace, const Duration(milliseconds: 216160));
    expect(tick.strokeRate, 29);
    expect(tick.watts, 35);
    expect(tick.calories, 0);
  });

  test('marks a missing heart rate monitor as absent instead of 255', () {
    expect(ticks.map((t) => t.heartRate), everyElement(isNull));
  });

  test('reports no pace while not rowing', () {
    final idle = ticks.where((t) => !t.isRowing);

    expect(idle, isNotEmpty);
    expect(idle.map((t) => t.pace), everyElement(isNull));
    expect(idle.map((t) => t.watts), everyElement(isNull));
  });

  test('keeps emitting ticks with a frozen clock during a pause', () {
    final pauseTicks = decodeAll(loadFixture('pause').packets)
        .whereType<StatusTick>()
        .where((t) => t.elapsed == const Duration(milliseconds: 228170))
        .toList();

    expect(pauseTicks.length, greaterThan(300));
    expect(pauseTicks.map((t) => t.isRowing), everyElement(isFalse));
  });

  test('derives watts from pace like the PM5 display', () {
    expect(wattsForPace(const Duration(minutes: 2)), 203);
    expect(wattsForPace(const Duration(minutes: 1, seconds: 45)), 302);
  });
}
