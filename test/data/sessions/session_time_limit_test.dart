import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sessions/session_plan.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/sources/erg_source_providers.dart';
import 'package:strokesplit/data/sources/simulated_source.dart';
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

/// Ending a course rowed for a total time (Change course-rowing-free, Design D2).
void main() {
  late AppDatabase db;
  late SimulatedSource source;
  late ProviderContainer container;

  setUp(() {
    db = openTestDatabase();
    source = SimulatedSource(seed: 1);
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        activeErgSourceProvider.overrideWith(() => _Fixed(source)),
      ],
    );
    addTearDown(container.dispose);
  });

  Course course(FakeAsync async, CourseDefinition definition) => _run(
    async,
    () async {
      final courses = CourseRepository(db);
      return (await courses.get(await courses.create('Seerunde', definition)))!;
    },
  );

  /// Starts [length] on [course] and returns the recording once it runs.
  ActiveRecording start(FakeAsync async, Course course, PlanLength length) {
    _run(async, () async {
      await source.start();
      await container
          .read(sessionRecorderProvider.notifier)
          .start(
            plan: SessionPlan(courses: [course], length: length),
          );
    });
    async.elapse(const Duration(milliseconds: 500));
    return container.read(sessionRecorderProvider)!;
  }

  SessionRow session(FakeAsync async, int id) => _run(
    async,
    (db.select(db.sessions)..where((s) => s.id.equals(id))).getSingle,
  );

  List<LapRow> laps(FakeAsync async) => _run(async, db.select(db.laps).get);

  test('ends at the first value whose rowing time reaches the duration, in the middle of a lap', () {
    fakeAsync((async) {
      final seerunde = course(
        async,
        CourseDefinition.single(axis: CourseAxis.distance, length: 2400),
      );
      final started = start(
        async,
        seerunde,
        const TimeLimit(Duration(minutes: 3)),
      );
      expect(
        (started.lap!.plannedLaps, started.plan!.plannedDuration),
        (null, const Duration(minutes: 3)),
      );

      async.elapse(const Duration(minutes: 2, seconds: 59));
      expect(
        container.read(sessionRecorderProvider),
        isNotNull,
        reason: 'before the duration',
      );
      async.elapse(const Duration(seconds: 2));
      expect(container.read(sessionRecorderProvider), isNull);
      expect(container.read(finishedSessionProvider), started.sessionId);

      final ended = session(async, started.sessionId!);
      expect(ended.durationMs, inInclusiveRange(180000, 181000));
      expect(ended.plannedDurationMs, 180000);
      // About 690 m at 2:10 /500 m: the first lap of 2.4 km stays incomplete.
      expect(
        [for (final l in laps(async)) (l.lapNo, l.complete)],
        [(1, false)],
      );
      source.stop();
    });
  });

  test('a pause moves the end by the length of the pause', () {
    fakeAsync((async) {
      final seerunde = course(
        async,
        CourseDefinition.single(axis: CourseAxis.distance, length: 2400),
      );
      final started = start(
        async,
        seerunde,
        const TimeLimit(Duration(minutes: 3)),
      );

      async.elapse(const Duration(minutes: 1));
      source.pause();
      async.elapse(const Duration(minutes: 2));
      source.resume();
      // Without the pause it would have ended by now.
      async.elapse(const Duration(seconds: 30));
      expect(container.read(sessionRecorderProvider), isNotNull);

      async.elapse(const Duration(minutes: 2));
      expect(container.read(sessionRecorderProvider), isNull);
      final ended = session(async, started.sessionId!);
      expect(ended.pauseCount, 1);
      expect(ended.durationMs, inInclusiveRange(180000, 181000));
      source.stop();
    });
  });

  test('"Vier Minuten" for 30 minutes gives 7 complete laps and an 8th after 2 minutes', () {
    fakeAsync((async) {
      final vierMinuten = course(
        async,
        CourseDefinition.single(axis: CourseAxis.time, length: 240),
      );
      final started = start(
        async,
        vierMinuten,
        const TimeLimit(Duration(minutes: 30)),
      );

      async.elapse(const Duration(minutes: 31));
      expect(container.read(sessionRecorderProvider), isNull);

      final rowed = laps(async);
      expect(
        [for (final l in rowed) l.complete],
        [for (var i = 0; i < 8; i++) i < 7],
      );
      final last = rowed.last;
      expect(
        last.endWallMs - last.startWallMs,
        inInclusiveRange(120000, 121000),
      );
      expect(
        session(async, started.sessionId!).durationMs,
        inInclusiveRange(1800000, 1801000),
      );
      source.stop();
    });
  });

  test('with laps or open the session ends as before', () {
    fakeAsync((async) {
      final sprint = course(
        async,
        CourseDefinition.single(axis: CourseAxis.distance, length: 100),
      );
      start(async, sprint, const LapCount(2));
      async.elapse(const Duration(seconds: 60));
      expect(
        container.read(sessionRecorderProvider),
        isNull,
        reason: '2 × 100 m end by themselves',
      );

      start(async, sprint, const OpenLength());
      async.elapse(const Duration(minutes: 5));
      final open = container.read(sessionRecorderProvider)!;
      expect(open.lap!.lap, greaterThan(5), reason: 'open laps go on');
      _run(async, container.read(sessionRecorderProvider.notifier).stop);
      source.stop();
    });
  });
}
