import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/sessions/session_accumulator.dart';
import 'package:aergrow/data/sessions/session_repository.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/templates/template_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  test('keeps a session that ended with the app and marks it incomplete', () async {
    final db = openTestDatabase();
    final repository = SessionRepository(db);
    final packets = loadFixture('just_row').packets;

    // Recording: two batches reach the database, then the app ends.
    final id = await repository.create(startedAt: DateTime(2026, 10, 15, 18), source: ErgSourceKind.pm5);
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
    expect(session.durationMs, writtenProgress.elapsed.inMilliseconds);
    expect(session.distanceDm, (writtenProgress.distanceMeters * 10).round());
    expect(session.distanceDm, greaterThan(0));
  });

  test('leaves finished sessions alone', () async {
    final db = openTestDatabase();
    final repository = SessionRepository(db);
    final id = await repository.create(startedAt: DateTime(2026, 10, 15), source: ErgSourceKind.simulator);
    await repository.finish(id);

    expect(await repository.recoverInterrupted(), 0);
    expect((await repository.get(id))!.status, SessionStatus.complete);
  });

  test('finishes the lap that was running when the app ended as incomplete', () async {
    final db = openTestDatabase();
    final repository = SessionRepository(db);
    final packets = loadFixture('just_row').packets;
    // Laps a fifth of the rowed distance, so the app can end in lap 3.
    final rowed = decodeTicks(packets).last.distanceMeters - decodeTicks(packets).first.distanceMeters;
    final course = CourseDefinition.single(axis: CourseAxis.distance, length: rowed ~/ 5);
    final courseId = await CourseRepository(db).create('Seerunde', course);
    final templates = TemplateRepository(db);
    final template = (await templates.get(await templates.create('Seerunde x5', courseId: courseId, laps: 5)))!;

    final id =
        await repository.create(startedAt: DateTime(2026, 10, 16), source: ErgSourceKind.pm5, template: template);
    final accumulator = SessionAccumulator(id, course: course, plannedLaps: 5);
    // The app ends halfway through lap 3.
    bool inFirstHalfOfLap3() => accumulator.lapProgress!.lap < 3 || accumulator.lapProgress!.remaining > rowed / 10;
    final iterator = packets.iterator;
    while (iterator.moveNext() && inFirstHalfOfLap3()) {
      accumulator.add(iterator.current);
    }
    expect(accumulator.lapProgress!.lap, 3);
    await repository.write(accumulator.takeBatch());
    final lastSample = (await db.select(db.samples).get()).last;

    await SessionRepository(db).recoverInterrupted();

    final laps = await db.select(db.laps).get();
    expect([for (final l in laps) (l.lapNo, l.complete)], [(1, true), (2, true), (3, false)]);
    expect(laps.last.startDistanceDm, laps[1].endDistanceDm);
    expect((laps.last.endWallMs, laps.last.endDistanceDm), (lastSample.wallMs, lastSample.distanceDm));
    expect((await repository.get(id))!.status, SessionStatus.incomplete);
    final segments = await db.select(db.lapSegments).get();
    expect([for (final s in segments) s.lapNo], [1, 2, 3]);
  });
}
