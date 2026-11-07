import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';
import '../../support/session_rows.dart';

final _seerunde = CourseDefinition.single(
  axis: CourseAxis.distance,
  length: 1000,
);

/// Stores a session rowed on [versionId], with one lap.
Future<int> _rowSession(AppDatabase db, int versionId) async {
  final id = await insertSession(
    db,
    SessionsCompanion.insert(
      startedAt: DateTime(2026, 10, 16),
      status: SessionStatus.complete,
      source: ErgSourceKind.pm5,
    ),
    courseVersionIds: [versionId],
  );
  await db
      .into(db.laps)
      .insert(
        LapsCompanion.insert(
          sessionId: id,
          lapNo: 1,
          startWallMs: 0,
          endWallMs: 240000,
          startDistanceDm: 0,
          endDistanceDm: 10000,
          complete: true,
        ),
      );
  return id;
}

/// Stores the workout [name] rowing [courseIds] in this order.
Future<int> _workout(AppDatabase db, String name, List<int> courseIds) async {
  final id = await db
      .into(db.workouts)
      .insert(WorkoutsCompanion.insert(name: name, createdAt: DateTime(2026)));
  for (final (position, courseId) in courseIds.indexed) {
    await db
        .into(db.workoutBlocks)
        .insert(
          WorkoutBlocksCompanion.insert(
            workoutId: id,
            position: position,
            courseId: courseId,
          ),
        );
  }
  return id;
}

