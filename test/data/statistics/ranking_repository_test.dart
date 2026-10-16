import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/statistics/ranking.dart';
import 'package:aergrow/data/statistics/ranking_repository.dart';
import 'package:aergrow/data/templates/template_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/rowed_sessions.dart';
import '../../support/test_database.dart';

/// Per ranking its length and the values of its entries: seconds on a
/// distance axis, metres on a time axis.
List<String> _values(List<Ranking> rankings) => [
      for (final r in rankings)
        '${r.length}: ${[
          for (final e in r.entries) r.axis == CourseAxis.distance ? e.durationMs ~/ 1000 : e.distanceDm ~/ 10,
        ].join(', ')}',
    ];

void main() {
  late AppDatabase db;
  late CourseRepository courses;
  late TemplateRepository templates;
  late RankingRepository rankings;
  late int seerunde;

  setUp(() async {
    db = openTestDatabase();
    courses = CourseRepository(db);
    templates = TemplateRepository(db);
    rankings = RankingRepository(db);
    seerunde = await courses.create('Seerunde', CourseDefinition.single(axis: CourseAxis.distance, length: 1000));
  });

  Future<int> versionOf(int courseId) async => (await courses.get(courseId))!.versionId;

  group('course', () {
    test('ranks the laps of all templates on the course together', () async {
      final x3 = (await templates.get(await templates.create('Seerunde x3', courseId: seerunde, laps: 3)))!;
      final open = (await templates.get(await templates.create('Seerunde offen', courseId: seerunde, laps: null)))!;
      await storeRowedSession(db, template: x3, laps: [
        RowedLap.single(250000, 1000),
        RowedLap.single(248000, 1000),
        RowedLap.single(252000, 1000),
      ]);
      await storeRowedSession(db, template: open, laps: [RowedLap.single(249000, 1000)]);

      final ranked = await rankings.course(seerunde);

      expect(_values(ranked), ['1000: 248, 249, 250, 252']);
      expect([for (final e in ranked.single.entries) e.lap], [2, 1, 1, 3]);
    });

    test('has a ranking per length, the current length first', () async {
      await storeRowedSession(db, courseVersionId: await versionOf(seerunde), laps: [RowedLap.single(250000, 1000)]);
      await courses.updateDefinition(seerunde, CourseDefinition.single(axis: CourseAxis.distance, length: 1200));
      await storeRowedSession(db, courseVersionId: await versionOf(seerunde), laps: [RowedLap.single(300000, 1200)]);

      expect(_values(await rankings.course(seerunde)), [
        '1200: 300',
        '1000: 250',
      ]);
    });

    test('ranks versions of the same length together when only the zones changed', () async {
      final first = await versionOf(seerunde);
      await storeRowedSession(db, courseVersionId: first, laps: [RowedLap.single(250000, 1000)]);
      await courses.updateDefinition(
        seerunde,
        const CourseDefinition(axis: CourseAxis.distance, length: 1000, segments: [
          CourseSegment(length: 500),
          CourseSegment(length: 500, paceFastCs: 10000, paceSlowCs: 12000),
        ]),
      );
      final changed = await versionOf(seerunde);
      expect(changed, isNot(first));
      await storeRowedSession(db, courseVersionId: changed, laps: [
        const RowedLap([(120000, 500), (126000, 500)]),
      ]);

      final ranked = await rankings.course(seerunde);

      expect(_values(ranked), ['1000: 246, 250']);
    });

    test('leaves out a lap that was not finished', () async {
      await storeRowedSession(db, courseVersionId: await versionOf(seerunde), laps: [
        RowedLap.single(250000, 1000),
        RowedLap.single(100000, 400, complete: false),
      ]);

      expect(_values(await rankings.course(seerunde)), ['1000: 250']);
    });

    test('keeps start and end of a lap for the ghost', () async {
      final id = await storeRowedSession(db, courseVersionId: await versionOf(seerunde), laps: [
        RowedLap.single(250000, 1000),
        RowedLap.single(248000, 1001),
      ]);

      final best = (await rankings.course(seerunde)).single.entries.first;

      expect(
        (best.sessionId, best.lap, best.startWallMs, best.endWallMs, best.startDistanceDm, best.endDistanceDm),
        (id, 2, 250000, 498000, 10000, 20010),
      );
    });

    test('has no ranking before the course was rowed', () async {
      expect(await rankings.course(seerunde), isEmpty);
    });
  });
}
