import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/ghost/ghost.dart';
import 'package:aergrow/data/ghost/ghost_repository.dart';
import 'package:aergrow/data/statistics/ranking.dart';
import 'package:aergrow/data/statistics/ranking_repository.dart';
import 'package:aergrow/data/templates/session_template.dart';
import 'package:aergrow/data/templates/template_repository.dart';
import 'package:aergrow/data/zones/zone.dart';
import 'package:aergrow/data/zones/zone_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/ghost_sessions.dart';
import '../../support/rowed_sessions.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late RankingRepository rankings;
  late GhostRepository ghosts;
  late int sprintId;
  late SessionTemplate template;

  /// A lap of 1000 m on the Seerunde with the sprint at its start and again
  /// from 400 m.
  RowedLap lap(int sprintMs) => RowedLap([(sprintMs, 100), (60000, 300), (22000, 100), (100000, 500)]);

  setUp(() async {
    db = openTestDatabase();
    rankings = RankingRepository(db);
    ghosts = GhostRepository(db);
    const sprint = Zone(name: 'Sprint', axis: CourseAxis.distance, length: 100, paceFastCs: 9000, paceSlowCs: 10000);
    sprintId = await ZoneRepository(db).create(sprint);
    final segment = sprint.copyWith(id: sprintId).segment;
    final course = await CourseRepository(db).create(
      'Seerunde',
      CourseDefinition(axis: CourseAxis.distance, length: 1000, segments: [
        segment,
        const CourseSegment(length: 300),
        segment,
        const CourseSegment(length: 500),
      ]),
    );
    final templates = TemplateRepository(db);
    template = (await templates.get(await templates.create('Seerunde x3', courseId: course, laps: 3)))!;
  });

  test('rebuilds a lap from its beginning to its end', () async {
    await storeRowedSessionWithSamples(db, template: template, laps: [lap(21000), lap(19000), lap(20000)]);
    final best = (await rankings.course(template.course.id)).single.entries.first;
    expect(best.lap, 2);

    final track = (await ghosts.track(best))!;

    expect((track.durationMs, track.distanceDm), (201000, 10000));
    expect(track.points.first, const GhostPoint(wallMs: 0, distanceDm: 0));
    expect(track.distanceDmAt(19000), 1000);
    expect(track.distanceDmAt(79000), 4000);
    expect(track.wallMsAt(10000), 201000);
  });

  test('rebuilds the second run through a zone in a lap from where it began', () async {
    await storeRowedSessionWithSamples(db, template: template, laps: [lap(21000), lap(21000), lap(21000)]);
    final second = (await rankings.zone(sprintId))
        .single
        .entries
        .firstWhere((e) => (e.lap, e.position) == (1, 2));
    expect(second.startWallMs, 81000);

    final track = (await ghosts.track(second))!;

    expect((track.durationMs, track.distanceDm), (22000, 1000));
    expect(track.distanceDmAt(0), 0);
    expect(track.distanceDmAt(11000), 500);
  });

  test('rebuilds a whole session over three laps', () async {
    await storeRowedSessionWithSamples(db, template: template, laps: [lap(21000), lap(19000), lap(20000)]);
    final entry = (await rankings.template(template.id)).single.entries.single;

    final track = (await ghosts.track(entry))!;

    expect((track.durationMs, track.distanceDm), (606000, 30000));
    // The end of lap 1 after 203 s, the end of lap 2 after 404 s.
    expect(track.wallMsAt(10000), 203000);
    expect(track.wallMsAt(20000), 404000);
  });

  test('gives no course for samples without wall-clock times, as before schema 2', () async {
    await storeRowedSessionWithSamples(db, template: template, wallClock: false, laps: [lap(21000)]);
    final entry = (await rankings.course(template.course.id)).single.entries.single;

    expect(await ghosts.track(entry), isNull);
  });

  test('gives no course for a session without samples', () async {
    await storeRowedSession(db, template: template, laps: [lap(21000)]);
    final entry = (await rankings.course(template.course.id)).single.entries.single;

    expect(await ghosts.track(entry), isNull);
  });

  test('gives no course for an entry whose session is gone', () async {
    final entry = RankingEntry(
      sessionId: 999,
      startedAt: DateTime(2026),
      startWallMs: 0,
      endWallMs: 1000,
      startDistanceDm: 0,
      endDistanceDm: 50,
    );

    expect(await ghosts.track(entry), isNull);
  });
}
