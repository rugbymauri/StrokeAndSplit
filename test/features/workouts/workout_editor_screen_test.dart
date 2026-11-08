import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sources/erg_source_providers.dart';
import 'package:strokesplit/features/live/live_screen.dart';
import 'package:strokesplit/data/sessions/session_plan.dart';
import 'package:strokesplit/features/workouts/workout_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oar_steppers.dart';
import '../../support/test_database.dart';
import '../../support/workout_setup.dart';

/// The workout editor with several courses in a row (Change
/// workout-course-chain, Design D8).
void main() {
  late WorkoutSetup setup;
  late int einrudern;
  late int intervall;
  late int ausrudern;
  late int vierMinuten;

  Future<void> addCourses(WidgetTester tester) async {
    setup = WorkoutSetup();
    einrudern = await setup.addCourse(tester, 'Einrudern', length: 500);
    intervall = await setup.addCourse(tester, '2 km Intervall', length: 2000);
    ausrudern = await setup.addCourse(tester, 'Ausrudern', length: 500);
    vierMinuten = (await tester.runAsync(
      () => setup.courses.create(
        'Vier Minuten',
        CourseDefinition.single(axis: CourseAxis.time, length: 240),
      ),
    ))!;
  }

  /// Opens the editor of a workout on [courseIds], or of a new one.
  Future<void> openEditor(
    WidgetTester tester, {
    List<int>? courseIds,
    PlanLength length = const LapCount(1),
  }) async {
    final workout = courseIds == null
        ? null
        : await tester.runAsync(
            () async => (await setup.workouts.get(
              await setup.workouts.create(
                'Intervalltraining',
                courseIds: courseIds,
                length: length,
              ),
            ))!,
          );
    await setup.pump(tester, home: WorkoutEditorScreen(workout: workout));
  }

  /// The names on the course cards from top to bottom.
  List<String> cards(WidgetTester tester) => [
    for (
      var i = 0;
      find.byKey(Key('workout-course-$i')).evaluate().isNotEmpty;
      i++
    )
      tester
          .widget<Text>(
            find
                .descendant(
                  of: find.byKey(Key('workout-course-$i')),
                  matching: find.byType(Text),
                )
                .first,
          )
          .data!,
  ];

  Future<void> tapAppend(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('workout-course-add')));
    await tester.tap(find.byKey(const Key('workout-course-add')));
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String name) async {
    await tester.tap(find.widgetWithText(ListTile, name));
    await tester.pumpAndSettle();
  }

  Future<void> chooseLength(WidgetTester tester, String option) async {
    final choice = find.descendant(
      of: find.byKey(const Key('workout-length')),
      matching: find.text(option),
    );
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pump();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Speichern'));
    await setup.settle(tester);
  }

  testWidgets('Strecke anhängen: a lap is the sum of the courses', (
    tester,
  ) async {
    await addCourses(tester);
    await openEditor(tester, courseIds: [einrudern]);

    await tapAppend(tester);
    await pick(tester, '2 km Intervall');

    expect(cards(tester), ['Einrudern', '2 km Intervall']);
    expect(
      tester.widget<Text>(find.byKey(const Key('workout-result'))).data,
      '2500 m',
    );
    expect(find.text('1 × 2500 m'), findsOneWidget);
    await save(tester);
    final saved = (await tester.runAsync(setup.workouts.all))!.single;
    expect([for (final c in saved.courses) c.id], [einrudern, intervall]);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('Nur gleiche Achse: appending offers no time course', (
    tester,
  ) async {
    await addCourses(tester);
    await openEditor(tester, courseIds: [einrudern]);

    await tapAppend(tester);

    expect(find.widgetWithText(ListTile, '2 km Intervall'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Vier Minuten'), findsNothing);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('Strecke verschieben: moves a course up', (tester) async {
    await addCourses(tester);
    await openEditor(tester, courseIds: [einrudern, intervall, ausrudern]);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('workout-course-2')),
        matching: find.byTooltip('Nach oben'),
      ),
    );
    await tester.pump();

    expect(cards(tester), ['Einrudern', 'Ausrudern', '2 km Intervall']);
    await save(tester);
    final saved = (await tester.runAsync(setup.workouts.all))!.single;
    expect(
      [for (final c in saved.courses) c.id],
      [einrudern, ausrudern, intervall],
    );
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('removes a course, but not the last one', (tester) async {
    await addCourses(tester);
    await openEditor(tester, courseIds: [einrudern, intervall]);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('workout-course-0')),
        matching: find.byTooltip('Strecke entfernen'),
      ),
    );
    await tester.pump();

    // Letzte Strecke: it can only be replaced.
    expect(cards(tester), ['2 km Intervall']);
    expect(find.byTooltip('Strecke entfernen'), findsNothing);
    expect(find.byTooltip('Strecke ersetzen'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('Erste Strecke ersetzen: offers both axes for the only course', (
    tester,
  ) async {
    await addCourses(tester);
    await openEditor(tester, courseIds: [einrudern]);

    await tester.tap(find.byTooltip('Strecke ersetzen'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, '2 km Intervall'), findsOneWidget);
    await pick(tester, 'Vier Minuten');

    expect(cards(tester), ['Vier Minuten']);
    await save(tester);
    final saved = (await tester.runAsync(setup.workouts.all))!.single;
    expect(saved.courses.single.id, vierMinuten);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('a new workout starts by choosing its first course', (
    tester,
  ) async {
    await addCourses(tester);
    await openEditor(tester);

    expect(find.text('Strecke wählen'), findsOneWidget);
    await tapAppend(tester);
    expect(find.widgetWithText(ListTile, 'Vier Minuten'), findsOneWidget);
    await pick(tester, 'Vier Minuten');

    expect(cards(tester), ['Vier Minuten']);
    expect(find.text('Strecke anhängen'), findsOneWidget);
    await tapAppend(tester);
    expect(find.widgetWithText(ListTile, 'Einrudern'), findsNothing);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('Dauer wählen: saves a duration of 45 min', (tester) async {
    await addCourses(tester);
    await openEditor(tester, courseIds: [einrudern, intervall, ausrudern]);

    await chooseLength(tester, 'Dauer');
    await stepTo(tester, const Key('workout-duration'), 45);

    expect(
      tester.widget<Text>(find.byKey(const Key('workout-result'))).data,
      '45:00',
    );
    expect(find.text('Runden à 3000 m'), findsOneWidget);
    await save(tester);
    final saved = (await tester.runAsync(setup.workouts.all))!.single;
    expect(saved.length, const TimeLimit(Duration(minutes: 45)));
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('Werte bleiben beim Wechseln: the laps stay at 5', (
    tester,
  ) async {
    await addCourses(tester);
    await openEditor(tester, courseIds: [einrudern]);

    await stepTo(tester, const Key('workout-laps'), 5);
    await chooseLength(tester, 'Dauer');
    await chooseLength(tester, 'Runden');

    expect(stepperValue(tester, const Key('workout-laps')), 5);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('fits 400 × 400 without overflow, also with long zone names', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    setup = WorkoutSetup();
    final long = (await tester.runAsync(
      () => setup.courses.create(
        'Seerunde mit einem sehr langen Namen für die Strecke',
        const CourseDefinition(
          axis: CourseAxis.distance,
          length: 1000,
          segments: [
            CourseSegment(length: 200),
            CourseSegment(
              length: 600,
              paceFastCs: 12500,
              paceSlowCs: 13000,
              spmMin: 20,
              spmMax: 22,
              zoneName: 'Tempo mit einem sehr langen Namen für die Zone',
            ),
            CourseSegment(length: 200),
          ],
        ),
      ),
    ))!;
    await openEditor(tester, courseIds: [long, long, long]);

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const Key('workout-result')),
      100,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await disposeWidgetsWithDatabase(tester);
  });

  group('Starten ohne Speichern', () {
    final button = find.byKey(const Key('workout-start-unsaved'));
    Finder editorList() => find
        .descendant(
          of: find.byType(WorkoutEditorScreen),
          matching: find.byType(Scrollable),
        )
        .first;

    Future<void> showButton(WidgetTester tester) async {
      await tester.scrollUntilVisible(button, 100, scrollable: editorList());
      await tester.pumpAndSettle();
    }

    Future<void> startUnsaved(WidgetTester tester) async {
      await showButton(tester);
      await tester.tap(button);
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    Future<void> stopRowing(WidgetTester tester) async {
      await setup.container.read(sessionRecorderProvider.notifier).stop();
      await setup.container.read(activeErgSourceProvider.notifier).clear();
    }

    /// Ends the session and closes its summary with "Fertig".
    Future<void> endAndClose(WidgetTester tester) async {
      await tester.tap(find.text('Beenden'));
      await setup.settle(tester);
      await tester.tap(find.text('Fertig'));
      await setup.settle(tester);
    }

    testWidgets(
      'Kette ohne Namen starten: rows the three courses, no workout',
      (tester) async {
        await addCourses(tester);
        // From the list, so the start screen of the test lies below the editor.
        await setup.pump(tester);
        await tester.tap(find.text('Workout anlegen'));
        await setup.settle(tester);
        for (final name in ['Einrudern', '2 km Intervall', 'Ausrudern']) {
          await tapAppend(tester);
          await pick(tester, name);
        }
        await stepTo(tester, const Key('workout-laps'), 1);

        await startUnsaved(tester);

        expect(find.byType(LiveScreen), findsOneWidget);
        final plan = setup.container.read(sessionRecorderProvider)?.plan;
        expect(
          [for (final c in plan!.courses) c.id],
          [einrudern, intervall, ausrudern],
        );
        expect(plan.length, const LapCount(1));
        expect(plan.workout, isNull);
        expect(await tester.runAsync(setup.workouts.all), isEmpty);

        await endAndClose(tester);
        // Zurück im Editor: everything as it was set.
        expect(find.byType(WorkoutEditorScreen), findsOneWidget);
        await tester.drag(editorList(), const Offset(0, 3000));
        await tester.pumpAndSettle();
        expect(cards(tester), ['Einrudern', '2 km Intervall', 'Ausrudern']);
        expect(stepperValue(tester, const Key('workout-laps')), 1);
        expect(await tester.runAsync(setup.workouts.all), isEmpty);
        await stopRowing(tester);
        await disposeWidgetsWithDatabase(tester);
      },
    );

    testWidgets('Ohne Strecke: no session, the editor names the course', (
      tester,
    ) async {
      await addCourses(tester);
      await openEditor(tester);

      await startUnsaved(tester);

      expect(find.byType(LiveScreen), findsNothing);
      expect(setup.container.read(sessionRecorderProvider), isNull);
      expect(find.text('Wähle eine Strecke.'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets(
      'Bestehendes Workout geändert starten: the saved one keeps 3 laps',
      (tester) async {
        await addCourses(tester);
        await openEditor(
          tester,
          courseIds: [einrudern],
          length: const LapCount(3),
        );
        await stepTo(tester, const Key('workout-laps'), 1);

        await startUnsaved(tester);

        final plan = setup.container.read(sessionRecorderProvider)?.plan;
        expect((plan?.length, plan?.workout), (const LapCount(1), null));
        final saved = (await tester.runAsync(setup.workouts.all))!.single;
        expect(saved.length, const LapCount(3));
        await stopRowing(tester);
        await disposeWidgetsWithDatabase(tester);
      },
    );

    testWidgets('rows the current version of a course edited meanwhile', (
      tester,
    ) async {
      await addCourses(tester);
      await openEditor(tester, courseIds: [einrudern]);
      await tester.runAsync(() async {
        await setup.courses.rename(einrudern, 'Einrudern lang');
        await setup.courses.updateDefinition(
          einrudern,
          CourseDefinition.single(axis: CourseAxis.distance, length: 800),
        );
      });

      await startUnsaved(tester);

      final course = setup.container
          .read(sessionRecorderProvider)
          ?.plan
          ?.courses
          .single;
      expect(
        (course?.name, course?.definition.length),
        ('Einrudern lang', 800),
      );
      await stopRowing(tester);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('fits 400 × 400 without overflow with both buttons', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await addCourses(tester);
      await openEditor(tester, courseIds: [einrudern, intervall]);

      await showButton(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Starten ohne Speichern'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });
  });
}
