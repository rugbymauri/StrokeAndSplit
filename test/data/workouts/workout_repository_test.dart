import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sessions/session_plan.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/workouts/workout_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../support/session_rows.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository workouts;
  late int seerunde;

  setUp(() async {
    db = openTestDatabase();
    workouts = WorkoutRepository(db);
    seerunde = await CourseRepository(db).create(
      'Seerunde',
      CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
    );
  });

  Future<int> rowSession(int workoutId) async {
    final workout = (await workouts.get(workoutId))!;
    return insertSession(
      db,
      SessionsCompanion.insert(
        startedAt: DateTime(2026, 10, 16),
        status: SessionStatus.complete,
        source: ErgSourceKind.pm5,
        workoutId: Value(workoutId),
        workoutName: Value(workout.name),
        plannedLaps: Value(workout.laps),
      ),
      courseVersionIds: [workout.chain.versionId],
    );
  }

  test('stores workouts with a fixed and an open number of laps', () async {
    await workouts.create(
      'Seerunde x3',
      courseIds: [seerunde],
      length: const LapCount(3),
    );
    await workouts.create(
      'Seerunde offen',
      courseIds: [seerunde],
      length: const OpenLength(),
    );

    final list = await workouts.all();

    expect(
      [for (final t in list) '${t.name} · ${t.chain.name} · ${t.laps}'],
      ['Seerunde offen · Seerunde · null', 'Seerunde x3 · Seerunde · 3'],
    );
  });

  test('needs at least one lap', () {
    expect(
      () => workouts.create(
        'Nichts',
        courseIds: [seerunde],
        length: const LapCount(0),
      ),
      throwsArgumentError,
    );
  });

  test('changing the laps leaves rowed sessions as they were', () async {
    final id = await workouts.create(
      'Seerunde x3',
      courseIds: [seerunde],
      length: const LapCount(3),
    );
    final session = await rowSession(id);

    await workouts.update(
      id,
      name: 'Seerunde x4',
      courseIds: [seerunde],
      length: const LapCount(4),
    );

    final workout = (await workouts.get(id))!;
    expect((workout.name, workout.laps), ('Seerunde x4', 4));
    final row = await (db.select(
      db.sessions,
    )..where((s) => s.id.equals(session))).getSingle();
    expect((row.workoutName, row.plannedLaps), ('Seerunde x3', 3));
  });

  test('changes the course of a workout', () async {
    final sprint = await CourseRepository(db).create(
      'Sprint',
      CourseDefinition.single(axis: CourseAxis.distance, length: 500),
    );
    final id = await workouts.create(
      'Training',
      courseIds: [seerunde],
      length: const LapCount(3),
    );

    await workouts.update(
      id,
      name: 'Training',
      courseIds: [sprint],
      length: const LapCount(3),
    );

    expect((await workouts.get(id))!.chain.name, 'Sprint');
  });

  test(
    'deleting a workout keeps its sessions with the name of the workout',
    () async {
      final id = await workouts.create(
        'Seerunde x3',
        courseIds: [seerunde],
        length: const LapCount(3),
      );
      final session = await rowSession(id);

      await workouts.delete(id);

      expect(await workouts.all(), isEmpty);
      final row = await (db.select(
        db.sessions,
      )..where((s) => s.id.equals(session))).getSingle();
      expect(row.workoutId, isNull);
      expect(row.workoutName, 'Seerunde x3');
      expect(await sessionVersionIds(db, session), hasLength(1));
    },
  );

  group('a workout with several courses', () {
    late int einrudern;
    late int intervall;
    late int ausrudern;

    setUp(() async {
      final courses = CourseRepository(db);
      einrudern = await courses.create(
        'Einrudern',
        CourseDefinition.single(axis: CourseAxis.distance, length: 500),
      );
      intervall = await courses.create(
        '2 km Intervall',
        CourseDefinition.single(axis: CourseAxis.distance, length: 2000),
      );
      ausrudern = await courses.create(
        'Ausrudern',
        CourseDefinition.single(axis: CourseAxis.distance, length: 500),
      );
    });

    Future<List<String>> names(int id) async => [
      for (final c in (await workouts.get(id))!.courses) c.name,
    ];

    test('stores its courses in order with one length for all', () async {
      final id = await workouts.create(
        'Intervalltraining',
        courseIds: [einrudern, intervall, ausrudern],
        length: const LapCount(1),
      );

      final workout = (await workouts.get(id))!;
      expect(await names(id), ['Einrudern', '2 km Intervall', 'Ausrudern']);
      expect(
        (workout.chain.name, workout.lapLength, workout.laps),
        ('Einrudern + 2 km Intervall + Ausrudern', 3000, 1),
      );
    });

    test('appends, moves and removes courses and sets a duration', () async {
      final id = await workouts.create(
        'Intervalltraining',
        courseIds: [einrudern, intervall],
        length: const LapCount(1),
      );

      await workouts.update(
        id,
        name: 'Intervalltraining',
        courseIds: [einrudern, intervall, ausrudern],
        length: const LapCount(1),
      );
      expect(await names(id), ['Einrudern', '2 km Intervall', 'Ausrudern']);

      await workouts.update(
        id,
        name: 'Intervalltraining',
        courseIds: [intervall, einrudern, ausrudern],
        length: const LapCount(1),
      );
      expect(await names(id), ['2 km Intervall', 'Einrudern', 'Ausrudern']);

      await workouts.update(
        id,
        name: 'Intervalltraining',
        courseIds: [intervall, ausrudern],
        length: const TimeLimit(Duration(minutes: 45)),
      );
      final workout = (await workouts.get(id))!;
      expect(await names(id), ['2 km Intervall', 'Ausrudern']);
      expect(workout.length, const TimeLimit(Duration(minutes: 45)));
      expect(workout.laps, isNull);
      final blocks = await db.select(db.workoutBlocks).get();
      expect([for (final b in blocks) b.position], [0, 1]);
    });

    test('mixes no axes', () async {
      final vierMinuten = await CourseRepository(db).create(
        'Vier Minuten',
        CourseDefinition.single(axis: CourseAxis.time, length: 240),
      );

      expect(
        () => workouts.create(
          'Gemischt',
          courseIds: [einrudern, vierMinuten],
          length: const LapCount(1),
        ),
        throwsArgumentError,
      );
    });

    test('deleting it removes all its courses from it', () async {
      final id = await workouts.create(
        'Intervalltraining',
        courseIds: [einrudern, intervall, ausrudern],
        length: const LapCount(1),
      );

      await workouts.delete(id);

      expect(await workouts.all(), isEmpty);
      expect(await db.select(db.workoutBlocks).get(), isEmpty);
      expect(await CourseRepository(db).all(), hasLength(4));
    });
  });
}
