import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/courses/lap_tracker.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/ghost/ghost_progress.dart';
import 'package:strokesplit/data/ghost/ghost_providers.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/sources/erg_source_providers.dart';
import 'package:strokesplit/data/templates/session_template.dart';
import 'package:strokesplit/data/templates/template_repository.dart';
import 'package:strokesplit/data/zones/zone.dart';
import 'package:strokesplit/data/zones/zone_repository.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_erg_source.dart';
import '../../support/ghost_sessions.dart';
import '../../support/rowed_sessions.dart';
import '../../support/test_database.dart';

class _Fixed extends ActiveErgSource {
  _Fixed(this.source);

  final ErgSource source;

  @override
  ErgSource? build() => source;
}

/// One Rower Data record per second on an FTMS rower, at [speeds] metres per
/// second for the given number of seconds each, from second [from] on.
List<RawPacket> _ftmsRowing(List<(int, int)> speeds, {int from = 0}) {
  const encoder = FtmsEncoder();
  final packets = <RawPacket>[];
  var second = 0;
  var metres = 0;
  void emit() {
    if (second >= from) {
      packets.add(
        encoder.encode(
          RowerData(
            strokeRate: 24,
            strokeCount: second * 2 ~/ 5,
            totalDistance: metres,
            pace: const Duration(minutes: 2),
            power: 180,
            totalEnergy: second ~/ 6,
            energyPerHour: RowerData.energyNotAvailable,
            energyPerMinute: 0xFF,
            elapsedTime: Duration(seconds: second),
          ),
          at: Duration(seconds: second),
        ),
      );
    }
  }

  emit();
  for (final (seconds, speed) in speeds) {
    for (var s = 0; s < seconds; s++) {
      second++;
      metres += speed;
      emit();
    }
  }
  return packets;
}

