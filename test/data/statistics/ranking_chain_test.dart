import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sessions/session_plan.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/sources/erg_source_providers.dart';
import 'package:strokesplit/data/sources/simulated_source.dart';
import 'package:strokesplit/data/statistics/ranking.dart';
import 'package:strokesplit/data/statistics/ranking_repository.dart';
import 'package:strokesplit/data/statistics/session_places.dart';
import 'package:strokesplit/data/workouts/workout.dart';
import 'package:strokesplit/data/workouts/workout_repository.dart';
import 'package:strokesplit/data/zones/zone.dart';
import 'package:strokesplit/data/zones/zone_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/rowed_sessions.dart';
import '../../support/test_database.dart';

/// Per ranking its length and the seconds of its entries.
List<String> _values(List<Ranking> rankings) => [
  for (final r in rankings)
    '${r.length}: ${[for (final e in r.entries) e.durationMs ~/ 1000].join(', ')}',
];

class _Fixed extends ActiveErgSource {
  _Fixed(this.source);

  final ErgSource source;

  @override
  ErgSource? build() => source;
}

/// Runs [body] to its end in fake time.
T _run<T>(FakeAsync async, Future<T> Function() body) {
  late T result;
  body().then((value) => result = value);
  async.flushMicrotasks();
  return result;
}

