import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

final _seerunde = CourseDefinition.single(
  axis: CourseAxis.distance,
  length: 1000,
);

/// Stores a session rowed on [versionId], with one lap.
Future<int> _rowSession(AppDatabase db, int versionId) async {
  final id = await db
      .into(db.sessions)
      .insert(
        SessionsCompanion.insert(
          startedAt: DateTime(2026, 10, 16),
          status: SessionStatus.complete,
          source: ErgSourceKind.pm5,
          courseVersionId: Value(versionId),
        ),
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

Future<int> _template(AppDatabase db, String name, int courseId) async {
  final id = await db
      .into(db.templates)
      .insert(TemplatesCompanion.insert(name: name, createdAt: DateTime(2026)));
  await db
      .into(db.templateBlocks)
      .insert(
        TemplateBlocksCompanion.insert(
          templateId: id,
          position: 0,
          courseId: courseId,
        ),
      );
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

  test('deleting a course deletes the templates using it', () async {
    final id = await courses.create('Seerunde', _seerunde);
    final other = await courses.create(
      'Sprint',
      CourseDefinition.single(axis: CourseAxis.distance, length: 500),
    );
    await _template(db, 'Seerunde x3', id);
    await _template(db, 'Sprint x5', other);

    expect(await courses.templatesUsing(id), ['Seerunde x3']);
    await courses.delete(id);

    expect((await db.select(db.templates).get()).map((t) => t.name), [
      'Sprint x5',
    ]);
    expect(await db.select(db.templateBlocks).get(), hasLength(1));
  });

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
