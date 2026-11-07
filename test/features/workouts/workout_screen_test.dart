import 'package:strokesplit/app/widgets/ghost_symbol.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/sources/erg_source_providers.dart';
import 'package:strokesplit/data/sources/rower_choice.dart';
import 'package:strokesplit/features/sessions/session_summary_screen.dart';
import 'package:strokesplit/features/workouts/workout_podium.dart';
import 'package:strokesplit/features/workouts/workout_screen.dart';
import 'package:strokesplit/features/workouts/workouts_screen.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/rowed_sessions.dart';
import '../../support/workout_setup.dart';
import '../../support/test_database.dart';

import 'package:strokesplit/data/sessions/session_plan.dart';

void main() {
  Finder onScreen(Finder finder) =>
      find.descendant(of: find.byType(WorkoutScreen), matching: finder);

  /// Rows on with the simulator until the live display has started.
  Future<void> start(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('workout-start')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> stopRowing(WorkoutSetup setup) async {
    await setup.container.read(sessionRecorderProvider.notifier).stop();
    await setup.container.read(activeErgSourceProvider.notifier).clear();
  }

  group('the screen of a workout', () {
    testWidgets('shows course, laps and zones and goes back to the list', (
      tester,
    ) async {
      final setup = WorkoutSetup();
      final course = await setup.addCourseWithZone(tester, 'Seerunde');
      await setup.addWorkout(tester, 'Seerunde x3', courseIds: [course]);
      await setup.pump(tester);

      await setup.openWorkout(tester, 'Seerunde x3');

      expect(onScreen(find.text('Seerunde x3')), findsOneWidget);
      expect(
        onScreen(find.text('Seerunde · 1000 m · 3 Runden')),
        findsOneWidget,
      );
      expect(
        onScreen(find.text('Tempo 2:05–2:10 · 20–22 spm')),
        findsOneWidget,
      );
      expect(onScreen(find.text('Starten')), findsOneWidget);
      expect(onScreen(find.byTooltip('Workout bearbeiten')), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await setup.settle(tester);
      expect(find.byType(WorkoutScreen), findsNothing);
      expect(find.text('Seerunde x3'), findsOneWidget);
      expect(find.text('Tempo 2:05–2:10 · 20–22 spm'), findsNothing);
      expect(find.text('Starten'), findsNothing);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('says that a course without zones is rowed freely', (
      tester,
    ) async {
      final setup = WorkoutSetup();
      final course = await setup.addCourse(tester, 'Seerunde');
      await setup.addWorkout(tester, 'Seerunde x3', courseIds: [course]);
      await setup.pump(tester);

      await setup.openWorkout(tester, 'Seerunde x3');

      expect(onScreen(find.text('ohne Zonen')), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('shows the new name after renaming in the editor', (
      tester,
    ) async {
      final setup = WorkoutSetup();
      final course = await setup.addCourse(tester, 'Seerunde');
      await setup.addWorkout(tester, 'Seerunde x3', courseIds: [course]);
      await setup.pump(tester);

      await setup.openWorkout(tester, 'Seerunde x3');
      await tester.tap(find.byTooltip('Workout bearbeiten'));
      await setup.settle(tester);
      await tester.enterText(
        find.byKey(const Key('workout-name')),
        'Seerunde dreimal',
      );
      await tester.tap(find.byTooltip('Speichern'));
      await setup.settle(tester);

      expect(find.byType(WorkoutScreen), findsOneWidget);
      expect(onScreen(find.text('Seerunde dreimal')), findsOneWidget);
      expect(onScreen(find.text('Seerunde x3')), findsNothing);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets(
      'goes back to the list when the workout is deleted in its editor',
      (tester) async {
        final setup = WorkoutSetup();
        final course = await setup.addCourse(tester, 'Seerunde');
        await setup.addWorkout(tester, 'Seerunde x3', courseIds: [course]);
        await setup.pump(tester);

        await setup.openWorkout(tester, 'Seerunde x3');
        await tester.tap(find.byTooltip('Workout bearbeiten'));
        await setup.settle(tester);
        await tester.tap(find.byTooltip('Löschen'));
        await tester.pumpAndSettle();
        expect(find.text('Workout löschen?'), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Löschen'),
          ),
        );
        await setup.settle(tester);

        expect(find.byType(WorkoutScreen), findsNothing);
        expect(find.byType(WorkoutsScreen), findsOneWidget);
        expect(find.text('Seerunde x3'), findsNothing);
        expect(find.text('Noch keine Workouts angelegt.'), findsOneWidget);
        await disposeWidgetsWithDatabase(tester);
      },
    );

    testWidgets('shows the workout in English', (tester) async {
      final setup = WorkoutSetup();
      final course = await setup.addCourseWithZone(tester, 'Seerunde');
      final id = await setup.addWorkout(
        tester,
        'Seerunde x3',
        courseIds: [course],
      );
      await setup.pump(
        tester,
        home: WorkoutScreen(workoutId: id),
        locale: const Locale('en'),
      );

      expect(find.text('Seerunde · 1000 m · 3 laps'), findsOneWidget);
      expect(find.text('Tempo 2:05–2:10 · 20–22 spm'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Row against the ghost'), findsOneWidget);
      expect(find.byTooltip('Edit workout'), findsOneWidget);
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
        final setup = WorkoutSetup();
        final course = await setup.addCourseWithZone(tester, 'Seerunde');
        final id = await setup.addWorkout(
          tester,
          'Seerunde x3',
          courseIds: [course],
        );
        await tester.runAsync(() async {
          final x3 = (await setup.workouts.get(id))!;
          for (final day in [1, 2, 3]) {
            await storeRowedSession(
              setup.db,
              workout: x3,
              startedAt: DateTime(2026, 10, day, 7),
              laps: [
                for (var i = 0; i < 3; i++)
                  RowedLap.single(250000 - day * 1000, 1000),
              ],
            );
          }
        });
        await setup.pump(tester, home: WorkoutScreen(workoutId: id));

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('workout-start')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('workout-ghost')).hitTestable(),
          findsOneWidget,
        );
        await disposeWidgetsWithDatabase(tester);
      });
    }
  });

  group('starting', () {
    testWidgets('starts the workout with the chosen FTMS simulator', (
      tester,
    ) async {
      final setup = WorkoutSetup(
        rower: const RowerChoice.simulator(ErgProtocol.ftms),
      );
      final course = await setup.addCourseWithZone(tester, 'Seerunde');
      await setup.addWorkout(tester, 'Seerunde x3', courseIds: [course]);
      await setup.addWorkout(
        tester,
        'Seerunde offen',
        courseIds: [course],
        length: const OpenLength(),
      );
      await setup.pump(tester);

      await setup.openWorkout(tester, 'Seerunde x3');
      await start(tester);

      final source = setup.container.read(activeErgSourceProvider);
      expect(
        (source?.kind, source?.protocol),
        (ErgSourceKind.simulator, ErgProtocol.ftms),
      );
      expect(
        setup.container.read(sessionRecorderProvider)?.plan?.workout?.name,
        'Seerunde x3',
      );
      expect(find.text('Runde 1 / 3'), findsOneWidget);

      await stopRowing(setup);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets(
      'starts with the chosen simulator without asking for the source',
      (tester) async {
        final setup = WorkoutSetup();
        final id = await setup.addCourse(tester, 'Seerunde');
        await setup.addWorkout(tester, 'Seerunde x3', courseIds: [id]);
        await setup.pump(tester);

        await setup.openWorkout(tester, 'Seerunde x3');
        await start(tester);

        expect(find.byType(SimpleDialog), findsNothing);
        expect(
          setup.container.read(activeErgSourceProvider)?.kind,
          ErgSourceKind.simulator,
        );
        expect(find.text('Runde 1 / 3'), findsOneWidget);
        expect(find.text('Beenden'), findsOneWidget);
        expect(
          setup.container.read(sessionRecorderProvider)?.plan?.workout?.name,
          'Seerunde x3',
        );

        await stopRowing(setup);
        await disposeWidgetsWithDatabase(tester);
      },
    );

    testWidgets('shows the summary when the last lap is done', (tester) async {
      final setup = WorkoutSetup();
      final id = await setup.addCourse(tester, 'Sprint', length: 100);
      await setup.addWorkout(tester, 'Sprint x3', courseIds: [id]);
      await setup.pump(tester);

      await setup.openWorkout(tester, 'Sprint x3');
      await tester.tap(find.byKey(const Key('workout-start')));
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
  });

  group('the ghost switch', () {
    Switch ghostSwitch(WidgetTester tester) => tester.widget<Switch>(
      find.descendant(
        of: find.byKey(const Key('workout-ghost')),
        matching: find.byType(Switch),
      ),
    );

    testWidgets('is on when the screen opens, also without a best result', (
      tester,
    ) async {
      final setup = WorkoutSetup();
      final course = await setup.addCourse(tester, 'Seerunde');
      await setup.addWorkout(tester, 'Seerunde x3', courseIds: [course]);
      await setup.pump(tester);

      await setup.openWorkout(tester, 'Seerunde x3');

      expect(onScreen(find.text('Gegen den Ghost rudern')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('workout-ghost')),
          matching: find.byType(GhostSymbol),
        ),
        findsOneWidget,
      );
      expect(ghostSwitch(tester).value, isTrue);
      expect(
        tester.getSize(find.byKey(const Key('workout-ghost'))).height,
        greaterThanOrEqualTo(48),
      );
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets(
      'starts without ghost when turned off and is on again when the screen opens again',
      (tester) async {
        final setup = WorkoutSetup();
        final course = await setup.addCourse(tester, 'Seerunde');
        await setup.addWorkout(tester, 'Seerunde x3', courseIds: [course]);
        await setup.pump(tester);

        await setup.openWorkout(tester, 'Seerunde x3');
        // A tap anywhere on the row switches.
        await tester.tap(find.text('Gegen den Ghost rudern'));
        await tester.pump();
        expect(ghostSwitch(tester).value, isFalse);
        await start(tester);

        final recording = setup.container.read(sessionRecorderProvider);
        expect(
          (recording?.plan?.workout?.name, recording?.ghost),
          ('Seerunde x3', false),
        );
        await stopRowing(setup);

        // Back on the start screen of the test: the list.
        final navigator = tester.state<NavigatorState>(
          find.byType(Navigator).first,
        );
        navigator.popUntil((route) => route.isFirst);
        await setup.settle(tester);
        await setup.openWorkout(tester, 'Seerunde x3');
        expect(ghostSwitch(tester).value, isTrue);

        await start(tester);
        expect(setup.container.read(sessionRecorderProvider)?.ghost, isTrue);
        await stopRowing(setup);
        await disposeWidgetsWithDatabase(tester);
      },
    );
  });

  group('places of a workout', () {
    Finder inPlace(int place, String text) => find.descendant(
      of: find.byKey(Key('workout-place-$place')),
      matching: find.text(text),
    );
    Finder inPodium(Finder finder) =>
        find.descendant(of: find.byType(WorkoutPodium), matching: finder);

    testWidgets(
      'shows places 1 and 2 with time, pace and date after two sessions',
      (tester) async {
        final setup = WorkoutSetup();
        final course = await setup.addCourse(tester, 'Seerunde');
        final id = await setup.addWorkout(
          tester,
          'Seerunde x3',
          courseIds: [course],
        );
        await tester.runAsync(() async {
          final x3 = (await setup.workouts.get(id))!;
          await storeRowedSession(
            setup.db,
            workout: x3,
            startedAt: DateTime(2026, 10, 1, 7),
            laps: [for (var i = 0; i < 3; i++) RowedLap.single(250000, 1000)],
          );
          await storeRowedSession(
            setup.db,
            workout: x3,
            startedAt: DateTime(2026, 10, 3, 7),
            laps: [for (var i = 0; i < 3; i++) RowedLap.single(248000, 1000)],
          );
        });
        await setup.pump(tester);

        expect(find.byKey(const Key('workout-podium')), findsNothing);
        await setup.openWorkout(tester, 'Seerunde x3');

        expect(onScreen(find.text('BESTLEISTUNGEN')), findsOneWidget);
        expect(inPlace(1, '12:24.0'), findsOneWidget);
        expect(inPlace(1, '2:04 /500 m'), findsOneWidget);
        expect(inPlace(1, '3.10.2026'), findsOneWidget);
        expect(inPlace(2, '12:30.0'), findsOneWidget);
        expect(inPlace(2, '2:05 /500 m'), findsOneWidget);
        expect(inPlace(2, '1.10.2026'), findsOneWidget);
        expect(find.byKey(const Key('workout-place-3')), findsNothing);
        expect(find.byKey(const Key('workout-podium-hint')), findsNothing);
        // Only place 1 carries the ghost symbol.
        final ghostSlot = find.byKey(const Key('workout-ghost-slot'));
        expect(
          find.descendant(
            of: find.byKey(const Key('workout-place-1')),
            matching: ghostSlot,
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: ghostSlot, matching: find.byType(GhostSymbol)),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('workout-place-2')),
            matching: find.byType(GhostSymbol),
          ),
          findsNothing,
        );
        expect(inPodium(find.byType(GhostSymbol)), findsOneWidget);
        await disposeWidgetsWithDatabase(tester);
      },
    );

    testWidgets('shows the ghost symbol only at place 1 of three', (
      tester,
    ) async {
      final setup = WorkoutSetup();
      final course = await setup.addCourse(tester, 'Seerunde');
      final id = await setup.addWorkout(
        tester,
        'Seerunde x1',
        courseIds: [course],
        length: const LapCount(1),
      );
      await tester.runAsync(() async {
        final x1 = (await setup.workouts.get(id))!;
        for (final (day, ms) in [(1, 250000), (2, 246000), (3, 248000)]) {
          await storeRowedSession(
            setup.db,
            workout: x1,
            startedAt: DateTime(2026, 10, day, 7),
            laps: [RowedLap.single(ms, 1000)],
          );
        }
      });
      await setup.pump(tester);

      await setup.openWorkout(tester, 'Seerunde x1');

      Finder ghostIn(int place) => find.descendant(
        of: find.byKey(Key('workout-place-$place')),
        matching: find.byType(GhostSymbol),
      );
      expect(ghostIn(1), findsOneWidget);
      expect(ghostIn(2), findsNothing);
      expect(ghostIn(3), findsNothing);
      expect(inPodium(find.byType(GhostSymbol)), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('says that a workout never rowed has no best time yet', (
      tester,
    ) async {
      final setup = WorkoutSetup();
      final course = await setup.addCourse(tester, 'Seerunde');
      await setup.addWorkout(tester, 'Seerunde x3', courseIds: [course]);
      await setup.pump(tester);

      await setup.openWorkout(tester, 'Seerunde x3');

      expect(
        onScreen(
          find.text(
            'Noch keine Bestzeit. Es zählen Sessions mit allen Runden an einem Rudergerät.',
          ),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('workout-podium')), findsNothing);
      expect(inPodium(find.byType(GhostSymbol)), findsNothing);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('shows no places for an open number of laps', (tester) async {
      final setup = WorkoutSetup();
      final course = await setup.addCourse(tester, 'Seerunde');
      final id = await setup.addWorkout(
        tester,
        'Seerunde offen',
        courseIds: [course],
        length: const OpenLength(),
      );
      await tester.runAsync(() async {
        final open = (await setup.workouts.get(id))!;
        await storeRowedSession(
          setup.db,
          workout: open,
          laps: [RowedLap.single(250000, 1000)],
        );
      });
      await setup.pump(tester);

      await setup.openWorkout(tester, 'Seerunde offen');

      expect(
        onScreen(find.text('Bei offener Rundenzahl gibt es keine Bestzeit.')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('workout-podium')), findsNothing);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('shows the hint when only a simulated session was rowed', (
      tester,
    ) async {
      final setup = WorkoutSetup();
      final course = await setup.addCourse(tester, 'Seerunde');
      final id = await setup.addWorkout(
        tester,
        'Seerunde x1',
        courseIds: [course],
        length: const LapCount(1),
      );
      await tester.runAsync(() async {
        final x1 = (await setup.workouts.get(id))!;
        await storeRowedSession(
          setup.db,
          workout: x1,
          source: ErgSourceKind.simulator,
          laps: [RowedLap.single(250000, 1000)],
        );
      });
      await setup.pump(tester);

      await setup.openWorkout(tester, 'Seerunde x1');

      expect(find.byKey(const Key('workout-podium-hint')), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('shows the places in English', (tester) async {
      final setup = WorkoutSetup();
      final course = await setup.addCourse(tester, 'Seerunde');
      final id = await setup.addWorkout(
        tester,
        'Seerunde x1',
        courseIds: [course],
        length: const LapCount(1),
      );
      await tester.runAsync(() async {
        final x1 = (await setup.workouts.get(id))!;
        await storeRowedSession(
          setup.db,
          workout: x1,
          startedAt: DateTime(2026, 10, 3, 7),
          laps: [RowedLap.single(250000, 1000)],
        );
      });
      await setup.pump(tester, locale: const Locale('en'));

      await setup.openWorkout(tester, 'Seerunde x1');

      expect(find.text('BEST RESULTS'), findsOneWidget);
      expect(inPlace(1, '4:10.0'), findsOneWidget);
      expect(inPlace(1, '10/3/2026'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });
  });
}
