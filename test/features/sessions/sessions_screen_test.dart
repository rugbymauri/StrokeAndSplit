import 'package:strokesplit/app/platform_providers.dart';
import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/sessions/session_accumulator.dart';
import 'package:strokesplit/data/sessions/session_plan.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sessions/session_repository.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/sources/erg_source_providers.dart';
import 'package:strokesplit/data/templates/template_repository.dart';
import 'package:strokesplit/features/sessions/sessions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/fake_session_files.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';
import '../../support/localized_app.dart';

class _Setup {
  final db = openTestDatabase();
  late final repository = SessionRepository(db);
  final files = FakeSessionFiles();
  late final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      wakelockProvider.overrideWithValue(FakeWakelock()),
      sessionFilesProvider.overrideWithValue(files),
    ],
  );

  /// Stores a finished session, recorded from [fixture] when given.
  Future<int> addSession(
    WidgetTester tester,
    DateTime startedAt, {
    String? fixture,
  }) async {
    return (await tester.runAsync(() async {
      final id = await repository.create(
        startedAt: startedAt,
        source: ErgSourceKind.pm5,
        deviceName: 'PM5 Test',
      );
      if (fixture != null) {
        final accumulator = SessionAccumulator(id);
        loadFixture(fixture).packets.forEach(accumulator.add);
        accumulator.finish();
        await repository.write(accumulator.takeBatch());
      }
      await repository.finish(id);
      return id;
    }))!;
  }

  Future<void> pump(WidgetTester tester) async {
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LocalizedApp(home: SessionsScreen()),
      ),
    );
    await tester.pump();
  }

  Future<void> tearDown(WidgetTester tester) async {
    await container.read(activeErgSourceProvider.notifier).clear();
    await disposeWidgetsWithDatabase(tester);
  }
}

