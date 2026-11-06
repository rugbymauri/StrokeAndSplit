import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/templates/template_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late TemplateRepository templates;
  late int seerunde;

  setUp(() async {
    db = openTestDatabase();
    templates = TemplateRepository(db);
    seerunde = await CourseRepository(db).create(
      'Seerunde',
      CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
    );
  });

  Future<int> rowSession(int templateId) async {
    final template = (await templates.get(templateId))!;
    return db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            startedAt: DateTime(2026, 10, 16),
            status: SessionStatus.complete,
            source: ErgSourceKind.pm5,
            templateId: Value(templateId),
            templateName: Value(template.name),
            courseVersionId: Value(template.course.versionId),
            plannedLaps: Value(template.laps),
          ),
        );
  }

  test('stores templates with a fixed and an open number of laps', () async {
    await templates.create('Seerunde x3', courseId: seerunde, laps: 3);
    await templates.create('Seerunde offen', courseId: seerunde, laps: null);

    final list = await templates.all();

    expect(
      [for (final t in list) '${t.name} · ${t.course.name} · ${t.laps}'],
      ['Seerunde offen · Seerunde · null', 'Seerunde x3 · Seerunde · 3'],
    );
  });

  test('needs at least one lap', () {
    expect(
      () => templates.create('Nichts', courseId: seerunde, laps: 0),
      throwsArgumentError,
    );
  });

  test('changing the laps leaves rowed sessions as they were', () async {
    final id = await templates.create(
      'Seerunde x3',
      courseId: seerunde,
      laps: 3,
    );
    final session = await rowSession(id);

    await templates.update(
      id,
      name: 'Seerunde x4',
      courseId: seerunde,
      laps: 4,
    );

    final template = (await templates.get(id))!;
    expect((template.name, template.laps), ('Seerunde x4', 4));
    final row = await (db.select(
      db.sessions,
    )..where((s) => s.id.equals(session))).getSingle();
    expect((row.templateName, row.plannedLaps), ('Seerunde x3', 3));
  });

  test('changes the course of a template', () async {
    final sprint = await CourseRepository(db).create(
      'Sprint',
      CourseDefinition.single(axis: CourseAxis.distance, length: 500),
    );
    final id = await templates.create('Training', courseId: seerunde, laps: 3);

    await templates.update(id, name: 'Training', courseId: sprint, laps: 3);

    expect((await templates.get(id))!.course.name, 'Sprint');
  });

  test(
    'deleting a template keeps its sessions with the name of the template',
    () async {
      final id = await templates.create(
        'Seerunde x3',
        courseId: seerunde,
        laps: 3,
      );
      final session = await rowSession(id);

      await templates.delete(id);

      expect(await templates.all(), isEmpty);
      final row = await (db.select(
        db.sessions,
      )..where((s) => s.id.equals(session))).getSingle();
      expect(row.templateId, isNull);
      expect(row.templateName, 'Seerunde x3');
      expect(row.courseVersionId, isNotNull);
    },
  );
}
