import 'package:strokesplit/app/widgets/oar_stepper.dart';
import 'package:strokesplit/features/connection/start_screen.dart';
import 'package:strokesplit/features/templates/template_editor_screen.dart';
import 'package:strokesplit/features/templates/template_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oar_steppers.dart';
import '../../support/template_setup.dart';
import '../../support/test_database.dart';

void main() {
  testWidgets('lists templates with course and laps', (tester) async {
    final setup = TemplateSetup();
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

  testWidgets(
    'creates a template with a fixed and one with an open number of laps',
    (tester) async {
      final setup = TemplateSetup();
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
    },
  );

  testWidgets('does not save a template without name and course', (
    tester,
  ) async {
    final setup = TemplateSetup();
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
    final setup = TemplateSetup();
    await setup.addCourse(tester, 'Seerunde');
    await setup.pump(
      tester,
      home: const TemplateEditorScreen(),
      locale: const Locale('en'),
    );

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
    final setup = TemplateSetup();
    final id = await setup.addCourse(tester, 'Seerunde');
    await tester.runAsync(
      () => setup.templates.create('Seerunde x3', courseId: id, laps: 3),
    );
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

  testWidgets(
    'opens a template on its own screen instead of opening the card',
    (tester) async {
      final setup = TemplateSetup();
      final course = await setup.addCourseWithZone(tester, 'Seerunde');
      final x3 = await setup.addTemplate(
        tester,
        'Seerunde x3',
        courseId: course,
      );
      await setup.addTemplate(
        tester,
        'Seerunde offen',
        courseId: course,
        laps: null,
      );
      await setup.pump(tester);

      // No card shows zones, places or "Starten".
      expect(find.text('Tempo 2:05–2:10 · 20–22 spm'), findsNothing);
      expect(find.text('Starten'), findsNothing);
      expect(find.byTooltip('Vorlage bearbeiten'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(Key('template-$x3')),
          matching: find.byIcon(Icons.chevron_right),
        ),
        findsOneWidget,
      );

      await setup.openTemplate(tester, 'Seerunde x3');
      expect(find.byType(TemplateScreen), findsOneWidget);
      expect(find.text('Starten'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    },
  );

  group('number of laps', () {
    Future<TemplateSetup> openEditor(
      WidgetTester tester, {
      int? laps = 3,
    }) async {
      final setup = TemplateSetup();
      final id = await setup.addCourse(tester, 'Seerunde');
      await tester.runAsync(
        () => setup.templates.create('Seerunde', courseId: id, laps: laps),
      );
      final template = (await tester.runAsync(setup.templates.all))!.single;
      await setup.pump(tester, home: TemplateEditorScreen(template: template));
      return setup;
    }

    OarStepper laps(WidgetTester tester) =>
        tester.widget<OarStepper>(find.byKey(const Key('template-laps')));

    testWidgets('counts a fixed number of laps and shows what they add up to', (
      tester,
    ) async {
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

    testWidgets('rows an open number of laps until the session ends', (
      tester,
    ) async {
      final setup = await openEditor(tester);

      await tester.tap(find.text('Offen bis Stopp'));
      await tester.pump();

      expect(find.byKey(const Key('template-laps')), findsNothing);
      expect(find.text('1000 m'), findsOneWidget);
      expect(
        find.text('pro Runde, bis du die Session beendest'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Speichern'));
      await setup.settle(tester);
      expect((await tester.runAsync(setup.templates.all))!.single.laps, isNull);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets(
      'starts an open template with three laps when it gets a fixed number',
      (tester) async {
        await openEditor(tester, laps: null);

        expect(find.byKey(const Key('template-laps')), findsNothing);
        await tester.tap(find.text('Feste Anzahl'));
        await tester.pump();

        expect(laps(tester).value, 3);
        expect(find.text('3000 m'), findsOneWidget);
        await disposeWidgetsWithDatabase(tester);
      },
    );
  });

  testWidgets('offers to create a course first when there is none', (
    tester,
  ) async {
    final setup = TemplateSetup();
    await setup.pump(tester);

    expect(
      find.text('Für eine Vorlage brauchst du zuerst eine Strecke.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Vorlage anlegen'));
    await tester.pumpAndSettle();
    expect(find.text('Zuerst eine Strecke anlegen'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Strecke anlegen'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Neue Strecke'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('is reached from the start screen', (tester) async {
    final setup = TemplateSetup();
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

  group('across the tabs', () {
    Future<void> createZone(
      WidgetTester tester,
      TemplateSetup setup,
      String name,
    ) async {
      await tester.tap(find.text('Zonen'));
      await setup.settle(tester);
      await tester.tap(find.text('Zone anlegen'));
      await setup.settle(tester);
      await tester.enterText(find.byKey(const Key('zone-name')), name);
      await tester.tap(find.byTooltip('Speichern'));
      await setup.settle(tester);
    }

    Future<void> openPlaceDialog(
      WidgetTester tester,
      TemplateSetup setup,
    ) async {
      await tester.tap(find.text('Strecken'));
      await setup.settle(tester);
      await tester.tap(find.text('Strecke anlegen'));
      await setup.settle(tester);
      await tester.tap(find.text('Zone einbauen'));
      await setup.settle(tester);
    }

    testWidgets('offers every zone created in the zones tab when placing', (
      tester,
    ) async {
      final setup = TemplateSetup();
      await setup.pump(tester);

      await createZone(tester, setup, 'Sprint');
      await openPlaceDialog(tester, setup);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Sprint'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Abbrechen'));
      await setup.settle(tester);
      await tester.tap(find.byType(BackButton));
      await setup.settle(tester);

      await createZone(tester, setup, 'Ausdauer');
      await openPlaceDialog(tester, setup);

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Sprint'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Ausdauer'),
        ),
        findsOneWidget,
      );
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets(
      'places zones created right in the dialog one after the other',
      (tester) async {
        final setup = TemplateSetup();
        // Room for the course with both zones.
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await setup.pump(tester);
        await tester.tap(find.text('Strecken'));
        await setup.settle(tester);
        await tester.tap(find.text('Strecke anlegen'));
        await setup.settle(tester);
        await tester.enterText(
          find.byKey(const Key('course-name')),
          'Intervall',
        );
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

        expect(
          find.text('Distanz · 2 Zonen · noch nie gerudert'),
          findsOneWidget,
        );
        await disposeWidgetsWithDatabase(tester);
      },
    );

    testWidgets(
      'offers a course created in the courses tab for a new template',
      (tester) async {
        final setup = TemplateSetup();
        await setup.addCourse(tester, 'Seerunde');
        await setup.pump(tester);

        await tester.tap(find.text('Strecken'));
        await setup.settle(tester);
        await tester.tap(find.text('Strecke anlegen'));
        await setup.settle(tester);
        await tester.enterText(
          find.byKey(const Key('course-name')),
          'Sprintstrecke',
        );
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
      },
    );
  });
}
