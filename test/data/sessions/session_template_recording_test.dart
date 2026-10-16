import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/data/sources/simulated_source.dart';
import 'package:aergrow/data/templates/template_repository.dart';
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
      final started = _run(async, () async {
        await source.start();
        await container.read(sessionRecorderProvider.notifier).start(template: template);
        return container.read(sessionRecorderProvider)!;
      });

      expect(started.template?.name, 'Seerunde x3');
      expect((started.lap!.lap, started.lap!.plannedLaps), (1, 3));
      async.elapse(const Duration(seconds: 30));
      expect(container.read(sessionRecorderProvider)!.lap!.lap, 2);

      // 3 × 100 m at 2:10 /500 m take 78 s.
      async.elapse(const Duration(seconds: 60));
      expect(container.read(sessionRecorderProvider), isNull);
      expect(container.read(finishedSessionProvider), started.sessionId);

      final session = _run(async, (db.select(db.sessions)..where((s) => s.id.equals(started.sessionId))).getSingle);
      final laps = _run(async, db.select(db.laps).get);
      expect(session.status, SessionStatus.complete);
      expect((session.templateId, session.templateName, session.plannedLaps), (template.id, 'Seerunde x3', 3));
      expect(session.courseVersionId, template.course.versionId);
      expect([for (final l in laps) (l.lapNo, l.complete)], [(1, true), (2, true), (3, true)]);
      expect(laps.last.endDistanceDm, 3000);
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
