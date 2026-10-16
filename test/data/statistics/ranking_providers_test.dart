import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/data/statistics/ranking.dart';
import 'package:aergrow/data/statistics/ranking_providers.dart';
import 'package:aergrow/data/statistics/ranking_repository.dart';
import 'package:aergrow/data/templates/template_repository.dart';
import 'package:aergrow/data/zones/zone.dart';
import 'package:aergrow/data/zones/zone_repository.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_erg_source.dart';
import '../../support/fixtures.dart';
import '../../support/rowed_sessions.dart';
import '../../support/test_database.dart';

class _Fixed extends ActiveErgSource {
  _Fixed(this.source);

  final ErgSource source;

  @override
  ErgSource? build() => source;
}

void main() {
  test('gives a new first place once a session ends', () async {
    final db = openTestDatabase();
    final source = FakeErgSource(kind: ErgSourceKind.ftms, protocol: ErgProtocol.ftms);
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      activeErgSourceProvider.overrideWith(() => _Fixed(source)),
      recordingFlushIntervalProvider.overrideWithValue(const Duration(milliseconds: 10)),
    ]);
    addTearDown(container.dispose);
    final course =
        await CourseRepository(db).create('Seerunde', CourseDefinition.single(axis: CourseAxis.distance, length: 100));
    final templates = TemplateRepository(db);
    final template = (await templates.get(await templates.create('Seerunde x1', courseId: course, laps: 1)))!;
    await storeRowedSession(db, template: template, laps: [RowedLap.single(30000, 100)]);
    final seen = <List<Ranking>>[];
    container.listen(courseRankingsProvider(course), (_, next) => seen.addAll([?next.value]), fireImmediately: true);
    await pumpEventQueue();
    expect(seen.last.single.entries.single.durationMs, 30000);

    final recorder = container.read(sessionRecorderProvider.notifier);
    await recorder.start(template: template);
    // 100 m at 4 m/s; the session starts with the first stroke and ends by itself after its only lap.
    ftmsRowing(seconds: 30).forEach(source.emit);
    await pumpEventQueue();
    expect(container.read(sessionRecorderProvider), isNull);
    final id = container.read(finishedSessionProvider);

    final first = seen.last.single.entries.first;
    expect((first.sessionId, first.durationMs), (id, 25000));
    expect(seen.last.single.entries, hasLength(2));
    container.listen(templateRankingsProvider(template.id), (_, _) {});
    final rankings = await container.read(templateRankingsProvider(template.id).future);
    expect(rankings.single.entries.first.sessionId, id);
  });

  test('keeps places 1 to 3', () async {
    final db = openTestDatabase();
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    final course =
        await CourseRepository(db).create('Seerunde', CourseDefinition.single(axis: CourseAxis.distance, length: 1000));
    final versionId = (await CourseRepository(db).get(course))!.versionId;
    await storeRowedSession(db, courseVersionId: versionId, laps: [
      for (var i = 0; i < 5; i++) RowedLap.single(250000 - i * 1000, 1000),
    ]);

    container.listen(courseRankingsProvider(course), (_, _) {});
    final rankings = await container.read(courseRankingsProvider(course).future);

    expect([for (final e in rankings.single.entries) e.lap], [5, 4, 3]);
  });

  test('ranks 200 sessions of 3 laps with 2 zones quickly', () async {
    final db = openTestDatabase();
    final zones = ZoneRepository(db);
    const sprint = Zone(name: 'Sprint', axis: CourseAxis.distance, length: 100, paceFastCs: 9000, paceSlowCs: 10000);
    const tempo = Zone(name: 'Tempo', axis: CourseAxis.distance, length: 200, paceFastCs: 11000, paceSlowCs: 12000);
    final sprintId = await zones.create(sprint);
    final tempoId = await zones.create(tempo);
    final course = await CourseRepository(db).create(
      'Seerunde',
      CourseDefinition(axis: CourseAxis.distance, length: 1000, segments: [
        sprint.copyWith(id: sprintId).segment,
        const CourseSegment(length: 300),
        tempo.copyWith(id: tempoId).segment,
        const CourseSegment(length: 400),
      ]),
    );
    final templates = TemplateRepository(db);
    final templateId = await templates.create('Seerunde x3', courseId: course, laps: 3);
    final template = (await templates.get(templateId))!;
    for (var i = 0; i < 200; i++) {
      final lap = RowedLap([(18000 + i, 100), (70000, 300), (44000 + i, 200), (100000 - i, 400)]);
      final startedAt = DateTime(2026, 1, 1).add(Duration(hours: i));
      await storeRowedSession(db, template: template, startedAt: startedAt, laps: [lap, lap, lap]);
    }
    final rankings = RankingRepository(db);

    final watch = Stopwatch()..start();
    final results = [
      await rankings.template(templateId),
      await rankings.course(course),
      await rankings.zone(sprintId),
      await rankings.zone(tempoId),
    ];
    watch.stop();

    expect([for (final r in results) r.single.entries.length], [200, 600, 600, 600]);
    // About 20–70 ms for all four on a laptop (Task 1.6); the bound leaves room for slow machines.
    expect(watch.elapsed, lessThan(const Duration(milliseconds: 500)));
  });
}
