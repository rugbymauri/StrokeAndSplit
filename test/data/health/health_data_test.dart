import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/health/health_workout.dart';
import 'package:strokesplit/data/sessions/session_accumulator.dart';
import 'package:strokesplit/data/sessions/session_plan.dart';
import 'package:strokesplit/data/sessions/session_repository.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/templates/template_repository.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late SessionRepository repository;
  final startedAt = DateTime.utc(2026, 11, 2, 18, 30);

  setUp(() {
    db = openTestDatabase();
    repository = SessionRepository(db);
  });
  tearDown(() => db.close());

  test(
    'reads the measurements on the wall clock, the laps and the pauses',
    () async {
      final id = await repository.create(
        startedAt: startedAt,
        source: ErgSourceKind.pm5,
      );
      SamplesCompanion sample(int tMs, int? wallMs, {int? heartRate}) =>
          SamplesCompanion.insert(
            sessionId: id,
            tMs: tMs,
            distanceDm: tMs ~/ 100,
            wallMs: Value(wallMs),
            heartRate: Value(heartRate),
            watts: const Value(150),
            paceCs: const Value(12500),
            calories: const Value(12),
          );
      await repository.write(
        SessionBatch(
          samples: [sample(1000, 1500, heartRate: 140), sample(2000, null)],
          strokes: const [],
          rawPackets: const [],
          laps: [
            LapsCompanion.insert(
              sessionId: id,
              lapNo: 1,
              startWallMs: 0,
              endWallMs: 2000,
              startDistanceDm: 0,
              endDistanceDm: 200,
              complete: true,
            ),
          ],
          pauses: [
            PausesCompanion.insert(
              sessionId: id,
              startWallMs: 1600,
              endWallMs: 1800,
            ),
          ],
        ),
      );
      await repository.finish(
        id,
        endedAt: startedAt.add(const Duration(seconds: 3)),
      );

      final data = (await repository.healthData(id))!;
      expect(data.startedAt.toUtc(), startedAt);
      expect(data.endedAt!.toUtc(), startedAt.add(const Duration(seconds: 3)));
      expect(data.templateName, isNull);
      // Without a wall clock the time of the rower.
      expect(
        [
          for (final p in data.points)
            (p.wallMs, p.heartRate, p.watts, p.paceCs, p.calories),
        ],
        [(1500, 140, 150, 12500, 12), (2000, null, 150, 12500, 12)],
      );
      expect(data.laps, [(startMs: 0, endMs: 2000, distanceDm: 200)]);
      expect(data.pauses, [(startWallMs: 1600, endWallMs: 1800)]);
    },
  );

  test('gives a recorded session with a pause as a workout', () async {
    final id = await repository.create(
      startedAt: startedAt,
      source: ErgSourceKind.pm5,
    );
    final accumulator = SessionAccumulator(id);
    loadFixture('pause').packets.forEach(accumulator.add);
    accumulator.finish();
    await repository.write(accumulator.takeBatch());
    await repository.finish(id);

    final workout = healthWorkoutOf(
      (await repository.healthData(id))!,
      freeTitle: 'Freies Rudern',
    );
    expect(workout.title, 'Freies Rudern');
    expect(workout.meters, greaterThan(0));
    expect(workout.power, isNotEmpty);
    expect(workout.speed, isNotEmpty);
    expect(
      workout.segments.where((s) => s.type == HealthSegmentType.pause),
      isNotEmpty,
    );
  });

  test('remembers when a session was written and forgets it again', () async {
    final id = await repository.create(
      startedAt: startedAt,
      source: ErgSourceKind.pm5,
    );
    expect((await repository.get(id))!.healthExportedAt, isNull);

    final at = DateTime.utc(2026, 11, 2, 19);
    await repository.markHealthExported(id, at);
    expect((await repository.get(id))!.healthExportedAt!.toUtc(), at);
    await repository.clearHealthExported(id);
    expect((await repository.get(id))!.healthExportedAt, isNull);
  });

  test('imports a written session as not written', () async {
    final id = await repository.create(
      startedAt: startedAt,
      source: ErgSourceKind.pm5,
    );
    final accumulator = SessionAccumulator(id);
    loadFixture('just_row').packets.forEach(accumulator.add);
    accumulator.finish();
    await repository.write(accumulator.takeBatch());
    await repository.finish(id);
    await repository.markHealthExported(id, DateTime.utc(2026, 11, 2, 19));

    final imported = await repository.import(await repository.export(id));
    expect((await repository.get(imported))!.healthExportedAt, isNull);
  });

  test('knows no session that is not stored', () async {
    expect(await repository.healthData(42), isNull);
  });

  test('titles a course rowed without a template by the course and a template by its name', () async {
    final courses = CourseRepository(db);
    final course = (await courses.get(
      await courses.create(
        'Seerunde',
        CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
      ),
    ))!;
    Future<String> title(SessionPlan plan) async {
      final id = await repository.create(
        startedAt: startedAt,
        source: ErgSourceKind.pm5,
        plan: plan,
      );
      await repository.finish(id);
      return healthWorkoutOf(
        (await repository.healthData(id))!,
        freeTitle: 'Freies Rudern',
      ).title;
    }

    expect(
      await title(
        SessionPlan(
          course: course,
          length: const TimeLimit(Duration(minutes: 30)),
        ),
      ),
      'Seerunde',
    );
    final templates = TemplateRepository(db);
    final x3 = (await templates.get(
      await templates.create('Seerunde x3', courseId: course.id, laps: 3),
    ))!;
    expect(await title(x3.toPlan()), 'Seerunde x3');
  });
}