void main() {
  late AppDatabase db;
  late CourseRepository courses;

  setUp(() {
    db = openTestDatabase();
    courses = CourseRepository(db);
  });

  test('stores distance and time courses and lists them by name', () async {
    await courses.create(
      'Vier Minuten',
      CourseDefinition.single(axis: CourseAxis.time, length: 240),
    );
    await courses.create('Seerunde', _seerunde);

    final list = await courses.all();

    expect(
      [
        for (final c in list)
          (c.name, formatCourseLength(c.axis, c.definition.length)),
      ],
      [('Seerunde', '1000 m'), ('Vier Minuten', '4:00')],
    );
    expect(list.first.version, 1);
  });

  test('stores segments with their bands', () async {
    const definition = CourseDefinition(
      axis: CourseAxis.distance,
      length: 1000,
      segments: [
        CourseSegment(length: 200),
        CourseSegment(
          length: 600,
          paceFastCs: 12500,
          paceSlowCs: 13000,
          spmMin: 20,
          spmMax: 22,
        ),
        CourseSegment(length: 200),
      ],
    );
    final id = await courses.create('Seerunde', definition);

    expect((await courses.get(id))!.definition, definition);
  });

  test('renames a course', () async {
    final id = await courses.create('Seerunde', _seerunde);

    await courses.rename(id, 'Seerunde lang');

    expect((await courses.all()).single.name, 'Seerunde lang');
  });

  test('changes a course that was never rowed in place', () async {
    final id = await courses.create('Seerunde', _seerunde);
    final before = (await courses.get(id))!;

    await courses.updateDefinition(
      id,
      CourseDefinition.single(axis: CourseAxis.distance, length: 1200),
    );

    final after = (await courses.get(id))!;
    expect(after.definition.length, 1200);
    expect(after.versionId, before.versionId);
    expect(after.version, 1);
  });

  test('keeps a rowed version and stores the change as a new one', () async {
    final id = await courses.create('Seerunde', _seerunde);
    final rowed = (await courses.get(id))!;
    await _rowSession(db, rowed.versionId);

    await courses.updateDefinition(
      id,
      CourseDefinition.single(axis: CourseAxis.distance, length: 1200),
    );

    final newest = (await courses.get(id))!;
    expect(newest.version, 2);
    expect(newest.definition.length, 1200);
    expect((await courses.atVersion(rowed.versionId)).definition.length, 1000);
    expect((await courses.all()).single.version, 2);
  });

  test('renaming a rowed course makes no new version and also renames old sessions', () async {
    final id = await courses.create('Seerunde', _seerunde);
    final rowed = (await courses.get(id))!;
    await _rowSession(db, rowed.versionId);

    await courses.rename(id, 'Seerunde lang');
    await courses.updateDefinition(id, _seerunde);

    expect((await courses.get(id))!.version, 1);
    expect((await courses.atVersion(rowed.versionId)).name, 'Seerunde lang');
  });

  test('does not change the axis of a course', () async {
    final id = await courses.create('Seerunde', _seerunde);

    expect(
      () => courses.updateDefinition(
        id,
        CourseDefinition.single(axis: CourseAxis.time, length: 240),
      ),
      throwsArgumentError,
    );
  });

  test('deleting a rowed course keeps its sessions and laps', () async {
    final id = await courses.create('Seerunde', _seerunde);
    final rowed = (await courses.get(id))!;
    final session = await _rowSession(db, rowed.versionId);

    await courses.delete(id);

    expect(await courses.all(), isEmpty);
    expect((await courses.atVersion(rowed.versionId)).name, 'Seerunde');
    final laps = await (db.select(
      db.laps,
    )..where((l) => l.sessionId.equals(session))).get();
    expect(laps.single.endWallMs, 240000);
  });

  test(
    'Strecke eines Workouts löschen: deletes the workouts rowing only it',
    () async {
      final id = await courses.create('Seerunde', _seerunde);
      final other = await courses.create(
        'Sprint',
        CourseDefinition.single(axis: CourseAxis.distance, length: 500),
      );
      await _workout(db, 'Seerunde x3', [id]);
      await _workout(db, 'Sprint x5', [other]);

      expect(await courses.workoutsLeftEmpty(id), ['Seerunde x3']);
      await courses.delete(id);

      expect((await db.select(db.workouts).get()).map((t) => t.name), [
        'Sprint x5',
      ]);
      expect(await db.select(db.workoutBlocks).get(), hasLength(1));
    },
  );

  test(
    'Strecke aus einer Kette löschen: keeps the workout with the other courses',
    () async {
      final einrudern = await courses.create(
        'Einrudern',
        CourseDefinition.single(axis: CourseAxis.distance, length: 500),
      );
      final intervall = await courses.create(
        '2 km Intervall',
        CourseDefinition.single(axis: CourseAxis.distance, length: 2000),
      );
      final ausrudern = await courses.create(
        'Ausrudern',
        CourseDefinition.single(axis: CourseAxis.distance, length: 500),
      );
      final training = await _workout(db, 'Intervalltraining', [
        einrudern,
        ausrudern,
        intervall,
        ausrudern,
      ]);
      await _workout(db, 'Nur Ausrudern', [ausrudern, ausrudern]);

      expect(await courses.workoutsLeftEmpty(ausrudern), ['Nur Ausrudern']);
      await courses.delete(ausrudern);

      final blocks = await db.select(db.workoutBlocks).get();
      expect(
        [for (final b in blocks) (b.workoutId, b.position, b.courseId)],
        [(training, 0, einrudern), (training, 1, intervall)],
      );
      expect((await db.select(db.workouts).get()).map((t) => t.name), [
        'Intervalltraining',
      ]);
    },
  );

  test('tells the list about changes', () async {
    final updates = courses.watchAll().map(
      (list) => list.map((c) => c.name).toList(),
    );
    final expectation = expectLater(
      updates,
      emitsInOrder([
        <String>[],
        ['Seerunde'],
      ]),
    );

    await Future<void>.delayed(Duration.zero);
    await courses.create('Seerunde', _seerunde);
    await expectation;
  });

  test(
    'counts how often a course was rowed, in all versions and in the newest',
    () async {
      final id = await courses.create('Seerunde', _seerunde);
      await courses.create(
        'Vier Minuten',
        CourseDefinition.single(axis: CourseAxis.time, length: 240),
      );
      final first = (await courses.get(id))!.versionId;
      await _rowSession(db, first);
      await _rowSession(db, first);
      expect(await courses.rowCounts(), {id: (total: 2, newest: 2)});

      await courses.updateDefinition(
        id,
        CourseDefinition.single(axis: CourseAxis.distance, length: 1200),
      );
      expect(await courses.rowCounts(), {id: (total: 2, newest: 0)});

      await _rowSession(db, (await courses.get(id))!.versionId);
      expect(await courses.rowCounts(), {id: (total: 3, newest: 1)});
    },
  );
}
