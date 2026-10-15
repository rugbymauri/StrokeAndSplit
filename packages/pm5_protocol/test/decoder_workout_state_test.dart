import 'package:pm5_protocol/pm5_protocol.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  test('reports the initial workout state', () {
    final first = decodeAll(loadFixture('just_row').packets).first;

    expect(first, isA<WorkoutStateChanged>().having((e) => e.previous, 'previous', WorkoutState.unknown));
  });

  test('reports each new workout started on the PM5 as a reset', () {
    final changes = decodeAll(loadFixture('reset').packets).whereType<WorkoutStateChanged>().toList();
    final resets = changes.where((c) => c.isReset).toList();

    expect(resets, hasLength(3));
    expect(resets.map((r) => r.elapsed), everyElement(Duration.zero));
    expect(changes.map((c) => c.current), containsAllInOrder([WorkoutState.workoutRow, WorkoutState.terminate]));
  });

  test('restarts stroke numbering after a reset', () {
    final events = decodeAll(loadFixture('reset').packets);
    final lastReset = events.lastIndexWhere((e) => e is WorkoutStateChanged && e.isReset);
    final strokesAfter = events.skip(lastReset).whereType<Stroke>().toList();

    expect(strokesAfter, isNotEmpty);
    expect(strokesAfter.first.strokeNumber, lessThan(3));
  });

  test('treats a pause as no state change', () {
    final changes = decodeAll(loadFixture('pause').packets).whereType<WorkoutStateChanged>().toList();

    expect(changes, hasLength(1));
    expect(changes.single.current, WorkoutState.workoutRow);
  });
}
