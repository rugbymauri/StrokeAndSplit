import 'package:strokesplit/app/widgets/oar_stepper.dart';
import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_layout.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/zones/zone.dart';
import 'package:strokesplit/data/zones/zone_repository.dart';
import 'package:strokesplit/features/zones/zone_editor_screen.dart';
import 'package:strokesplit/features/zones/zones_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oar_steppers.dart';
import '../../support/test_database.dart';
import '../../support/localized_app.dart';

const _sprint = Zone(
  name: 'Sprint',
  axis: CourseAxis.distance,
  length: 100,
  paceFastCs: 10500,
  paceSlowCs: 11000,
  spmMin: 30,
  spmMax: 34,
);

class _Setup {
  final db = openTestDatabase();
  late final zones = ZoneRepository(db);
  late final courses = CourseRepository(db);
  late final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);

  Future<void> pump(WidgetTester tester, {Locale locale = const Locale('de')}) async {
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: LocalizedApp(locale: locale, home: const ZonesScreen())),
    );
    await settle(tester);
  }

  /// Lets database work finish, which does not run under fake async.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pumpAndSettle();
    }
  }

  /// The sprint, placed at the end of two courses of 2000 m.
  Future<int> sprintInTwoCourses(WidgetTester tester) async {
    return (await tester.runAsync(() async {
      final id = await zones.create(_sprint);
      for (final name in ['2 km Intervall', 'Kurz']) {
        final layout = resolveCourse(
          axis: CourseAxis.distance,
          length: 2000,
          placements: [ZonePlacement(zoneId: id, start: 1900)],
          zones: {id: (await zones.get(id))!},
        );
        await courses.create(name, layout.definition!);
      }
      return id;
    }))!;
  }
}

/// Opens zone [name] from the list and its editor from the details.
Future<void> _openEditor(WidgetTester tester, _Setup setup, String name) async {
  await tester.tap(find.text(name));
  await setup.settle(tester);
  await tester.tap(find.byTooltip('Bearbeiten'));
  await setup.settle(tester);
}

Future<void> _name(WidgetTester tester, String name) async {
  await tester.enterText(find.byKey(const Key('zone-name')), name);
  await tester.pump();
}

/// Sets the steppers of the zone editor, e.g. `{'pace-fast': 10500}`.
Future<void> _step(WidgetTester tester, Map<String, int> fields) async {
  for (final MapEntry(:key, :value) in fields.entries) {
    await stepTo(tester, Key('zone-$key'), value);
  }
}

Future<void> _switch(WidgetTester tester, String band) async {
  await tester.tap(find.byKey(Key('zone-$band-band')));
  await tester.pump();
}

