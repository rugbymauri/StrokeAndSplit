import 'package:strokesplit/app/widgets/oar_stepper.dart';
import 'package:strokesplit/data/sessions/session_plan.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sources/erg_source_providers.dart';
import 'package:strokesplit/features/courses/course_detail_screen.dart';
import 'package:strokesplit/features/courses/course_start_screen.dart';
import 'package:strokesplit/features/courses/course_strip.dart';
import 'package:strokesplit/features/courses/courses_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/template_setup.dart';
import '../../support/test_database.dart';

const _laps = Key('course-start-laps');
const _duration = Key('course-start-duration');
const _openHint = Key('course-start-open-hint');

/// The start screen of a course (course-rowing-free, Design D6).
void main() {
  /// "Seerunde" in the list of courses, its detail and its start screen opened.
  Future<TemplateSetup> openStart(
    WidgetTester tester, {
    Locale locale = const Locale('de'),
  }) async {
    final setup = TemplateSetup();
    await setup.addCourseWithZone(tester, 'Seerunde');
    await setup.pump(tester, home: const CoursesScreen(), locale: locale);
    await tester.tap(find.text('Seerunde'));
    await setup.settle(tester);
    await tester.tap(find.byKey(const Key('course-row')));
    await setup.settle(tester);
    return setup;
  }

  OarStepper stepper(WidgetTester tester, Key key) =>
      tester.widget<OarStepper>(find.byKey(key));

  Future<void> choose(WidgetTester tester, String option) async {
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('course-start-length')),
        matching: find.text(option),
      ),
    );
    await tester.pump();
  }

  /// Sets the stepper with [key] to [value] as holding a blade would.
  Future<void> setTo(WidgetTester tester, Key key, int value) async {
    stepper(tester, key).onChanged(value);
    await tester.pump();
  }

  /// Starts and rows on with the simulator until the live display has started.
  Future<void> start(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('course-start-start')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> stopRowing(TemplateSetup setup) async {
    await setup.container.read(sessionRecorderProvider.notifier).stop();
    await setup.container.read(activeErgSourceProvider.notifier).clear();
  }

  testWidgets(
    '"Rudern" opens the start screen of the course, back leads to its detail',
    (tester) async {
      await openStart(tester);

      expect(find.byType(CourseStartScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Seerunde'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CourseStartScreen),
          matching: find.byType(CourseStrip),
        ),
        findsOneWidget,
      );
      expect(find.text('1000 m · Tempo'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(CourseStartScreen), findsNothing);
      expect(find.byType(CourseDetailScreen), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    },
  );

  testWidgets(
    'opens with 3 laps and shows only the input of the chosen option',
    (tester) async {
      await openStart(tester);

      expect(stepper(tester, _laps).value, 3);
      expect(find.text('Runden'), findsWidgets);
      expect(find.byKey(_duration), findsNothing);
      expect(find.byKey(_openHint), findsNothing);

      await choose(tester, 'Dauer');
      expect(find.byKey(_laps), findsNothing);
      expect(stepper(tester, _duration).value, 30);
      expect(find.text('30:00'), findsOneWidget);

      await choose(tester, 'Offen');
      expect(find.byKey(_laps), findsNothing);
      expect(find.byKey(_duration), findsNothing);
      expect(
        find.text('Du ruderst, bis du die Session beendest.'),
        findsOneWidget,
      );
      await disposeWidgetsWithDatabase(tester);
    },
  );

  testWidgets('keeps the values of the options when switching between them', (
    tester,
  ) async {
    await openStart(tester);

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.bySemanticsLabel('1 Runde mehr'));
      await tester.pump();
    }
    await choose(tester, 'Dauer');
    await tester.tap(find.bySemanticsLabel('1 Minute weniger'));
    await tester.pump();
    await choose(tester, 'Runden');
    expect(stepper(tester, _laps).value, 5);
    await choose(tester, 'Dauer');
    expect(stepper(tester, _duration).value, 29);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets(
    'locks the steps below 1 lap, below 1 minute and above 180 minutes',
    (tester) async {
      await openStart(tester);

      await setTo(tester, _laps, 1);
      expect(stepper(tester, _laps).canDecrease, isFalse);
      await tester.tap(find.bySemanticsLabel('1 Runde weniger'));
      await tester.pump();
      expect(stepper(tester, _laps).value, 1);

      await choose(tester, 'Dauer');
      await setTo(tester, _duration, 1);
      expect(
        (
          stepper(tester, _duration).canDecrease,
          stepper(tester, _duration).canIncrease,
        ),
        (false, true),
      );
      expect(find.text('1:00'), findsOneWidget);
      await setTo(tester, _duration, 180);
      expect(
        (
          stepper(tester, _duration).canDecrease,
          stepper(tester, _duration).canIncrease,
        ),
        (true, false),
      );
      expect(find.text('3:00:00'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    },
  );

  testWidgets('shows 90 minutes as 1:30:00', (tester) async {
    await openStart(tester);

    await choose(tester, 'Dauer');
    await setTo(tester, _duration, 89);
    await tester.tap(find.bySemanticsLabel('1 Minute mehr'));
    await tester.pump();

    expect(find.text('1:30:00'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('starts 30 minutes on the course without creating a template', (
    tester,
  ) async {
    final setup = await openStart(tester);

    await choose(tester, 'Dauer');
    await start(tester);

    final recording = setup.container.read(sessionRecorderProvider)!;
    expect(recording.plan!.course.name, 'Seerunde');
    expect(recording.plan!.length, const TimeLimit(Duration(minutes: 30)));
    expect((recording.plan!.template, recording.ghost), (null, true));
    expect(find.text('Runde 1'), findsOneWidget);
    expect(await tester.runAsync(setup.templates.all), isEmpty);
    await stopRowing(setup);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets(
    'starts laps and open with the ghost off, and opens with the defaults again',
    (tester) async {
      final setup = await openStart(tester);
      await tester.tap(find.text('Gegen den Ghost rudern'));
      await tester.pump();
      await setTo(tester, _laps, 5);
      await start(tester);

      var recording = setup.container.read(sessionRecorderProvider)!;
      expect(
        (recording.plan!.length, recording.ghost),
        (const LapCount(5), false),
      );
      expect(find.text('Runde 1 / 5'), findsOneWidget);
      await stopRowing(setup);

      // Back to the list of courses and on to the start screen of "Seerunde" again.
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .popUntil((route) => route.isFirst);
      await setup.settle(tester);
      await tester.tap(find.text('Seerunde'));
      await setup.settle(tester);
      await tester.tap(find.byKey(const Key('course-row')));
      await setup.settle(tester);
      expect(stepper(tester, _laps).value, 3);
      final ghost = find.descendant(
        of: find.byKey(const Key('course-start-ghost')),
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(ghost).value, isTrue);

      await choose(tester, 'Offen');
      await start(tester);
      recording = setup.container.read(sessionRecorderProvider)!;
      expect(
        (recording.plan!.length, recording.ghost),
        (const OpenLength(), true),
      );
      await stopRowing(setup);
      await disposeWidgetsWithDatabase(tester);
    },
  );

  testWidgets('speaks English', (tester) async {
    await openStart(tester, locale: const Locale('en'));

    expect(find.text('Laps'), findsWidgets);
    expect(find.text('Row against the ghost'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    await choose(tester, 'Duration');
    expect(find.text('30:00'), findsOneWidget);
    await choose(tester, 'Open');
    expect(find.text('You row until you end the session.'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Row'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  for (final MapEntry(key: name, value: size) in const {
    'portrait': Size(390, 844),
    'landscape': Size(844, 390),
  }.entries) {
    testWidgets('fits without overflow and keeps "Starten" in view, $name', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await openStart(tester);

      for (final option in ['Runden', 'Dauer', 'Offen']) {
        await choose(tester, option);
        expect(tester.takeException(), isNull, reason: option);
        expect(
          find.byKey(const Key('course-start-start')).hitTestable(),
          findsOneWidget,
          reason: option,
        );
        expect(
          find.byKey(const Key('course-start-ghost')).hitTestable(),
          findsOneWidget,
          reason: option,
        );
      }
      await disposeWidgetsWithDatabase(tester);
    });
  }
}
