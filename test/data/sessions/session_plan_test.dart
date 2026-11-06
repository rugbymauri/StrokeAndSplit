import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/sessions/session_plan.dart';
import 'package:strokesplit/data/sessions/session_repository.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/templates/template_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  test(
    'a template is rowed with its laps, or open, and keeps its name',
    () async {
      final db = openTestDatabase();
      addTearDown(db.close);
      final course = await CourseRepository(db).create(
        'Seerunde',
        CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
      );
      final templates = TemplateRepository(db);
      final x3 = (await templates.get(
        await templates.create('Seerunde x3', courseId: course, laps: 3),
      ))!.toPlan();
      final open = (await templates.get(
        await templates.create('Seerunde offen', courseId: course, laps: null),
      ))!.toPlan();

      expect(
        (x3.length, x3.plannedLaps, x3.plannedDuration, x3.template?.name),
        (const LapCount(3), 3, null, 'Seerunde x3'),
      );
      expect(
        (open.length, open.plannedLaps, open.template?.name),
        (const OpenLength(), null, 'Seerunde offen'),
      );
    },
  );

  test(
    'a session with a time limit stores its planned duration and no template',
    () async {
      final db = openTestDatabase();
      addTearDown(db.close);
      final courses = CourseRepository(db);
      final course = (await courses.get(
        await courses.create(
          'Seerunde',
          CourseDefinition.single(axis: CourseAxis.distance, length: 2400),
        ),
      ))!;

      final id = await SessionRepository(db).create(
        startedAt: DateTime.utc(2026, 11, 6, 7),
        source: ErgSourceKind.pm5,
        plan: SessionPlan(
          course: course,
          length: const TimeLimit(Duration(minutes: 30)),
        ),
      );

      final session = await (db.select(
        db.sessions,
      )..where((s) => s.id.equals(id))).getSingle();
      expect((session.templateId, session.templateName), (null, null));
      expect(
        (
          session.courseVersionId,
          session.plannedLaps,
          session.plannedDurationMs,
        ),
        (course.versionId, null, 1800000),
      );
    },
  );
}