/// Lets drift streams, flushes and loading courses run.
Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late AppDatabase db;
  late CourseRepository courses;
  late TemplateRepository templates;

  setUp(() {
    db = openTestDatabase();
    courses = CourseRepository(db);
    templates = TemplateRepository(db);
  });

  ProviderContainer containerWith([ErgSource? source]) {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        if (source != null)
          activeErgSourceProvider.overrideWith(() => _Fixed(source)),
        recordingFlushIntervalProvider.overrideWithValue(
          const Duration(milliseconds: 5),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// The ghosts for [template] at the state of [tracker], or of a fresh one.
  Future<LiveGhosts> ghostsOf(
    ProviderContainer container,
    SessionTemplate template, [
    LapProgress? progress,
  ]) async {
    final key = liveGhostsKey(
      template.toPlan(),
      progress ??
          LapTracker(
            template.course.definition,
            plannedLaps: template.laps,
          ).progress,
    );
    container.listen(liveGhostsProvider(key), (_, _) {});
    await _settle();
    return container.read(liveGhostsProvider(key));
  }

  Future<SessionTemplate> templateOn(
    CourseDefinition definition, {
    required int? laps,
  }) async {
    final course = await courses.create('Seerunde', definition);
    return (await templates.get(
      await templates.create('Seerunde x$laps', courseId: course, laps: laps),
    ))!;
  }

  group('during a recording', () {
    late SessionTemplate template;

    setUp(() async {
      template = await templateOn(
        CourseDefinition.single(axis: CourseAxis.distance, length: 100),
        laps: 3,
      );
      // The best so far: three laps of 22 s each.
      await storeRowedSessionWithSamples(
        db,
        template: template,
        laps: [for (var i = 0; i < 3; i++) RowedLap.single(22000, 100)],
      );
    });

    /// Records [template] with [source]: lap 1 in 25 s, lap 2 in 20 s and
    /// lap 3 in 25 s; returns the ghosts during lap 2 and during lap 3.
    Future<(LiveGhosts, LiveGhosts)> rowNewBestLap(ErgSource source) async {
      final fake = source as FakeErgSource;
      final container = containerWith(source);
      final recorder = container.read(sessionRecorderProvider.notifier);
      await recorder.start(plan: template.toPlan());
      final rowing = _ftmsRowing([(25, 4), (20, 5), (25, 4)]);

      rowing.take(36).forEach(fake.emit);
      await _settle();
      final recording = container.read(sessionRecorderProvider)!;
      expect(recording.lap!.lap, 2);
      final inLap2 = await ghostsOf(container, template, recording.lap);

      rowing.skip(36).take(10).forEach(fake.emit);
      await _settle();
      final inLap3Progress = container.read(sessionRecorderProvider)!.lap!;
      expect(inLap3Progress.lap, 3);
      final inLap3 = await ghostsOf(container, template, inLap3Progress);
      return (inLap2, inLap3);
    }

    test('Neue Bestleistung in derselben Session: lap 2 becomes the lap ghost from lap 3 on', () async {
      final (inLap2, inLap3) = await rowNewBestLap(
        FakeErgSource(kind: ErgSourceKind.ftms, protocol: ErgProtocol.ftms),
      );

      expect(inLap2.lap!.durationMs, 22000);
      expect(inLap3.lap!.durationMs, 20000);
      // The session is no whole entry yet, the template ghost stays.
      expect(
        (inLap2.course!.durationMs, inLap3.course!.durationMs),
        (66000, 66000),
      );
      expect((inLap2.segment, inLap3.segment), (null, null));
    });

    test('a simulator session rows against the ghosts as well', () async {
      final (inLap2, _) = await rowNewBestLap(
        FakeErgSource(
          kind: ErgSourceKind.simulator,
          protocol: ErgProtocol.ftms,
        ),
      );

      expect(inLap2.lap!.durationMs, 22000);
      expect(inLap2.course!.durationMs, 66000);
    });

    test('a simulator session never becomes the ghost', () async {
      final (_, inLap3) = await rowNewBestLap(
        FakeErgSource(
          kind: ErgSourceKind.simulator,
          protocol: ErgProtocol.ftms,
        ),
      );

      expect(inLap3.lap!.durationMs, 22000);
      expect(inLap3.course!.durationMs, 66000);
    });
  });

  test(
    'Offene Rundenzahl: no ghost outside, the best lap on the lap track',
    () async {
      final template = await templateOn(
        CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
        laps: null,
      );
      await storeRowedSessionWithSamples(
        db,
        template: template,
        laps: [RowedLap.single(250000, 1000), RowedLap.single(248000, 1000)],
      );

      final ghosts = await ghostsOf(containerWith(), template);

      expect(ghosts.course, isNull);
      expect(ghosts.lap!.durationMs, 248000);
    },
  );

  test('Freier Abschnitt: a ghost inside only in the zone', () async {
    const sprint = Zone(
      name: 'Sprint',
      axis: CourseAxis.distance,
      length: 100,
      paceFastCs: 9000,
      paceSlowCs: 10000,
    );
    final sprintId = await ZoneRepository(db).create(sprint);
    final definition = CourseDefinition(
      axis: CourseAxis.distance,
      length: 1000,
      segments: [
        sprint.copyWith(id: sprintId).segment,
        const CourseSegment(length: 900),
      ],
    );
    final template = await templateOn(definition, laps: 1);
    await storeRowedSessionWithSamples(
      db,
      template: template,
      laps: [
        const RowedLap([(20000, 100), (210000, 900)]),
      ],
    );
    final container = containerWith();
    final tracker = LapTracker(definition, plannedLaps: 1)
      ..add(const TrackPoint(wallMs: 0, distanceDm: 0))
      ..add(const TrackPoint(wallMs: 10000, distanceDm: 500));

    final inZone = await ghostsOf(container, template, tracker.progress);
    tracker.add(const TrackPoint(wallMs: 60000, distanceDm: 3000));
    final free = await ghostsOf(container, template, tracker.progress);

    expect(inZone.segment!.durationMs, 20000);
    expect(free.segment, isNull);
    expect((free.course!.durationMs, free.lap!.durationMs), (230000, 230000));
  });

  test(
    'no ghost for a length that has no entry yet, even with entries for others',
    () async {
      var template = await templateOn(
        CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
        laps: 1,
      );
      await storeRowedSessionWithSamples(
        db,
        template: template,
        laps: [RowedLap.single(250000, 1000)],
      );
      await courses.updateDefinition(
        template.course.id,
        CourseDefinition.single(axis: CourseAxis.distance, length: 1200),
      );
      template = (await templates.get(template.id))!;

      final ghosts = await ghostsOf(containerWith(), template);

      expect(ghosts, (course: null, lap: null, segment: null));
    },
  );

  test(
    'no ghost without a ranking or without the course of its place 1',
    () async {
      final template = await templateOn(
        CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
        laps: 1,
      );
      final container = containerWith();

      expect(await ghostsOf(container, template), (
        course: null,
        lap: null,
        segment: null,
      ));

      await storeRowedSession(
        db,
        template: template,
        laps: [RowedLap.single(250000, 1000)],
      );
      expect(await ghostsOf(container, template), (
        course: null,
        lap: null,
        segment: null,
      ));
    },
  );
}
