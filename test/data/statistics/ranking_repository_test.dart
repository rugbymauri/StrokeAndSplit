import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/courses/course_layout.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sessions/session_accumulator.dart';
import 'package:strokesplit/data/sessions/session_repository.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/statistics/ranking.dart';
import 'package:strokesplit/data/statistics/ranking_repository.dart';
import 'package:strokesplit/data/templates/template_repository.dart';
import 'package:strokesplit/data/zones/zone.dart';
import 'package:strokesplit/data/zones/zone_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/rowed_sessions.dart';
import '../../support/test_database.dart';

/// Per ranking its length and the values of its entries: seconds on a
/// distance axis, metres on a time axis.
List<String> _values(List<Ranking> rankings) => [
  for (final r in rankings)
    '${r.length}: ${[for (final e in r.entries) r.axis == CourseAxis.distance ? e.durationMs ~/ 1000 : e.distanceDm ~/ 10].join(', ')}',
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
    seerunde = await courses.create(
      'Seerunde',
      CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
    );
  });

  Future<int> versionOf(int courseId) async =>
      (await courses.get(courseId))!.versionId;

  group('course', () {
    test('ranks the laps of all templates on the course together', () async {
      final x3 = (await templates.get(
        await templates.create('Seerunde x3', courseId: seerunde, laps: 3),
      ))!;
      final open = (await templates.get(
        await templates.create(
          'Seerunde offen',
          courseId: seerunde,
          laps: null,
        ),
      ))!;
      await storeRowedSession(
        db,
        template: x3,
        laps: [
          RowedLap.single(250000, 1000),
          RowedLap.single(248000, 1000),
          RowedLap.single(252000, 1000),
        ],
      );
      await storeRowedSession(
        db,
        template: open,
        laps: [RowedLap.single(249000, 1000)],
      );

      final ranked = await rankings.course(seerunde);

      expect(_values(ranked), ['1000: 248, 249, 250, 252']);
      expect([for (final e in ranked.single.entries) e.lap], [2, 1, 1, 3]);
    });

    test('has a ranking per length, the current length first', () async {
      await storeRowedSession(
        db,
        courseVersionId: await versionOf(seerunde),
        laps: [RowedLap.single(250000, 1000)],
      );
      await courses.updateDefinition(
        seerunde,
        CourseDefinition.single(axis: CourseAxis.distance, length: 1200),
      );
      await storeRowedSession(
        db,
        courseVersionId: await versionOf(seerunde),
        laps: [RowedLap.single(300000, 1200)],
      );

      expect(_values(await rankings.course(seerunde)), [
        '1200: 300',
        '1000: 250',
      ]);
    });

    test(
      'ranks versions of the same length together when only the zones changed',
      () async {
        final first = await versionOf(seerunde);
        await storeRowedSession(
          db,
          courseVersionId: first,
          laps: [RowedLap.single(250000, 1000)],
        );
        await courses.updateDefinition(
          seerunde,
          const CourseDefinition(
            axis: CourseAxis.distance,
            length: 1000,
            segments: [
              CourseSegment(length: 500),
              CourseSegment(length: 500, paceFastCs: 10000, paceSlowCs: 12000),
            ],
          ),
        );
        final changed = await versionOf(seerunde);
        expect(changed, isNot(first));
        await storeRowedSession(
          db,
          courseVersionId: changed,
          laps: [
            const RowedLap([(120000, 500), (126000, 500)]),
          ],
        );

        final ranked = await rankings.course(seerunde);

        expect(_values(ranked), ['1000: 246, 250']);
      },
    );

    test('leaves out a lap that was not finished', () async {
      await storeRowedSession(
        db,
        courseVersionId: await versionOf(seerunde),
        laps: [
          RowedLap.single(250000, 1000),
          RowedLap.single(100000, 400, complete: false),
        ],
      );

      expect(_values(await rankings.course(seerunde)), ['1000: 250']);
    });

    test('keeps start and end of a lap for the ghost', () async {
      final id = await storeRowedSession(
        db,
        courseVersionId: await versionOf(seerunde),
        laps: [RowedLap.single(250000, 1000), RowedLap.single(248000, 1001)],
      );

      final best = (await rankings.course(seerunde)).single.entries.first;

      expect(
        (
          best.sessionId,
          best.lap,
          best.startWallMs,
          best.endWallMs,
          best.startDistanceDm,
          best.endDistanceDm,
        ),
        (id, 2, 250000, 498000, 10000, 20010),
      );
    });

    test('has no ranking before the course was rowed', () async {
      expect(await rankings.course(seerunde), isEmpty);
    });
  });

  group('zone', () {
    const sprint = Zone(
      name: 'Sprint',
      axis: CourseAxis.distance,
      length: 100,
      paceFastCs: 9000,
      paceSlowCs: 10000,
    );
    late ZoneRepository zones;
    late int sprintId;

    setUp(() async {
      zones = ZoneRepository(db);
      sprintId = await zones.create(sprint);
    });

    /// A course of free gaps of [gaps] metres with a sprint after each one.
    Future<int> courseWithSprints(
      String name,
      List<int> gaps, {
      int after = 0,
    }) async {
      final placed = sprint.copyWith(id: sprintId).segment;
      final length =
          gaps.fold(0, (sum, gap) => sum + gap + sprint.length) + after;
      return courses.create(
        name,
        CourseDefinition(
          axis: CourseAxis.distance,
          length: length,
          segments: [
            for (final gap in gaps) ...[
              if (gap > 0) CourseSegment(length: gap),
              placed,
            ],
            if (after > 0) CourseSegment(length: after),
          ],
        ),
      );
    }

    test('ranks the sprints of all courses together', () async {
      final interval = await courseWithSprints('2 km Intervall', [
        900,
      ], after: 1000);
      final lake = await courseWithSprints('Seerunde', [450], after: 450);
      await storeRowedSession(
        db,
        courseVersionId: await versionOf(interval),
        laps: [
          const RowedLap([(220000, 900), (18900, 100), (250000, 1000)]),
        ],
      );
      await storeRowedSession(
        db,
        courseVersionId: await versionOf(lake),
        laps: [
          const RowedLap([(110000, 450), (18200, 100), (110000, 450)]),
        ],
      );

      final ranked = await rankings.zone(sprintId);

      expect(_values(ranked), ['100: 18, 18']);
      expect(
        [for (final e in ranked.single.entries) (e.durationMs, e.paceCs)],
        [(18200, 9100), (18900, 9450)],
      );
    });

    test('counts every sprint of a session on its own', () async {
      final course = await courseWithSprints('Doppelsprint', [
        0,
        400,
      ], after: 400);
      final lap = RowedLap([
        (18000 + 100, 100),
        (100000, 400),
        (18000 + 200, 100),
        (100000, 400),
      ]);
      final id = await storeRowedSession(
        db,
        courseVersionId: await versionOf(course),
        laps: [lap, lap, lap],
      );

      final entries = (await rankings.zone(sprintId)).single.entries;

      expect(entries, hasLength(6));
      expect(entries.take(3).every((e) => e.sessionId == id), isTrue);
      expect(
        [for (final e in entries) (e.lap, e.position)],
        [(1, 0), (2, 0), (3, 0), (1, 2), (2, 2), (3, 2)],
      );
    });

    test(
      'starts and ends the second sprint of a lap after the segments before it',
      () async {
        final course = await courseWithSprints('Doppelsprint', [
          0,
          400,
        ], after: 400);
        final lap = RowedLap([
          (18000, 101),
          (100000, 400),
          (19000, 100),
          (100000, 400),
        ]);
        await storeRowedSession(
          db,
          courseVersionId: await versionOf(course),
          laps: [lap, lap],
        );

        final second = (await rankings.zone(sprintId)).single.entries
            .singleWhere((e) => e.lap == 2 && e.position == 2);

        // Lap 1 takes 237 s over 1001 m, then 118 s over 501 m to the sprint.
        expect(
          (
            second.startWallMs,
            second.endWallMs,
            second.startDistanceDm,
            second.endDistanceDm,
          ),
          (355000, 374000, 15020, 16020),
        );
      },
    );

    test(
      'has a ranking per length of the zone, the current length first',
      () async {
        final lake = await courseWithSprints('Seerunde', [450], after: 450);
        await storeRowedSession(
          db,
          courseVersionId: await versionOf(lake),
          laps: [
            const RowedLap([(110000, 450), (18200, 100), (110000, 450)]),
          ],
        );
        await zones.update(sprint.copyWith(id: sprintId, length: 150));
        await storeRowedSession(
          db,
          courseVersionId: await versionOf(lake),
          laps: [
            const RowedLap([(110000, 450), (28000, 150), (100000, 400)]),
          ],
        );

        expect(_values(await rankings.zone(sprintId)), ['150: 28', '100: 18']);
      },
    );

    test('leaves out the sprints of a lap that was not finished', () async {
      final lake = await courseWithSprints('Seerunde', [450], after: 450);
      await storeRowedSession(
        db,
        courseVersionId: await versionOf(lake),
        laps: [
          const RowedLap([(110000, 450), (18200, 100), (110000, 450)]),
          const RowedLap([
            (110000, 450),
            (17000, 100),
            (50000, 200),
          ], complete: false),
        ],
      );

      expect(_values(await rankings.zone(sprintId)), ['100: 18']);
    });
  });

  group('template', () {
    late int x3;

    setUp(
      () async => x3 = await templates.create(
        'Seerunde x3',
        courseId: seerunde,
        laps: 3,
      ),
    );

    /// Rows [template] with laps of [lapMs] each over 1000 m.
    Future<int> row(
      int template,
      List<int> lapMs, {
      bool lastComplete = true,
    }) async => storeRowedSession(
      db,
      template: (await templates.get(template))!,
      laps: [
        for (final (i, ms) in lapMs.indexed)
          RowedLap.single(
            ms,
            1000,
            complete: lastComplete || i < lapMs.length - 1,
          ),
      ],
    );

    test('ranks sessions with all laps by their sum', () async {
      await row(x3, [250000, 251000, 250800]);
      final best = await row(x3, [248000, 248100, 248000]);

      final ranked = await rankings.template(x3);

      expect(_values(ranked), ['1000: 744, 751']);
      final first = ranked.single.entries.first;
      expect(
        (first.sessionId, first.lap, first.durationMs, first.distanceDm),
        (best, null, 744100, 30000),
      );
      expect(
        (
          first.startWallMs,
          first.endWallMs,
          first.startDistanceDm,
          first.endDistanceDm,
        ),
        (0, 744100, 0, 30000),
      );
      expect(ranked.single.laps, 3);
    });

    test('leaves out a session that ended before its last lap', () async {
      await row(x3, [250000, 251000]);
      await row(x3, [250000, 251000, 100000], lastComplete: false);

      expect(await rankings.template(x3), isEmpty);
    });

    test('has a ranking per number of laps, the current one first', () async {
      await row(x3, [250000, 251000, 250800]);
      await templates.update(
        x3,
        name: 'Seerunde x3',
        courseId: seerunde,
        laps: 4,
      );
      await row(x3, [250000, 251000, 250800, 252000]);

      final ranked = await rankings.template(x3);

      expect(
        [for (final r in ranked) (r.length, r.laps, r.entries.length)],
        [(1000, 4, 1), (1000, 3, 1)],
      );
    });

    test('has no ranking for an open number of laps, its laps count for the course', () async {
      final open = await templates.create(
        'Seerunde offen',
        courseId: seerunde,
        laps: null,
      );
      await row(open, [250000, 251000]);

      expect(await rankings.template(open), isEmpty);
      expect(_values(await rankings.course(seerunde)), ['1000: 250, 251']);
    });
  });

  group('what counts', () {
    const sprint = Zone(
      name: 'Sprint',
      axis: CourseAxis.distance,
      length: 100,
      paceFastCs: 9000,
      paceSlowCs: 10000,
    );
    late ZoneRepository zones;
    late int sprintId;
    late int lake;
    late int x3;

    /// A lap of the lake with the sprint in [sprintMs].
    RowedLap lap(int sprintMs) =>
        RowedLap([(110000, 450), (sprintMs, 100), (110000, 450)]);

    Future<int> row(
      List<int> sprintMs, {
      ErgSourceKind source = ErgSourceKind.pm5,
    }) async => storeRowedSession(
      db,
      template: (await templates.get(x3))!,
      source: source,
      laps: [for (final ms in sprintMs) lap(ms)],
    );

    setUp(() async {
      zones = ZoneRepository(db);
      sprintId = await zones.create(sprint);
      lake = await courses.create(
        'Seerunde mit Sprint',
        CourseDefinition(
          axis: CourseAxis.distance,
          length: 1000,
          segments: [
            const CourseSegment(length: 450),
            sprint.copyWith(id: sprintId).segment,
            const CourseSegment(length: 450),
          ],
        ),
      );
      x3 = await templates.create('Seerunde x3', courseId: lake, laps: 3);
    });

    test('counts no session of the simulator or a replay', () async {
      await row([18000, 18000, 18000], source: ErgSourceKind.simulator);
      await row([18000, 18000, 18000], source: ErgSourceKind.replay);

      expect(await rankings.course(lake), isEmpty);
      expect(await rankings.zone(sprintId), isEmpty);
      expect(await rankings.template(x3), isEmpty);
    });

    test('counts sessions of FTMS rowers', () async {
      await row([18000, 18000, 18000], source: ErgSourceKind.ftms);

      expect(_values(await rankings.template(x3)), ['1000: 714']);
    });

    test(
      'has no ranking of a deleted zone, and the sessions keep their sprints',
      () async {
        final id = await row([18000, 18000, 18000]);

        await zones.delete(sprintId);

        expect(await rankings.zone(sprintId), isEmpty);
        final rowed = await CourseRepository(db)
            .atVersion((await SessionRepository(db).get(id))!.courseVersionId!);
        expect(rowed.definition.segments[1].zoneName, 'Sprint');
        expect(
          await (db.select(
            db.lapSegments,
          )..where((s) => s.sessionId.equals(id))).get(),
          hasLength(9),
        );
      },
    );

    test('counts the laps of a deleted template for its course', () async {
      await row([18000, 18000, 18000]);

      await templates.delete(x3);

      expect(await rankings.template(x3), isEmpty);
      expect(_values(await rankings.course(lake)), ['1000: 238, 238, 238']);
    });

    test('has no ranking of a deleted course', () async {
      await row([18000, 18000, 18000]);

      await courses.delete(lake);

      expect(await rankings.course(lake), isEmpty);
    });

    test('moves the others up when a session is deleted', () async {
      final best = await row([17000, 18000, 19000]);
      await row([17500, 18500, 19500]);

      await SessionRepository(db).delete(best);

      expect(
        [
          for (final e in (await rankings.zone(sprintId)).single.entries)
            e.durationMs,
        ],
        [17500, 18500, 19500],
      );
      expect(await rankings.template(x3), hasLength(1));
      expect((await rankings.course(lake)).single.entries, hasLength(3));
    });

    test(
      'leaves a PM5 session imported on another device out of all rankings',
      () async {
        // just_row as "Seerunde x3" on the phone, on a 40 m course with "Tempo" from 20 to 40 m.
        const tempo = Zone(
          name: 'Tempo',
          axis: CourseAxis.distance,
          length: 20,
          paceFastCs: 10000,
          paceSlowCs: 20000,
        );
        final phone = openTestDatabase();
        final tempoId = await ZoneRepository(phone).create(tempo);
        final definition = resolveCourse(
          axis: CourseAxis.distance,
          length: 40,
          placements: [ZonePlacement(zoneId: tempoId, start: 20)],
          zones: {tempoId: tempo.copyWith(id: tempoId)},
        ).definition!;
        final courseId = await CourseRepository(phone)
            .create('Seerunde', definition);
        final phoneTemplates = TemplateRepository(phone);
        final templateId = await phoneTemplates.create(
          'Seerunde x3',
          courseId: courseId,
          laps: 3,
        );
        final template = (await phoneTemplates.get(templateId))!;
        final sessions = SessionRepository(phone);
        final recorded = await sessions.create(
          startedAt: DateTime.utc(2026, 10, 16, 7),
          source: ErgSourceKind.pm5,
          template: template,
        );
        final accumulator = SessionAccumulator(
          recorded,
          course: definition,
          plannedLaps: 3,
        );
        loadFixture('just_row').packets.forEach(accumulator.add);
        accumulator.finish();
        await sessions.write(accumulator.takeBatch());
        await sessions.finish(recorded);

        final laptop = openTestDatabase();
        final imported = await SessionRepository(laptop)
            .import(await sessions.export(recorded));

        final course = (await CourseRepository(laptop).all()).single;
        final zone = (await ZoneRepository(laptop).all()).single;
        // The import links no template; linked by hand, the session still must not count.
        final laptopTemplate = await TemplateRepository(laptop)
            .create('Seerunde x3', courseId: course.id, laps: 3);
        await (laptop.update(laptop.sessions)
              ..where((s) => s.id.equals(imported)))
            .write(SessionsCompanion(templateId: Value(laptopTemplate)));

        expect(
          (await SessionRepository(laptop).get(imported))!.imported,
          isTrue,
        );
        final laptopRankings = RankingRepository(laptop);
        expect(await laptopRankings.course(course.id), isEmpty);
        expect(await laptopRankings.zone(zone.id), isEmpty);
        expect(await laptopRankings.template(laptopTemplate), isEmpty);
        // On the phone, where it was rowed, the session counts.
        final phoneRankings = RankingRepository(phone);
        expect(
          (await phoneRankings.course(courseId)).single.entries,
          hasLength(3),
        );
        expect(
          (await phoneRankings.zone(tempoId)).single.entries,
          hasLength(3),
        );
        expect(
          (await phoneRankings.template(templateId)).single.entries,
          hasLength(1),
        );
      },
    );
  });
}
