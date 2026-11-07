import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/workouts/workout_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

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
    return db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            startedAt: DateTime(2026, 10, 16),
            status: SessionStatus.complete,
            source: ErgSourceKind.pm5,
            workoutId: Value(workoutId),
            workoutName: Value(workout.name),
            courseVersionId: Value(workout.course.versionId),
            plannedLaps: Value(workout.laps),
          ),
        );
  }

  test('stores workouts with a fixed and an open number of laps', () async {
    await workouts.create('Seerunde x3', courseId: seerunde, laps: 3);
    await workouts.create('Seerunde offen', courseId: seerunde, laps: null);

    final list = await workouts.all();

    expect(
      [for (final t in list) '${t.name} · ${t.course.name} · ${t.laps}'],
      ['Seerunde offen · Seerunde · null', 'Seerunde x3 · Seerunde · 3'],
    );
  });

  test('needs at least one lap', () {
    expect(
      () => workouts.create('Nichts', courseId: seerunde, laps: 0),
      throwsArgumentError,
    );
  });

  test('changing the laps leaves rowed sessions as they were', () async {
    final id = await workouts.create(
      'Seerunde x3',
      courseId: seerunde,
      laps: 3,
    );
    final session = await rowSession(id);

    await workouts.update(id, name: 'Seerunde x4', courseId: seerunde, laps: 4);

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
    final id = await workouts.create('Training', courseId: seerunde, laps: 3);

    await workouts.update(id, name: 'Training', courseId: sprint, laps: 3);

    expect((await workouts.get(id))!.course.name, 'Sprint');
  });

  test(
    'deleting a workout keeps its sessions with the name of the workout',
    () async {
      final id = await workouts.create(
        'Seerunde x3',
        courseId: seerunde,
        laps: 3,
      );
      final session = await rowSession(id);

      await workouts.delete(id);

      expect(await workouts.all(), isEmpty);
      final row = await (db.select(
        db.sessions,
      )..where((s) => s.id.equals(session))).getSingle();
      expect(row.workoutId, isNull);
      expect(row.workoutName, 'Seerunde x3');
      expect(row.courseVersionId, isNotNull);
    },
  );
}