void main() {
  testWidgets('says when nothing is recorded yet', (tester) async {
    final setup = _Setup();
    await setup.pump(tester);

    expect(find.text('Noch keine Sessions aufgezeichnet.'), findsOneWidget);
    await setup.tearDown(tester);
  });

  testWidgets('lists the newest session first', (tester) async {
    final setup = _Setup();
    await setup.addSession(tester, DateTime(2026, 10, 14, 7));
    await setup.addSession(
      tester,
      DateTime(2026, 10, 15, 18, 30),
      fixture: 'just_row',
    );
    await setup.addSession(tester, DateTime(2026, 10, 12, 19));
    await setup.pump(tester);

    final dates = [
      '15.10.2026, 18:30',
      '14.10.2026, 07:00',
      '12.10.2026, 19:00',
    ];
    final tops = [for (final d in dates) tester.getTopLeft(find.text(d)).dy];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(find.textContaining('/500 m'), findsNWidgets(3));
    await setup.tearDown(tester);
  });

  testWidgets('deletes a session only after confirmation', (tester) async {
    final setup = _Setup();
    final id = await setup.addSession(
      tester,
      DateTime(2026, 10, 15, 18, 30),
      fixture: 'just_row',
    );
    await setup.pump(tester);

    Future<void> chooseDelete() async {
      await tester.tap(find.byTooltip('Aktionen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();
      expect(find.text('Session löschen?'), findsOneWidget);
    }

    await chooseDelete();
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.text('15.10.2026, 18:30'), findsOneWidget);

    await chooseDelete();
    await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
    await tester.pumpAndSettle();
    expect(find.text('Noch keine Sessions aufgezeichnet.'), findsOneWidget);

    final left = await tester.runAsync(
      () async => (
        await setup.repository.get(id),
        await setup.db.select(setup.db.samples).get(),
        await setup.db.select(setup.db.rawPackets).get(),
      ),
    );
    expect(left!.$1, isNull);
    expect(left.$2, isEmpty);
    expect(left.$3, isEmpty);
    await setup.tearDown(tester);
  });

  testWidgets('plays a session back in the live display', (tester) async {
    final setup = _Setup();
    await setup.addSession(
      tester,
      DateTime(2026, 10, 15, 18, 30),
      fixture: 'just_row',
    );
    await setup.pump(tester);

    await tester.tap(find.byTooltip('Aktionen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abspielen'));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(
      setup.container.read(activeErgSourceProvider)?.kind,
      ErgSourceKind.replay,
    );
    expect(find.text('REPLAY'), findsOneWidget);
    final distance = tester
        .widget<Text>(find.byKey(const Key('metric-distance')))
        .textSpan!
        .toPlainText();
    expect(int.parse(distance.replaceAll(RegExp(r'\D'), '')), greaterThan(0));
    await setup.tearDown(tester);
  });

  testWidgets('exports a session and imports the file again', (tester) async {
    final setup = _Setup();
    await setup.addSession(
      tester,
      DateTime(2026, 10, 15, 18, 30),
      fixture: 'just_row',
    );
    await setup.pump(tester);

    await tester.tap(find.byTooltip('Aktionen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exportieren'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(setup.files.saved.keys, ['strokesplit-2026-10-15-1830.strokesplit']);
    expect(find.text('Session exportiert.'), findsOneWidget);

    setup.files.toOpen = setup.files.saved.values.single;
    await tester.tap(find.byTooltip('Importieren'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(find.text('Session importiert.'), findsOneWidget);
    expect(find.text('15.10.2026, 18:30'), findsNWidgets(2));

    setup.files.toOpen = [1, 2, 3];
    await tester.tap(find.byTooltip('Importieren'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(
      find.textContaining('keine lesbare Stroke & Split-Session'),
      findsOneWidget,
    );
    await setup.tearDown(tester);
  });

  testWidgets('names the template of a session, also after it was deleted', (
    tester,
  ) async {
    final setup = _Setup();
    await tester.runAsync(() async {
      final courses = CourseRepository(setup.db);
      final templates = TemplateRepository(setup.db);
      final course = await courses.create(
        'Seerunde',
        CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
      );
      final kept = await templates.create(
        'Seerunde x3',
        courseId: course,
        laps: 3,
      );
      final deleted = await templates.create(
        'Seerunde offen',
        courseId: course,
        laps: null,
      );
      for (final id in [kept, deleted]) {
        final session = await setup.repository.create(
          startedAt: DateTime(2026, 10, 16, 7),
          source: ErgSourceKind.simulator,
          plan: (await templates.get(id))!.toPlan(),
        );
        await setup.repository.finish(session);
      }
      await templates.delete(deleted);
    });
    await setup.addSession(tester, DateTime(2026, 10, 15, 18, 30));
    await setup.pump(tester);

    expect(find.textContaining('Seerunde x3 · '), findsOneWidget);
    expect(find.textContaining('Seerunde offen · '), findsOneWidget);
    expect(find.textContaining('Seerunde'), findsNWidgets(2));
    await setup.tearDown(tester);
  });

  testWidgets(
    'names a course rowed without a template by the course and its planned length',
    (tester) async {
      final setup = _Setup();
      await tester.runAsync(() async {
        final courses = CourseRepository(setup.db);
        final course = (await courses.get(
          await courses.create(
            'Seerunde',
            CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
          ),
        ))!;
        for (final (day, length) in const [
          (14, TimeLimit(Duration(minutes: 30))),
          (15, LapCount(3)),
          (16, OpenLength()),
        ]) {
          final session = await setup.repository.create(
            startedAt: DateTime(2026, 10, day, 7),
            source: ErgSourceKind.pm5,
            plan: SessionPlan(course: course, length: length),
          );
          await setup.repository.finish(session);
        }
      });
      await setup.pump(tester);
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }

      expect(find.textContaining('Seerunde · 30 min · '), findsOneWidget);
      expect(find.textContaining('Seerunde · 3 Runden · '), findsOneWidget);
      expect(find.textContaining('Seerunde · offen · '), findsOneWidget);
      await setup.tearDown(tester);
    },
  );
}
