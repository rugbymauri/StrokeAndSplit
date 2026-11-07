import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sessions/session_accumulator.dart';
import 'package:strokesplit/data/sessions/session_repository.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/workouts/workout_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

import 'package:strokesplit/data/sessions/session_plan.dart';

void main() {
  test(
    'keeps a session that ended with the app and marks it incomplete',
    () async {
      final db = openTestDatabase();
      final repository = SessionRepository(db);
      final packets = loadFixture('just_row').packets;

      // Recording: two batches reach the database, then the app ends.
      final id = await repository.create(
        startedAt: DateTime(2026, 10, 15, 18),
        source: ErgSourceKind.pm5,
      );
      final accumulator = SessionAccumulator(id);
      final half = packets.length ~/ 2;
      packets.take(half).forEach(accumulator.add);
      await repository.write(accumulator.takeBatch());
      final writtenProgress = accumulator.progress;
      packets.skip(half).forEach(accumulator.add);

      // Next app start.
      final recovered = await SessionRepository(db).recoverInterrupted();

      final session = await repository.get(id);
      expect(recovered, 1);
      expect(session!.status, SessionStatus.incomplete);
      // The session time of the last stored sample (Change auto-pause).
      final stored = await db.select(db.samples).get();
      expect(
        session.durationMs,
        stored.map((s) => s.activeMs!).reduce((a, b) => a > b ? a : b),
      );
      expect(
        session.durationMs,
        lessThanOrEqualTo(writtenProgress.elapsed.inMilliseconds),
      );
      expect(session.distanceDm, (writtenProgress.distanceMeters * 10).round());
      expect(session.distanceDm, greaterThan(0));
    },
  );

  test('leaves finished sessions alone', () async {
    final db = openTestDatabase();
    final repository = SessionRepository(db);
    final id = await repository.create(
      startedAt: DateTime(2026, 10, 15),
      source: ErgSourceKind.simulator,
    );
    await repository.finish(id);

    expect(await repository.recoverInterrupted(), 0);
    expect((await repository.get(id))!.status, SessionStatus.complete);
  });

  test(
    'finishes the lap that was running when the app ended as incomplete',
    () async {
      final db = openTestDatabase();
      final repository = SessionRepository(db);
      final packets = loadFixture('just_row').packets;
      // Laps a fifth of the rowed distance, so the app can end in lap 3.
      final rowed =
          decodeTicks(packets).last.distanceMeters -
          decodeTicks(packets).first.distanceMeters;
      final course = CourseDefinition.single(
        axis: CourseAxis.distance,
        length: rowed ~/ 5,
      );
      final courseId = await CourseRepository(db).create('Seerunde', course);
      final workouts = WorkoutRepository(db);
      final workout = (await workouts.get(
        await workouts.create(
          'Seerunde x5',
          courseIds: [courseId],
          length: const LapCount(5),
        ),
      ))!;

      final id = await repository.create(
        startedAt: DateTime(2026, 10, 16),
        source: ErgSourceKind.pm5,
        plan: workout.toPlan(),
      );
      final accumulator = SessionAccumulator(
        id,
        course: course,
        plannedLaps: 5,
      );
      // The app ends halfway through lap 3.
      bool inFirstHalfOfLap3() =>
          accumulator.lapProgress!.lap < 3 ||
          accumulator.lapProgress!.remaining > rowed / 10;
      final iterator = packets.iterator;
      while (iterator.moveNext() && inFirstHalfOfLap3()) {
        accumulator.add(iterator.current);
      }
      expect(accumulator.lapProgress!.lap, 3);
      await repository.write(accumulator.takeBatch());
      final lastSample = (await db.select(db.samples).get()).last;

      await SessionRepository(db).recoverInterrupted();

      final laps = await db.select(db.laps).get();
      expect(
        [for (final l in laps) (l.lapNo, l.complete)],
        [(1, true), (2, true), (3, false)],
      );
      expect(laps.last.startDistanceDm, laps[1].endDistanceDm);
      // Laps run on the session time (Change auto-pause).
      expect(
        (laps.last.endWallMs, laps.last.endDistanceDm),
        (lastSample.activeMs, lastSample.distanceDm),
      );
      expect((await repository.get(id))!.status, SessionStatus.incomplete);
      final segments = await db.select(db.lapSegments).get();
      expect([for (final s in segments) s.lapNo], [1, 2, 3]);
    },
  );
}
