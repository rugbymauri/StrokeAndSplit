import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/app/widgets/oar_stepper.dart';
import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/data/sources/rower_choice.dart';
import 'package:aergrow/data/templates/template_repository.dart';
import 'package:aergrow/features/connection/start_screen.dart';
import 'package:aergrow/features/sessions/session_summary_screen.dart';
import 'package:aergrow/features/templates/template_editor_screen.dart';
import 'package:aergrow/features/templates/templates_screen.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/oar_steppers.dart';
import '../../support/rowed_sessions.dart';
import '../../support/test_database.dart';
import '../../support/localized_app.dart';

class _Setup {
  _Setup({this.rower = const RowerChoice.simulator()});

  final RowerChoice rower;
  final db = openTestDatabase();
  late final courses = CourseRepository(db);
  late final templates = TemplateRepository(db);
  late final container = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db),
    wakelockProvider.overrideWithValue(FakeWakelock()),
    rowerChoiceStoreProvider.overrideWithValue(MemoryRowerChoiceStore(rower)),
  ]);

  Future<int> addCourse(WidgetTester tester, String name, {int length = 1000}) async => (await tester.runAsync(
        () => courses.create(name, CourseDefinition.single(axis: CourseAxis.distance, length: length)),
      ))!;

  /// A course of 1000 m with the zone „Tempo“ from 200 to 800 m.
  Future<int> addCourseWithZone(WidgetTester tester, String name) async => (await tester.runAsync(
        () => courses.create(
          name,
          const CourseDefinition(axis: CourseAxis.distance, length: 1000, segments: [
            CourseSegment(length: 200),
            CourseSegment(length: 600, paceFastCs: 12500, paceSlowCs: 13000, spmMin: 20, spmMax: 22, zoneName: 'Tempo'),
            CourseSegment(length: 200),
          ]),
        ),
      ))!;

  Future<int> addTemplate(WidgetTester tester, String name, {required int courseId, int? laps = 3}) async =>
      (await tester.runAsync(() => templates.create(name, courseId: courseId, laps: laps)))!;

  Future<void> pump(
    WidgetTester tester, {
    Widget home = const TemplatesScreen(),
    Locale locale = const Locale('de'),
  }) async {
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: LocalizedApp(locale: locale, home: home)),
    );
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
    expect(find.text('Seerunde · 1000 m · 3 Runden'), findsOneWidget);
    expect(find.text('Seerunde · 1000 m · offen'), findsOneWidget);
    expect(find.text('Starten'), findsNothing);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('creates a template with a fixed and one with an open number of laps', (tester) async {
    final setup = _Setup();
    await setup.addCourse(tester, 'Seerunde');
    await setup.pump(tester);
    expect(find.text('Noch keine Vorlagen angelegt.'), findsOneWidget);

    Future<void> create(String name, {bool open = false}) async {
      await tester.tap(find.text('Vorlage anlegen'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('template-name')), name);
      await tester.tap(find.byKey(const Key('template-course')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Seerunde · 1000 m · frei').last);
      await tester.pumpAndSettle();
      if (open) await tester.tap(find.text('Offen bis Stopp'));
      await tester.pump();
      await tester.tap(find.byTooltip('Speichern'));
      await setup.settle(tester);
    }

    await create('Seerunde x3');
    await create('Seerunde offen', open: true);

    expect(find.text('Seerunde · 1000 m · 3 Runden'), findsOneWidget);
    expect(find.text('Seerunde · 1000 m · offen'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('does not save a template without name and course', (tester) async {
    final setup = _Setup();
    await setup.addCourse(tester, 'Seerunde');
    await setup.pump(tester);

    await tester.tap(find.text('Vorlage anlegen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Speichern'));
    await setup.settle(tester);

    expect(find.text('Der Name fehlt.'), findsOneWidget);
    expect(find.text('Wähle eine Strecke.'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('shows the editor in English', (tester) async {
    final setup = _Setup();
    await setup.addCourse(tester, 'Seerunde');
    await setup.pump(tester, home: const TemplateEditorScreen(), locale: const Locale('en'));

    expect(find.text('New template'), findsOneWidget);
    expect(find.text('Fixed number'), findsOneWidget);
    expect(find.text('Open until stop'), findsOneWidget);
    expect(find.text('laps'), findsOneWidget);
    expect(find.bySemanticsLabel('1 lap more'), findsOneWidget);
    await tester.tap(find.byTooltip('Save'));
    await setup.settle(tester);

    expect(find.text('The name is missing.'), findsOneWidget);
    expect(find.text('Choose a course.'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('changes the laps of a template', (tester) async {
    final setup = _Setup();
    final id = await setup.addCourse(tester, 'Seerunde');
    await tester.runAsync(() => setup.templates.create('Seerunde x3', courseId: id, laps: 3));
    await setup.pump(tester);

    await tester.tap(find.text('Seerunde x3'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Vorlage bearbeiten'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('1 Runde mehr'));
    await tester.pump();
    await tester.tap(find.byTooltip('Speichern'));
    await setup.settle(tester);

    expect(find.text('Seerunde · 1000 m · 4 Runden'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  group('choosing a template', () {
    Finder inCard(int id, Finder finder) => find.descendant(of: find.byKey(Key('template-$id')), matching: finder);

    testWidgets('opens a template with its bands and closes it again', (tester) async {
      final setup = _Setup();
      final course = await setup.addCourseWithZone(tester, 'Seerunde');
      final x3 = await setup.addTemplate(tester, 'Seerunde x3', courseId: course);
      final open = await setup.addTemplate(tester, 'Seerunde offen', courseId: course, laps: null);
      await setup.pump(tester);

      expect(find.text('Starten'), findsNothing);
      expect(find.byTooltip('Vorlage bearbeiten'), findsNothing);
      await tester.tap(find.text('Seerunde x3'));
      await tester.pumpAndSettle();

      expect(inCard(x3, find.text('Tempo 2:05–2:10 · 20–22 spm')), findsOneWidget);
      expect(inCard(x3, find.text('Starten')), findsOneWidget);
      expect(inCard(x3, find.byTooltip('Vorlage bearbeiten')), findsOneWidget);

      // Choosing another template closes the first.
      await tester.tap(find.text('Seerunde offen'));
      await tester.pumpAndSettle();
      expect(inCard(x3, find.text('Starten')), findsNothing);
      expect(inCard(open, find.text('Starten')), findsOneWidget);

      await tester.tap(find.text('Seerunde offen'));
      await tester.pumpAndSettle();
      expect(find.text('Starten'), findsNothing);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('says that a course without zones is rowed freely', (tester) async {
      final setup = _Setup();
      final course = await setup.addCourse(tester, 'Seerunde');
      await setup.addTemplate(tester, 'Seerunde x3', courseId: course);
      await setup.pump(tester);

      await tester.tap(find.text('Seerunde x3'));
      await tester.pumpAndSettle();

      expect(find.text('ohne Zonen'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('shows the template chosen with "Nochmal" opened and in view', (tester) async {
      final setup = _Setup();
      final course = await setup.addCourseWithZone(tester, 'Seerunde');
      final ids = [
        for (var i = 1; i <= 8; i++) await setup.addTemplate(tester, 'Vorlage $i', courseId: course),
      ];
      await setup.pump(tester, home: TemplatesScreen(selectedTemplateId: ids.last));

      expect(inCard(ids.last, find.text('Starten')).hitTestable(), findsOneWidget);
      expect(find.text('Starten'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('starts the opened template with the chosen FTMS simulator', (tester) async {
      final setup = _Setup(rower: const RowerChoice.simulator(ErgProtocol.ftms));
      final course = await setup.addCourseWithZone(tester, 'Seerunde');
      await setup.addTemplate(tester, 'Seerunde x3', courseId: course);
      await setup.addTemplate(tester, 'Seerunde offen', courseId: course, laps: null);
      await setup.pump(tester);

      await tester.tap(find.text('Seerunde x3'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Starten'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      final source = setup.container.read(activeErgSourceProvider);
      expect((source?.kind, source?.protocol), (ErgSourceKind.simulator, ErgProtocol.ftms));
      expect(setup.container.read(sessionRecorderProvider)?.template?.name, 'Seerunde x3');
      expect(find.text('Runde 1 / 3'), findsOneWidget);

      await setup.container.read(sessionRecorderProvider.notifier).stop();
      await setup.container.read(activeErgSourceProvider.notifier).clear();
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('deletes a template in its editor', (tester) async {
      final setup = _Setup();
      final course = await setup.addCourse(tester, 'Seerunde');
      await setup.addTemplate(tester, 'Seerunde x3', courseId: course);
      await setup.pump(tester);

      await tester.tap(find.text('Seerunde x3'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Vorlage bearbeiten'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Löschen'));
      await tester.pumpAndSettle();
      expect(find.text('Vorlage löschen?'), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Löschen')));
      await setup.settle(tester);

      expect(find.byType(TemplatesScreen), findsOneWidget);
      expect(find.text('Seerunde x3'), findsNothing);
      expect(find.text('Noch keine Vorlagen angelegt.'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('shows the opened template in English', (tester) async {
      final setup = _Setup();
      final course = await setup.addCourseWithZone(tester, 'Seerunde');
      final id = await setup.addTemplate(tester, 'Seerunde x3', courseId: course);
      await setup.pump(tester, home: TemplatesScreen(selectedTemplateId: id), locale: const Locale('en'));

      expect(find.text('Templates'), findsOneWidget);
      expect(find.text('Seerunde · 1000 m · 3 laps'), findsOneWidget);
      expect(find.text('Tempo 2:05–2:10 · 20–22 spm'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.byTooltip('Edit template'), findsOneWidget);
      expect(find.text('New template'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });
  });

  group('number of laps', () {
    Future<_Setup> openEditor(WidgetTester tester, {int? laps = 3}) async {
      final setup = _Setup();
      final id = await setup.addCourse(tester, 'Seerunde');
      await tester.runAsync(() => setup.templates.create('Seerunde', courseId: id, laps: laps));
      final template = (await tester.runAsync(setup.templates.all))!.single;
      await setup.pump(tester, home: TemplateEditorScreen(template: template));
      return setup;
    }

    OarStepper laps(WidgetTester tester) => tester.widget<OarStepper>(find.byKey(const Key('template-laps')));

    testWidgets('counts a fixed number of laps and shows what they add up to', (tester) async {
      final setup = await openEditor(tester, laps: 2);

      expect(laps(tester).value, 2);
      expect(find.text('Runden'), findsWidgets);
      expect(find.text('2000 m'), findsOneWidget);
      expect(find.text('2 × 1000 m'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('1 Runde weniger'));
      await tester.pump();
      expect(laps(tester).value, 1);
      expect(find.text('Runde'), findsOneWidget);
      expect(find.text('1000 m'), findsOneWidget);

      // Not below one lap.
      expect(laps(tester).canDecrease, isFalse);
      await tester.tap(find.bySemanticsLabel('1 Runde weniger'));
      await tester.pump();
      expect(laps(tester).value, 1);

      for (var i = 0; i < 2; i++) {
        await tester.tap(find.bySemanticsLabel('1 Runde mehr'));
        await tester.pump();
      }
      expect(find.text('3000 m'), findsOneWidget);
      await tester.tap(find.byTooltip('Speichern'));
      await setup.settle(tester);

      expect((await tester.runAsync(setup.templates.all))!.single.laps, 3);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('rows an open number of laps until the session ends', (tester) async {
      final setup = await openEditor(tester);

      await tester.tap(find.text('Offen bis Stopp'));
      await tester.pump();

      expect(find.byKey(const Key('template-laps')), findsNothing);
      expect(find.text('1000 m'), findsOneWidget);
      expect(find.text('pro Runde, bis du die Session beendest'), findsOneWidget);
      await tester.tap(find.byTooltip('Speichern'));
      await setup.settle(tester);
      expect((await tester.runAsync(setup.templates.all))!.single.laps, isNull);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('starts an open template with three laps when it gets a fixed number', (tester) async {
      await openEditor(tester, laps: null);

      expect(find.byKey(const Key('template-laps')), findsNothing);
      await tester.tap(find.text('Feste Anzahl'));
      await tester.pump();

      expect(laps(tester).value, 3);
      expect(find.text('3000 m'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });
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

    await tester.tap(find.text('Rudern'));
    await setup.settle(tester);
    await tester.tap(find.text('Strecken'));
    await setup.settle(tester);
    expect(find.text('Noch keine Strecken angelegt.'), findsOneWidget);
    await tester.tap(find.text('Zonen'));
    await setup.settle(tester);

    expect(find.textContaining('Noch keine Zonen angelegt.'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('starts a template with the chosen simulator without asking for the source', (tester) async {
    final setup = _Setup();
    final id = await setup.addCourse(tester, 'Seerunde');
    await tester.runAsync(() => setup.templates.create('Seerunde x3', courseId: id, laps: 3));
    await setup.pump(tester);

    await tester.tap(find.text('Seerunde x3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Starten'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.byType(SimpleDialog), findsNothing);
    expect(setup.container.read(activeErgSourceProvider)?.kind, ErgSourceKind.simulator);
    expect(find.text('Runde 1 / 3'), findsOneWidget);
    expect(find.text('Beenden'), findsOneWidget);
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
    await tester.tap(find.text('Starten'));
    // 3 × 100 m at 2:10 /500 m take 78 s.
    for (var i = 0; i < 90 * 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(setup.container.read(sessionRecorderProvider), isNull);
    expect(find.byType(SessionSummaryScreen), findsOneWidget);
    expect(find.textContaining('3 × 100 m'), findsOneWidget);
    expect(find.byKey(const Key('lap-best')), findsOneWidget);
    expect(find.byKey(const Key('lap-value')), findsNWidgets(3));

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
      await tester.tap(find.byTooltip('Speichern'));
      await setup.settle(tester);
    }

    Future<void> openPlaceDialog(WidgetTester tester, _Setup setup) async {
      await tester.tap(find.text('Strecken'));
      await setup.settle(tester);
      await tester.tap(find.text('Strecke anlegen'));
      await setup.settle(tester);
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
      await tester.tap(find.byType(BackButton));
      await setup.settle(tester);

      await createZone(tester, setup, 'Ausdauer');
      await openPlaceDialog(tester, setup);

      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Sprint')), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Ausdauer')), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('places zones created right in the dialog one after the other', (tester) async {
      final setup = _Setup();
      // Room for the course with both zones.
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await setup.pump(tester);
      await tester.tap(find.text('Strecken'));
      await setup.settle(tester);
      await tester.tap(find.text('Strecke anlegen'));
      await setup.settle(tester);
      await tester.enterText(find.byKey(const Key('course-name')), 'Intervall');
      await tester.pump();

      for (final (name, start) in [('Sprint', 500), ('Ausdauer', 1000)]) {
        await tester.tap(find.text('Zone einbauen'));
        await setup.settle(tester);
        await tester.tap(find.text('Neue Zone anlegen'));
        await setup.settle(tester);
        await tester.enterText(find.byKey(const Key('zone-name')), name);
        await tester.tap(find.byTooltip('Speichern'));
        await setup.settle(tester);
        await stepTo(tester, const Key('place-start'), start);
        await tester.tap(find.text('Einbauen'));
        await setup.settle(tester);
      }
      await tester.tap(find.byTooltip('Speichern'));
      await setup.settle(tester);

      expect(find.text('Distanz · 2 Zonen · noch nie gerudert'), findsOneWidget);
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
      await tester.tap(find.byTooltip('Speichern'));
      await setup.settle(tester);
      await tester.tap(find.text('Vorlagen'));
      await setup.settle(tester);
      await tester.tap(find.text('Vorlage anlegen'));
      await setup.settle(tester);
      await tester.tap(find.byKey(const Key('template-course')));
      await setup.settle(tester);

      expect(find.text('Sprintstrecke · 2000 m · frei'), findsWidgets);
      await disposeWidgetsWithDatabase(tester);
    });
  });

  group('places of a template', () {
    Finder inCard(int id, Finder finder) => find.descendant(of: find.byKey(Key('template-$id')), matching: finder);
    Finder inPlace(int place, String text) =>
        find.descendant(of: find.byKey(Key('template-place-$place')), matching: find.text(text));

    testWidgets('shows places 1 and 2 with time, pace and date after two sessions', (tester) async {
      final setup = _Setup();
      final course = await setup.addCourse(tester, 'Seerunde');
      final id = await setup.addTemplate(tester, 'Seerunde x3', courseId: course);
      await tester.runAsync(() async {
        final x3 = (await setup.templates.get(id))!;
        await storeRowedSession(setup.db, template: x3, startedAt: DateTime(2026, 10, 1, 7), laps: [
          for (var i = 0; i < 3; i++) RowedLap.single(250000, 1000),
        ]);
        await storeRowedSession(setup.db, template: x3, startedAt: DateTime(2026, 10, 3, 7), laps: [
          for (var i = 0; i < 3; i++) RowedLap.single(248000, 1000),
        ]);
      });
      await setup.pump(tester);

      expect(find.byKey(const Key('template-podium')), findsNothing);
      await tester.tap(find.text('Seerunde x3'));
      await setup.settle(tester);

      expect(inCard(id, find.text('BESTLEISTUNGEN')), findsOneWidget);
      expect(inPlace(1, '12:24.0'), findsOneWidget);
      expect(inPlace(1, '2:04.0 /500 m'), findsOneWidget);
      expect(inPlace(1, '3.10.2026'), findsOneWidget);
      expect(inPlace(2, '12:30.0'), findsOneWidget);
      expect(inPlace(2, '2:05.0 /500 m'), findsOneWidget);
      expect(inPlace(2, '1.10.2026'), findsOneWidget);
      expect(find.byKey(const Key('template-place-3')), findsNothing);
      expect(find.byKey(const Key('template-podium-hint')), findsNothing);
      // Place 1 keeps room for the ghost symbol.
      final ghostSlot = find.byKey(const Key('template-ghost-slot'));
      expect(find.descendant(of: find.byKey(const Key('template-place-1')), matching: ghostSlot), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('says that a template never rowed has no best time yet', (tester) async {
      final setup = _Setup();
      final course = await setup.addCourse(tester, 'Seerunde');
      final id = await setup.addTemplate(tester, 'Seerunde x3', courseId: course);
      await setup.pump(tester);

      await tester.tap(find.text('Seerunde x3'));
      await setup.settle(tester);

      expect(
        inCard(id, find.text('Noch keine Bestzeit. Es zählen Sessions mit allen Runden an einem Rudergerät.')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('template-podium')), findsNothing);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('shows no places for an open number of laps', (tester) async {
      final setup = _Setup();
      final course = await setup.addCourse(tester, 'Seerunde');
      final id = await setup.addTemplate(tester, 'Seerunde offen', courseId: course, laps: null);
      await tester.runAsync(() async {
        final open = (await setup.templates.get(id))!;
        await storeRowedSession(setup.db, template: open, laps: [RowedLap.single(250000, 1000)]);
      });
      await setup.pump(tester);

      await tester.tap(find.text('Seerunde offen'));
      await setup.settle(tester);

      expect(inCard(id, find.text('Bei offener Rundenzahl gibt es keine Bestzeit.')), findsOneWidget);
      expect(find.byKey(const Key('template-podium')), findsNothing);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('shows the hint when only a simulated session was rowed', (tester) async {
      final setup = _Setup();
      final course = await setup.addCourse(tester, 'Seerunde');
      final id = await setup.addTemplate(tester, 'Seerunde x1', courseId: course, laps: 1);
      await tester.runAsync(() async {
        final x1 = (await setup.templates.get(id))!;
        await storeRowedSession(setup.db, template: x1, source: ErgSourceKind.simulator, laps: [
          RowedLap.single(250000, 1000),
        ]);
      });
      await setup.pump(tester);

      await tester.tap(find.text('Seerunde x1'));
      await setup.settle(tester);

      expect(find.byKey(const Key('template-podium-hint')), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('shows the places in English', (tester) async {
      final setup = _Setup();
      final course = await setup.addCourse(tester, 'Seerunde');
      final id = await setup.addTemplate(tester, 'Seerunde x1', courseId: course, laps: 1);
      await tester.runAsync(() async {
        final x1 = (await setup.templates.get(id))!;
        await storeRowedSession(setup.db, template: x1, startedAt: DateTime(2026, 10, 3, 7), laps: [
          RowedLap.single(250000, 1000),
        ]);
      });
      await setup.pump(tester, locale: const Locale('en'));

      await tester.tap(find.text('Seerunde x1'));
      await setup.settle(tester);

      expect(find.text('BEST RESULTS'), findsOneWidget);
      expect(inPlace(1, '4:10.0'), findsOneWidget);
      expect(inPlace(1, '10/3/2026'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });
  });
}
