import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/statistics/ranking.dart';
import 'package:aergrow/data/statistics/ranking_repository.dart';
import 'package:aergrow/data/templates/template_repository.dart';
import 'package:aergrow/data/zones/zone.dart';
import 'package:aergrow/data/zones/zone_repository.dart';
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

  group('zone', () {
    const sprint = Zone(name: 'Sprint', axis: CourseAxis.distance, length: 100, paceFastCs: 9000, paceSlowCs: 10000);
    late ZoneRepository zones;
    late int sprintId;

    setUp(() async {
      zones = ZoneRepository(db);
      sprintId = await zones.create(sprint);
    });

    /// A course of free gaps of [gaps] metres with a sprint after each one.
    Future<int> courseWithSprints(String name, List<int> gaps, {int after = 0}) async {
      final placed = sprint.copyWith(id: sprintId).segment;
      final length = gaps.fold(0, (sum, gap) => sum + gap + sprint.length) + after;
      return courses.create(name, CourseDefinition(axis: CourseAxis.distance, length: length, segments: [
        for (final gap in gaps) ...[if (gap > 0) CourseSegment(length: gap), placed],
        if (after > 0) CourseSegment(length: after),
      ]));
    }

    test('ranks the sprints of all courses together', () async {
      final interval = await courseWithSprints('2 km Intervall', [900], after: 1000);
      final lake = await courseWithSprints('Seerunde', [450], after: 450);
      await storeRowedSession(db, courseVersionId: await versionOf(interval), laps: [
        const RowedLap([(220000, 900), (18900, 100), (250000, 1000)]),
      ]);
      await storeRowedSession(db, courseVersionId: await versionOf(lake), laps: [
        const RowedLap([(110000, 450), (18200, 100), (110000, 450)]),
      ]);

      final ranked = await rankings.zone(sprintId);

      expect(_values(ranked), ['100: 18, 18']);
      expect([for (final e in ranked.single.entries) (e.durationMs, e.paceCs)], [(18200, 9100), (18900, 9450)]);
    });

    test('counts every sprint of a session on its own', () async {
      final course = await courseWithSprints('Doppelsprint', [0, 400], after: 400);
      final lap = RowedLap([(18000 + 100, 100), (100000, 400), (18000 + 200, 100), (100000, 400)]);
      final id = await storeRowedSession(db, courseVersionId: await versionOf(course), laps: [lap, lap, lap]);

      final entries = (await rankings.zone(sprintId)).single.entries;

      expect(entries, hasLength(6));
      expect(entries.take(3).every((e) => e.sessionId == id), isTrue);
      expect([for (final e in entries) (e.lap, e.position)], [(1, 0), (2, 0), (3, 0), (1, 2), (2, 2), (3, 2)]);
    });

    test('starts and ends the second sprint of a lap after the segments before it', () async {
      final course = await courseWithSprints('Doppelsprint', [0, 400], after: 400);
      final lap = RowedLap([(18000, 101), (100000, 400), (19000, 100), (100000, 400)]);
      await storeRowedSession(db, courseVersionId: await versionOf(course), laps: [lap, lap]);

      final second = (await rankings.zone(sprintId))
          .single
          .entries
          .singleWhere((e) => e.lap == 2 && e.position == 2);

      // Lap 1 takes 237 s over 1001 m, then 118 s over 501 m to the sprint.
      expect(
        (second.startWallMs, second.endWallMs, second.startDistanceDm, second.endDistanceDm),
        (355000, 374000, 15020, 16020),
      );
    });

    test('has a ranking per length of the zone, the current length first', () async {
      final lake = await courseWithSprints('Seerunde', [450], after: 450);
      await storeRowedSession(db, courseVersionId: await versionOf(lake), laps: [
        const RowedLap([(110000, 450), (18200, 100), (110000, 450)]),
      ]);
      await zones.update(sprint.copyWith(id: sprintId, length: 150));
      await storeRowedSession(db, courseVersionId: await versionOf(lake), laps: [
        const RowedLap([(110000, 450), (28000, 150), (100000, 400)]),
      ]);

      expect(_values(await rankings.zone(sprintId)), ['150: 28', '100: 18']);
    });

    test('leaves out the sprints of a lap that was not finished', () async {
      final lake = await courseWithSprints('Seerunde', [450], after: 450);
      await storeRowedSession(db, courseVersionId: await versionOf(lake), laps: [
        const RowedLap([(110000, 450), (18200, 100), (110000, 450)]),
        const RowedLap([(110000, 450), (17000, 100), (50000, 200)], complete: false),
      ]);

      expect(_values(await rankings.zone(sprintId)), ['100: 18']);
    });
  });
}
