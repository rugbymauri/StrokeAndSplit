import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/courses/lap_tracker.dart';
import 'package:strokesplit/data/sessions/session_plan.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/sources/erg_source_providers.dart';
import 'package:strokesplit/data/sources/simulated_source.dart';
import 'package:strokesplit/data/workouts/workout_repository.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

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

Course _course(int id, String name, CourseDefinition definition) => Course(
  id: id,
  versionId: id,
  version: 1,
  name: name,
  definition: definition,
);

final _einrudern = _course(
  1,
  'Einrudern',
  CourseDefinition.single(axis: CourseAxis.distance, length: 500),
);

final _intervall = _course(
  2,
  '2 km Intervall',
  const CourseDefinition(
    axis: CourseAxis.distance,
    length: 2000,
    segments: [
      CourseSegment(length: 500),
      CourseSegment(length: 1000, spmMin: 24, spmMax: 28),
      CourseSegment(length: 500),
    ],
  ),
);

final _ausrudern = _course(
  3,
  'Ausrudern',
  CourseDefinition.single(axis: CourseAxis.distance, length: 500),
);

/// A point at [seconds] wall-clock time and [meters].
TrackPoint _at(num seconds, num meters) => TrackPoint(
  wallMs: (seconds * 1000).round(),
  distanceDm: (meters * 10).round(),
  paceCs: 12500,
  strokeRate: 22,
);

/// Workouts with several courses in a row (Change workout-course-chain).
void main() {
  group('a chain of courses', () {
    test('is one lap with the segments of all courses in order', () {
      final chain = CourseDefinition.chain([
        _einrudern.definition,
        _intervall.definition,
        _ausrudern.definition,
      ]);

      expect((chain.axis, chain.length), (CourseAxis.distance, 3000));
      expect(chain.segmentEnds, [500, 1000, 2000, 2500, 3000]);
    });

    test('of one course is that course', () {
      expect(
        CourseDefinition.chain([_intervall.definition]),
        _intervall.definition,
      );
    });

    test('mixes no axes', () {
      expect(
        () => CourseDefinition.chain([
          _einrudern.definition,
          CourseDefinition.single(axis: CourseAxis.time, length: 240),
        ]),
        throwsArgumentError,
      );
    });

    test('knows where each course starts', () {
      final plan = SessionPlan(
        courses: [_einrudern, _intervall, _ausrudern],
        length: const LapCount(1),
      );

      expect(plan.courseStarts, [0, 1, 4]);
      expect([for (var s = 0; s < 5; s++) plan.courseAt(s)], [0, 1, 1, 1, 2]);
    });
  });

  group('rowing a chain', () {
    final plan = SessionPlan(
      courses: [_einrudern, _intervall, _ausrudern],
      length: const OpenLength(),
    );

    test('goes on to the next course at 500 m without a new lap', () {
      final tracker = LapTracker(plan.definition)
        ..add(_at(0, 0))
        ..add(_at(124, 496))
        ..add(_at(130, 520));

      final progress = tracker.progress;
      expect((progress.lap, progress.segmentIndex), (1, 1));
      expect(
        plan.courses[plan.courseAt(progress.segmentIndex)].name,
        '2 km Intervall',
      );
      expect(tracker.takeLaps(), isEmpty);
    });

    test('ends a lap only after the last course at 3000 m', () {
      final tracker = LapTracker(plan.definition)
        ..add(_at(0, 0))
        ..add(_at(375, 1500))
        ..add(_at(749, 2996))
        ..add(_at(751, 3004));

      final laps = tracker.takeLaps();
      expect(
        [for (final l in laps) (l.lap, l.endDistanceDm, l.complete)],
        [(1, 30000, true)],
      );
      expect(tracker.progress.lap, 2);
      expect(tracker.takeSegments(), hasLength(5));
    });
  });

  test('a workout with a duration ends after 45 min of rowing', () {
    final db = openTestDatabase();
    final source = SimulatedSource(seed: 1);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        activeErgSourceProvider.overrideWith(() => _Fixed(source)),
      ],
    );
    addTearDown(container.dispose);

    fakeAsync((async) {
      final workout = _run(async, () async {
        final courses = CourseRepository(db);
        final ids = [
          for (final c in [_einrudern, _intervall, _ausrudern])
            await courses.create(c.name, c.definition),
        ];
        final workouts = WorkoutRepository(db);
        return (await workouts.get(
          await workouts.create(
            'Intervalltraining 45 min',
            courseIds: ids,
            length: const TimeLimit(Duration(minutes: 45)),
          ),
        ))!;
      });
      final plan = workout.toPlan();
      expect(
        (plan.plannedLaps, plan.plannedDuration, plan.definition.length),
        (null, const Duration(minutes: 45), 3000),
      );
      _run(async, () async {
        await source.start();
        await container
            .read(sessionRecorderProvider.notifier)
            .start(plan: plan);
      });
      async.elapse(const Duration(milliseconds: 500));
      final id = container.read(sessionRecorderProvider)!.sessionId!;

      async.elapse(const Duration(minutes: 44, seconds: 59));
      expect(container.read(sessionRecorderProvider), isNotNull);
      async.elapse(const Duration(seconds: 2));
      expect(container.read(sessionRecorderProvider), isNull);

      final session = _run(
        async,
        (db.select(db.sessions)..where((s) => s.id.equals(id))).getSingle,
      );
      expect(
        (session.workoutName, session.plannedLaps, session.plannedDurationMs),
        ('Intervalltraining 45 min', null, 2700000),
      );
      expect(session.durationMs, inInclusiveRange(2700000, 2701000));
      // About 10.4 km at 2:10 /500 m: three full laps of 3000 m.
      final laps = _run(async, db.select(db.laps).get);
      expect([for (final l in laps) l.complete], [true, true, true, false]);
      source.stop();
    });
  });
}