/// Rankings of workouts with several courses in a row (Change
/// workout-course-chain, Design D4).
void main() {
  late AppDatabase db;
  late CourseRepository courses;
  late WorkoutRepository workouts;
  late RankingRepository rankings;
  late int einrudern;
  late int seerunde;
  late int ausrudern;

  setUp(() async {
    db = openTestDatabase();
    courses = CourseRepository(db);
    workouts = WorkoutRepository(db);
    rankings = RankingRepository(db);
    einrudern = await courses.create(
      'Einrudern',
      CourseDefinition.single(axis: CourseAxis.distance, length: 500),
    );
    seerunde = await courses.create(
      'Seerunde',
      CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
    );
    ausrudern = await courses.create(
      'Ausrudern',
      CourseDefinition.single(axis: CourseAxis.distance, length: 500),
    );
  });

  Future<Workout> workout(
    String name,
    List<int> courseIds, {
    PlanLength length = const LapCount(1),
  }) async => (await workouts.get(
    await workouts.create(name, courseIds: courseIds, length: length),
  ))!;

  group('course', () {
    test('ranks a course rowed alone and in a chain together', () async {
      await storeRowedSession(
        db,
        courseVersionId: (await courses.get(seerunde))!.versionId,
        laps: [RowedLap.single(250000, 1000)],
      );
      final chain = await workout('Seerunde mit Ein- und Ausrudern', [
        einrudern,
        seerunde,
        ausrudern,
      ]);
      final session = await storeRowedSession(
        db,
        workout: chain,
        laps: [
          const RowedLap([(120000, 500), (245000, 1000), (130000, 500)]),
        ],
      );

      final ranked = await rankings.course(seerunde);

      expect(_values(ranked), ['1000: 245, 250']);
      final run = ranked.single.entries.first;
      expect(
        (
          run.sessionId,
          run.lap,
          run.startWallMs,
          run.endWallMs,
          run.startDistanceDm,
          run.endDistanceDm,
        ),
        (session, 1, 120000, 365000, 5000, 15000),
      );
      expect(_values(await rankings.course(einrudern)), ['500: 120']);
      expect(_values(await rankings.course(ausrudern)), ['500: 130']);
    });

    test('keeps the values of sessions with a single course', () async {
      final x2 = await workout('Seerunde x2', [
        seerunde,
      ], length: const LapCount(2));
      final session = await storeRowedSession(
        db,
        workout: x2,
        laps: [RowedLap.single(250000, 1000), RowedLap.single(248000, 1000)],
      );

      final entries = (await rankings.course(seerunde)).single.entries;

      expect(
        [
          for (final e in entries)
            (
              e.sessionId,
              e.lap,
              e.position,
              e.startWallMs,
              e.endWallMs,
              e.startDistanceDm,
              e.endDistanceDm,
            ),
        ],
        [
          (session, 2, null, 250000, 498000, 10000, 20000),
          (session, 1, null, 0, 250000, 0, 10000),
        ],
      );
    });

    test('counts the courses rowed to their end when a chain was stopped', () {
      final source = SimulatedSource(seed: 1);
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          activeErgSourceProvider.overrideWith(() => _Fixed(source)),
        ],
      );
      addTearDown(container.dispose);

      fakeAsync((async) {
        final chain = _run(async, () async {
          final short = [
            for (final (name, length) in [
              ('Kurz ein', 100),
              ('Kurz Mitte', 200),
              ('Kurz aus', 100),
            ])
              await courses.create(
                name,
                CourseDefinition.single(
                  axis: CourseAxis.distance,
                  length: length,
                ),
              ),
          ];
          return workout('Kurzkette', short);
        });
        _run(async, () async {
          await source.start();
          await container
              .read(sessionRecorderProvider.notifier)
              .start(plan: chain.toPlan());
        });
        async.elapse(const Duration(milliseconds: 500));
        final id = container.read(sessionRecorderProvider)!.sessionId!;
        // About 350 m at 2:10 /500 m: in the middle of "Kurz aus".
        async.elapse(const Duration(seconds: 91));
        _run(async, container.read(sessionRecorderProvider.notifier).stop);
        source.stop();
        // Recorded with the simulator, counted as if rowed on a PM5.
        _run(
          async,
          () => (db.update(db.sessions)..where((s) => s.id.equals(id))).write(
            const SessionsCompanion(source: Value(ErgSourceKind.pm5)),
          ),
        );

        final counts = [
          for (final c in chain.courses)
            _run(
              async,
              () => rankings.course(c.id),
            ).fold(0, (sum, r) => sum + r.entries.length),
        ];
        expect(counts, [1, 1, 0]);
        final laps = _run(async, db.select(db.laps).get);
        expect([for (final l in laps) l.complete], [false]);
      });
    });
  });

  group('zone', () {
    test('finds a sprint in the second course of a chain', () async {
      final zones = ZoneRepository(db);
      const sprint = Zone(
        name: 'Sprint',
        axis: CourseAxis.distance,
        length: 100,
        paceFastCs: 9000,
        paceSlowCs: 10000,
      );
      final sprintId = await zones.create(sprint);
      final withSprint = await courses.create(
        'Sprint am Ende',
        CourseDefinition(
          axis: CourseAxis.distance,
          length: 500,
          segments: [
            const CourseSegment(length: 400),
            sprint.copyWith(id: sprintId).segment,
          ],
        ),
      );
      final chain = await workout('Ein und Sprint', [einrudern, withSprint]);
      final session = await storeRowedSession(
        db,
        workout: chain,
        laps: [
          const RowedLap([(120000, 500), (100000, 400), (18500, 100)]),
        ],
      );

      final entry = (await rankings.zone(sprintId)).single.entries.single;

      expect(
        (
          entry.sessionId,
          entry.position,
          entry.startWallMs,
          entry.endWallMs,
          entry.startDistanceDm,
          entry.endDistanceDm,
        ),
        (session, 2, 220000, 238500, 9000, 10000),
      );
    });
  });

  group('workout', () {
    test('ranks a workout anew when a course was appended', () async {
      final training = await workout('Training', [seerunde]);
      await storeRowedSession(
        db,
        workout: training,
        laps: [RowedLap.single(250000, 1000)],
      );
      await workouts.update(
        training.id,
        name: 'Training',
        courseIds: [seerunde, ausrudern],
        length: const LapCount(1),
      );
      await storeRowedSession(
        db,
        workout: (await workouts.get(training.id))!,
        laps: [
          const RowedLap([(252000, 1000), (130000, 500)]),
        ],
      );

      final ranked = await rankings.workout(training.id);

      expect(
        [
          for (final r in ranked)
            (r.length, r.laps, r.courseLengths?.join(' + '), r.entries.length),
        ],
        [(1500, 1, '1000 + 500', 1), (1000, 1, '1000', 1)],
      );
      expect(_values(ranked), ['1500: 382', '1000: 250']);
    });

    test(
      'has no ranking and no places for a workout with a duration',
      () async {
        final timed = await workout('Seerunde 45 min', [
          einrudern,
          seerunde,
        ], length: const TimeLimit(Duration(minutes: 45)));
        final session = await storeRowedSession(
          db,
          workout: timed,
          plannedDuration: const Duration(minutes: 45),
          laps: [
            const RowedLap([(120000, 500), (245000, 1000)]),
            const RowedLap([(121000, 500), (246000, 1000)]),
          ],
        );

        expect(await rankings.workout(timed.id), isEmpty);
        final places = await SessionPlacesRepository(
          db,
          rankings,
        ).places(session);
        expect(places.session, isNull);
        expect(places.laps, isEmpty);
        expect(_values(await rankings.course(seerunde)), ['1000: 245, 246']);
      },
    );
  });
}
