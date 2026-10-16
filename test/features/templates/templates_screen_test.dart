import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/data/templates/template_repository.dart';
import 'package:aergrow/features/connection/start_screen.dart';
import 'package:aergrow/features/sessions/session_summary_screen.dart';
import 'package:aergrow/features/templates/templates_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/test_database.dart';

class _Setup {
  final db = openTestDatabase();
  late final courses = CourseRepository(db);
  late final templates = TemplateRepository(db);
  late final container = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db),
    wakelockProvider.overrideWithValue(FakeWakelock()),
  ]);

  Future<int> addCourse(WidgetTester tester, String name, {int length = 1000}) async => (await tester.runAsync(
        () => courses.create(name, CourseDefinition.single(axis: CourseAxis.distance, length: length)),
      ))!;

  Future<void> pump(WidgetTester tester, {Widget home = const TemplatesScreen()}) async {
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: MaterialApp(home: home)));
    await settle(tester);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pumpAndSettle();
    }
  }
}

void main() {
  testWidgets('lists templates with course and laps', (tester) async {
    final setup = _Setup();
    final id = await setup.addCourse(tester, 'Seerunde');
    await tester.runAsync(() async {
      await setup.templates.create('Seerunde x3', courseId: id, laps: 3);
      await setup.templates.create('Seerunde offen', courseId: id, laps: null);
    });
    await setup.pump(tester);

    expect(find.text('Seerunde x3'), findsOneWidget);
    expect(find.text('Seerunde · 3 Runden'), findsOneWidget);
    expect(find.text('Seerunde · offen'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('creates a template with a fixed and one with an open number of laps', (tester) async {
    final setup = _Setup();
    await setup.addCourse(tester, 'Seerunde');
    await setup.pump(tester);
    expect(find.text('Noch keine Vorlagen angelegt.'), findsOneWidget);

    Future<void> create(String name, {String? laps, bool open = false}) async {
      await tester.tap(find.text('Vorlage anlegen'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('template-name')), name);
      await tester.tap(find.byKey(const Key('template-course')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Seerunde · 1000 m · frei').last);
      await tester.pumpAndSettle();
      if (open) await tester.tap(find.text('Offene Rundenzahl'));
      if (laps != null) await tester.enterText(find.byKey(const Key('template-laps')), laps);
      await tester.pump();
      await tester.tap(find.byTooltip('Speichern'));
      await setup.settle(tester);
    }

    await create('Seerunde x3', laps: '3');
    await create('Seerunde offen', open: true);

    expect(find.text('Seerunde · 3 Runden'), findsOneWidget);
    expect(find.text('Seerunde · offen'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('does not save a template without course and laps', (tester) async {
    final setup = _Setup();
    await setup.addCourse(tester, 'Seerunde');
    await setup.pump(tester);

    await tester.tap(find.text('Vorlage anlegen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('template-laps')), '0');
    await tester.tap(find.byTooltip('Speichern'));
    await setup.settle(tester);

    expect(find.text('Der Name fehlt.'), findsOneWidget);
    expect(find.text('Wähle eine Strecke.'), findsOneWidget);
    expect(find.text('Die Rundenzahl muss mindestens 1 sein.'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('changes the laps of a template', (tester) async {
    final setup = _Setup();
    final id = await setup.addCourse(tester, 'Seerunde');
    await tester.runAsync(() => setup.templates.create('Seerunde x3', courseId: id, laps: 3));
    await setup.pump(tester);

    await tester.tap(find.byTooltip('Aktionen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bearbeiten'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('template-laps')), '4');
    await tester.tap(find.byTooltip('Speichern'));
    await setup.settle(tester);

    expect(find.text('Seerunde · 4 Runden'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('offers to create a course first when there is none', (tester) async {
    final setup = _Setup();
    await setup.pump(tester);

    expect(find.text('Für eine Vorlage brauchst du zuerst eine Strecke.'), findsOneWidget);
    await tester.tap(find.text('Vorlage anlegen'));
    await tester.pumpAndSettle();
    expect(find.text('Zuerst eine Strecke anlegen'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Strecke anlegen')));
    await tester.pumpAndSettle();

    expect(find.text('Neue Strecke'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('is reached from the start screen', (tester) async {
    final setup = _Setup();
    await setup.pump(tester, home: const StartScreen());

    await tester.tap(find.text('Vorlage rudern'));
    await setup.settle(tester);
    await tester.tap(find.text('Strecken'));
    await setup.settle(tester);
    expect(find.text('Noch keine Strecken angelegt.'), findsOneWidget);
    await tester.tap(find.text('Zonen'));
    await setup.settle(tester);

    expect(find.textContaining('Noch keine Zonen angelegt.'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('starts a template with the simulator', (tester) async {
    final setup = _Setup();
    final id = await setup.addCourse(tester, 'Seerunde');
    await tester.runAsync(() => setup.templates.create('Seerunde x3', courseId: id, laps: 3));
    await setup.pump(tester);

    await tester.tap(find.text('Seerunde x3'));
    await tester.pumpAndSettle();
    expect(find.text('„Seerunde x3“ rudern'), findsOneWidget);
    await tester.tap(find.text('Simulator'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(setup.container.read(activeErgSourceProvider)?.kind, ErgSourceKind.simulator);
    expect(find.text('Runde 1 von 3'), findsOneWidget);
    expect(find.text('Session beenden'), findsOneWidget);
    expect(setup.container.read(sessionRecorderProvider)?.template?.name, 'Seerunde x3');

    await setup.container.read(sessionRecorderProvider.notifier).stop();
    await setup.container.read(activeErgSourceProvider.notifier).clear();
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('shows the summary when the last lap is done', (tester) async {
    final setup = _Setup();
    final id = await setup.addCourse(tester, 'Sprint', length: 100);
    await tester.runAsync(() => setup.templates.create('Sprint x3', courseId: id, laps: 3));
    await setup.pump(tester);

    await tester.tap(find.text('Sprint x3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simulator'));
    // 3 × 100 m at 2:10 /500 m take 78 s.
    for (var i = 0; i < 90 * 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(setup.container.read(sessionRecorderProvider), isNull);
    expect(find.byType(SessionSummaryScreen), findsOneWidget);
    expect(find.text('Sprint · 100 m'), findsOneWidget);
    expect(find.byKey(const Key('lap-best')), findsOneWidget);
    expect(find.text('Runde 3'), findsOneWidget);

    await setup.container.read(activeErgSourceProvider.notifier).clear();
    await disposeWidgetsWithDatabase(tester);
  });

  group('across the tabs', () {
    Future<void> createZone(WidgetTester tester, _Setup setup, String name) async {
      await tester.tap(find.text('Zonen'));
      await setup.settle(tester);
      await tester.tap(find.text('Zone anlegen'));
      await setup.settle(tester);
      await tester.enterText(find.byKey(const Key('zone-name')), name);
      await tester.enterText(find.byKey(const Key('zone-length')), '100');
      await tester.enterText(find.byKey(const Key('zone-spm-min')), '20');
      await tester.enterText(find.byKey(const Key('zone-spm-max')), '22');
      await tester.tap(find.byTooltip('Speichern'));
      await setup.settle(tester);
    }

    Future<void> openPlaceDialog(WidgetTester tester, _Setup setup) async {
      await tester.tap(find.text('Strecken'));
      await setup.settle(tester);
      await tester.tap(find.text('Strecke anlegen'));
      await setup.settle(tester);
      await tester.enterText(find.byKey(const Key('course-length')), '2000');
      await tester.pump();
      await tester.tap(find.text('Zone einbauen'));
      await setup.settle(tester);
    }

    testWidgets('offers every zone created in the zones tab when placing', (tester) async {
      final setup = _Setup();
      await setup.pump(tester);

      await createZone(tester, setup, 'Sprint');
      await openPlaceDialog(tester, setup);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Sprint')), findsOneWidget);
      await tester.tap(find.text('Abbrechen'));
      await setup.settle(tester);
      await tester.pageBack();
      await setup.settle(tester);

      await createZone(tester, setup, 'Ausdauer');
      await openPlaceDialog(tester, setup);

      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Sprint')), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Ausdauer')), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('places zones created right in the dialog one after the other', (tester) async {
      final setup = _Setup();
      await setup.pump(tester);
      await tester.tap(find.text('Strecken'));
      await setup.settle(tester);
      await tester.tap(find.text('Strecke anlegen'));
      await setup.settle(tester);
      await tester.enterText(find.byKey(const Key('course-name')), 'Intervall');
      await tester.enterText(find.byKey(const Key('course-length')), '2000');
      await tester.pump();

      for (final (name, start) in [('Sprint', '500'), ('Ausdauer', '1000')]) {
        await tester.tap(find.text('Zone einbauen'));
        await setup.settle(tester);
        await tester.tap(find.text('Neue Zone anlegen'));
        await setup.settle(tester);
        await tester.enterText(find.byKey(const Key('zone-name')), name);
        await tester.enterText(find.byKey(const Key('zone-length')), '100');
        await tester.enterText(find.byKey(const Key('zone-spm-min')), '20');
        await tester.enterText(find.byKey(const Key('zone-spm-max')), '22');
        await tester.tap(find.byTooltip('Speichern'));
        await setup.settle(tester);
        await tester.enterText(find.byKey(const Key('place-start')), start);
        await tester.pump();
        await tester.tap(find.text('Einbauen'));
        await setup.settle(tester);
      }
      await tester.tap(find.byTooltip('Speichern'));
      await setup.settle(tester);

      expect(find.text('2000 m · Sprint, Ausdauer'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('offers a course created in the courses tab for a new template', (tester) async {
      final setup = _Setup();
      await setup.addCourse(tester, 'Seerunde');
      await setup.pump(tester);

      await tester.tap(find.text('Strecken'));
      await setup.settle(tester);
      await tester.tap(find.text('Strecke anlegen'));
      await setup.settle(tester);
      await tester.enterText(find.byKey(const Key('course-name')), 'Sprintstrecke');
      await tester.enterText(find.byKey(const Key('course-length')), '500');
      await tester.tap(find.byTooltip('Speichern'));
      await setup.settle(tester);
      await tester.tap(find.text('Vorlagen'));
      await setup.settle(tester);
      await tester.tap(find.text('Vorlage anlegen'));
      await setup.settle(tester);
      await tester.tap(find.byKey(const Key('template-course')));
      await setup.settle(tester);

      expect(find.text('Sprintstrecke · 500 m · frei'), findsWidgets);
      await disposeWidgetsWithDatabase(tester);
    });
  });
}
