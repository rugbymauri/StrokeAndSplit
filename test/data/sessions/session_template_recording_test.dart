import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/sources/erg_source_providers.dart';
import 'package:strokesplit/data/sources/simulated_source.dart';
import 'package:strokesplit/data/templates/template_repository.dart';
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

void main() {
  late AppDatabase db;
  late SimulatedSource source;
  late ProviderContainer container;

  setUp(() {
    db = openTestDatabase();
    source = SimulatedSource(seed: 1);
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      activeErgSourceProvider.overrideWith(() => _Fixed(source)),
    ]);
    addTearDown(container.dispose);
  });

  test('a template with three laps ends by itself after the third lap', () {
    fakeAsync((async) {
      final template = _run(async, () async {
        final courses = CourseRepository(db);
        final course =
            await courses.create('Seerunde', CourseDefinition.single(axis: CourseAxis.distance, length: 100));
        final templates = TemplateRepository(db);
        return (await templates.get(await templates.create('Seerunde x3', courseId: course, laps: 3)))!;
      });
      final ready = _run(async, () async {
        await source.start();
        await container.read(sessionRecorderProvider.notifier).start(template: template);
        return container.read(sessionRecorderProvider)!;
      });
      expect((ready.ready, ready.template?.name), (true, 'Seerunde x3'));
      // The simulator rows from the start: its second status starts the session.
      async.elapse(const Duration(milliseconds: 500));
      final started = container.read(sessionRecorderProvider)!;

      expect(started.ready, isFalse);
      expect((started.lap!.lap, started.lap!.plannedLaps), (1, 3));
      async.elapse(const Duration(seconds: 30));
      expect(container.read(sessionRecorderProvider)!.lap!.lap, 2);

      // 3 × 100 m at 2:10 /500 m take 78 s.
      async.elapse(const Duration(seconds: 60));
      expect(container.read(sessionRecorderProvider), isNull);
      expect(container.read(finishedSessionProvider), started.sessionId);

      final session = _run(async, (db.select(db.sessions)..where((s) => s.id.equals(started.sessionId!))).getSingle);
      final laps = _run(async, db.select(db.laps).get);
      expect(session.status, SessionStatus.complete);
      expect((session.templateId, session.templateName, session.plannedLaps), (template.id, 'Seerunde x3', 3));
      expect(session.courseVersionId, template.course.versionId);
      expect([for (final l in laps) (l.lapNo, l.complete)], [(1, true), (2, true), (3, true)]);
      expect(laps.last.endDistanceDm, 3000);
      source.stop();
    });
  });

  test('a time segment runs from the first stroke, not from choosing the template', () {
    fakeAsync((async) {
      final template = _run(async, () async {
        final course = await CourseRepository(db)
            .create('Vier Minuten', CourseDefinition.single(axis: CourseAxis.time, length: 240));
        final templates = TemplateRepository(db);
        return (await templates.get(await templates.create('Vier Minuten', courseId: course, laps: 1)))!;
      });
      _run(async, () async {
        // Not rowing yet when the template is chosen.
        source.pause();
        await source.start();
        await container.read(sessionRecorderProvider.notifier).start(template: template);
      });

      async.elapse(const Duration(seconds: 30));
      final ready = container.read(sessionRecorderProvider)!;
      expect(ready.ready, isTrue);
      expect((ready.lap!.segmentTime, ready.lap!.courseTime, ready.progress.elapsed), (
        Duration.zero,
        Duration.zero,
        Duration.zero,
      ));
      expect(_run(async, db.select(db.sessions).get), isEmpty);

      source.resume();
      async.elapse(const Duration(seconds: 10));
      final rowing = container.read(sessionRecorderProvider)!;
      expect(rowing.ready, isFalse);
      // Counted from the last status before the first stroke, at most one status earlier.
      expect(rowing.lap!.segmentTime.inMilliseconds, inInclusiveRange(10000, 11000));
      expect(rowing.lap!.remaining, inInclusiveRange(229, 230));

      // The segment ends 4 minutes after the first stroke.
      async.elapse(const Duration(seconds: 229));
      expect(container.read(sessionRecorderProvider), isNotNull);
      async.elapse(const Duration(seconds: 2));
      expect(container.read(sessionRecorderProvider), isNull);
      source.stop();
    });
  });

  test('a session without template has no laps', () {
    fakeAsync((async) {
      _run(async, () async {
        await source.start();
        await container.read(sessionRecorderProvider.notifier).start();
      });
      async.elapse(const Duration(seconds: 10));

      final recording = container.read(sessionRecorderProvider)!;
      expect((recording.template, recording.lap), (null, null));
      _run(async, container.read(sessionRecorderProvider.notifier).stop);
      expect(_run(async, db.select(db.laps).get), isEmpty);
      source.stop();
    });
  });
}