void main() {
  testWidgets('creates a sprint and lists it', (tester) async {
    final setup = _Setup();
    await setup.pump(tester);

    await tester.tap(find.text('Zone anlegen'));
    await tester.pumpAndSettle();
    await _name(tester, 'Sprint');
    expect(stepperValue(tester, const Key('zone-length')), 100);
    await _step(tester, {'pace-fast': 10500, 'pace-slow': 11000});
    expect(find.byKey(const Key('zone-spm-min')), findsNothing);
    await _switch(tester, 'spm');
    await _step(tester, {'spm-max': 34, 'spm-min': 30});
    await tester.tap(find.byTooltip('Speichern'));
    await setup.settle(tester);

    expect(find.text('DISTANZ'), findsOneWidget);
    expect(find.text('Sprint'), findsOneWidget);
    expect(find.text('100 m · 1:45–1:50 · 30–34 spm'), findsOneWidget);
    expect(find.text('nicht verwendet'), findsOneWidget);
    final stored = (await tester.runAsync(setup.zones.all))!.single;
    expect((stored.paceFastCs, stored.spmMax), (10500, 34));
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('does not save a zone without a band', (tester) async {
    final setup = _Setup();
    await setup.pump(tester);

    await tester.tap(find.text('Zone anlegen'));
    await tester.pumpAndSettle();
    await _name(tester, 'Nichts');
    await _switch(tester, 'pace');
    await tester.tap(find.byTooltip('Speichern'));
    await setup.settle(tester);

    expect(find.text('Es fehlt ein Band: Pace, Schlagzahl oder beides.'), findsOneWidget);
    expect(await tester.runAsync(setup.zones.all), isEmpty);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('says in English what keeps a zone from being saved', (tester) async {
    final setup = _Setup();
    addTearDown(setup.container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: setup.container,
      child: const LocalizedApp(locale: Locale('en'), home: ZoneEditorScreen()),
    ));
    expect(find.text('Pace band'), findsOneWidget);
    expect(find.text('Fastest'), findsOneWidget);
    expect(find.bySemanticsLabel('5 seconds more'), findsNWidgets(2));
    await _switch(tester, 'pace');
    await tester.tap(find.byTooltip('Save'));
    await setup.settle(tester);

    expect(find.text('The name is missing.'), findsOneWidget);
    expect(find.text('A band is missing: pace, stroke rate or both.'), findsOneWidget);
    expect(await tester.runAsync(setup.zones.all), isEmpty);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('lists the zones in English', (tester) async {
    final setup = _Setup();
    await setup.sprintInTwoCourses(tester);
    await tester.runAsync(() => setup.zones.create(_sprint.copyWith(name: 'Lang', length: 200)));
    await setup.pump(tester, locale: const Locale('en'));

    expect(find.text('DISTANCE'), findsOneWidget);
    expect(find.text('in 2 courses'), findsOneWidget);
    expect(find.text('not used'), findsOneWidget);
    expect(find.text('New zone'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('names the courses a change applies to and keeps their axis', (tester) async {
    final setup = _Setup();
    await setup.sprintInTwoCourses(tester);
    await setup.pump(tester);
    expect(find.text('in 2 Strecken'), findsOneWidget);

    await _openEditor(tester, setup, 'Sprint');

    expect(find.text('Steckt in „2 km Intervall“, „Kurz“'), findsOneWidget);
    final axis = tester.widget<SegmentedButton<CourseAxis>>(find.byType(SegmentedButton<CourseAxis>));
    expect(axis.onSelectionChanged, isNull);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('refuses a change that no longer fits a course', (tester) async {
    final setup = _Setup();
    await setup.sprintInTwoCourses(tester);
    await setup.pump(tester);

    await _openEditor(tester, setup, 'Sprint');
    await tapStep(tester, const Key('zone-length'), more: true);
    await tester.tap(find.byTooltip('Speichern'));
    await setup.settle(tester);

    expect(find.textContaining('Die Änderung passt nicht in „2 km Intervall“, „Kurz“'), findsOneWidget);
    expect((await tester.runAsync(setup.zones.all))!.single.length, 100);
    await disposeWidgetsWithDatabase(tester);
  });

  group('steps', () {
    Future<_Setup> openSprint(WidgetTester tester) async {
      final setup = _Setup();
      await tester.runAsync(() => setup.zones.create(_sprint));
      await setup.pump(tester);
      await _openEditor(tester, setup, 'Sprint');
      return setup;
    }

    testWidgets('makes the fastest pace of the band 5 s slower', (tester) async {
      final setup = await openSprint(tester);
      final fastest = find.byKey(const Key('zone-pace-fast'));
      expect(find.descendant(of: fastest, matching: find.text('1:45')), findsOneWidget);

      await tester.tap(find.descendant(of: fastest, matching: find.bySemanticsLabel('5 Sekunden mehr')));
      await tester.pump();

      expect(find.descendant(of: fastest, matching: find.text('1:50')), findsOneWidget);
      // The slowest pace moves along.
      expect(stepperValue(tester, const Key('zone-pace-slow')), 11500);
      await tester.tap(find.byTooltip('Speichern'));
      await setup.settle(tester);
      expect(find.text('100 m · 1:50–1:55 · 30–34 spm'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('lengthens the zone by 10 m', (tester) async {
      final setup = await openSprint(tester);

      await tapStep(tester, const Key('zone-length'), more: true);

      expect(stepperValue(tester, const Key('zone-length')), 110);
      await tester.tap(find.byTooltip('Speichern'));
      await setup.settle(tester);
      expect(find.text('110 m · 1:45–1:50 · 30–34 spm'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('steps the stroke rate by one stroke within the band', (tester) async {
      final setup = await openSprint(tester);
      final lowest = find.byKey(const Key('zone-spm-min'));

      await tester.tap(find.descendant(of: lowest, matching: find.bySemanticsLabel('1 Schlag weniger')));
      await tester.pump();
      expect(stepperValue(tester, const Key('zone-spm-min')), 29);
      await _step(tester, {'spm-min': 34});

      expect(tester.widget<OarStepper>(lowest).canIncrease, isFalse);
      expect(tester.widget<OarStepper>(find.byKey(const Key('zone-spm-max'))).canDecrease, isFalse);
      await tester.tap(find.byTooltip('Speichern'));
      await setup.settle(tester);
      expect(find.text('100 m · 1:45–1:50 · 34–34 spm'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });
  });

  group('pace band', () {
    const fast = Key('zone-pace-fast');
    const slow = Key('zone-pace-slow');

    (int, int) band(WidgetTester tester) => (stepperValue(tester, fast), stepperValue(tester, slow));

    Future<_Setup> openNewZone(WidgetTester tester) async {
      final setup = _Setup();
      await setup.pump(tester);
      await tester.tap(find.text('Zone anlegen'));
      await tester.pumpAndSettle();
      return setup;
    }

    testWidgets('starts a new zone with a gap of 10 s', (tester) async {
      await openNewZone(tester);

      expect(band(tester), (16500, 17500));
      expect(find.descendant(of: find.byKey(fast), matching: find.text('2:45')), findsOneWidget);
      expect(find.descendant(of: find.byKey(slow), matching: find.text('2:55')), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('moves the slowest pace along with the fastest', (tester) async {
      final setup = await openNewZone(tester);

      await tapStep(tester, fast, more: false);
      expect(band(tester), (16000, 17000));
      await stepTo(tester, fast, 12000);
      expect(band(tester), (12000, 13000));
      await tapStep(tester, fast, more: true);
      expect(band(tester), (12500, 13500));

      await _name(tester, 'Band');
      await tester.tap(find.byTooltip('Speichern'));
      await setup.settle(tester);
      expect(find.text('100 m · 2:05–2:15'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('changes only the slowest pace and keeps the new gap', (tester) async {
      await openNewZone(tester);
      await stepTo(tester, fast, 12000);

      await tapStep(tester, slow, more: true);
      expect(band(tester), (12000, 13500));
      await tapStep(tester, fast, more: false);
      expect(band(tester), (11500, 13000));

      await stepTo(tester, slow, 11500);
      expect(band(tester), (11500, 11500));
      // Not faster than the fastest pace.
      expect(tester.widget<OarStepper>(find.byKey(slow)).canDecrease, isFalse);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('stops the band at 1:00 and 5:00', (tester) async {
      await openNewZone(tester);

      await stepTo(tester, fast, 29000);
      expect(band(tester), (29000, 30000));
      // The slowest pace would leave the range.
      expect(tester.widget<OarStepper>(find.byKey(fast)).canIncrease, isFalse);
      expect(tester.widget<OarStepper>(find.byKey(slow)).canIncrease, isFalse);
      await tapStep(tester, fast, more: true);
      expect(band(tester), (29000, 30000));

      await stepTo(tester, fast, 6000);
      expect(band(tester), (6000, 7000));
      expect(tester.widget<OarStepper>(find.byKey(fast)).canDecrease, isFalse);
      await disposeWidgetsWithDatabase(tester);
    });
  });

  testWidgets('deletes a zone after confirming the courses it frees', (tester) async {
    final setup = _Setup();
    await setup.sprintInTwoCourses(tester);
    await setup.pump(tester);

    await _openEditor(tester, setup, 'Sprint');
    await tester.tap(find.byTooltip('Löschen'));
    await tester.pumpAndSettle();
    expect(find.textContaining('In diesen Strecken wird ihre Stelle frei: „2 km Intervall“, „Kurz“.'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Löschen')));
    await setup.settle(tester);

    expect(find.textContaining('Noch keine Zonen angelegt.'), findsOneWidget);
    final course = (await tester.runAsync(setup.courses.all))!.first;
    expect(course.definition.segments.single.isFree, isTrue);
    await disposeWidgetsWithDatabase(tester);
  });
}
