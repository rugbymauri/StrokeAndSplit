import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_layout.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/zones/zone.dart';
import 'package:aergrow/data/zones/zone_repository.dart';
import 'package:aergrow/features/zones/zone_editor_screen.dart';
import 'package:aergrow/features/zones/zones_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  /// The sprint, placed at 500 m in two courses.
  Future<int> sprintInTwoCourses(WidgetTester tester) async {
    return (await tester.runAsync(() async {
      final id = await zones.create(_sprint);
      for (final name in ['2 km Intervall', 'Kurz']) {
        final layout = resolveCourse(
          axis: CourseAxis.distance,
          length: 2000,
          placements: [ZonePlacement(zoneId: id, start: 500)],
          zones: {id: (await zones.get(id))!},
        );
        await courses.create(name, layout.definition!);
      }
      return id;
    }))!;
  }
}

Future<void> _enter(WidgetTester tester, Map<String, String> fields) async {
  for (final MapEntry(:key, :value) in fields.entries) {
    await tester.enterText(find.byKey(Key('zone-$key')), value);
  }
  await tester.pump();
}

void main() {
  testWidgets('creates a sprint and lists it', (tester) async {
    final setup = _Setup();
    await setup.pump(tester);

    await tester.tap(find.text('Zone anlegen'));
    await tester.pumpAndSettle();
    await _enter(tester, {
      'name': 'Sprint',
      'length': '100',
      'pace-fast': '1:45',
      'pace-slow': '1:50',
      'spm-min': '30',
      'spm-max': '34',
    });
    await tester.tap(find.byTooltip('Speichern'));
    await setup.settle(tester);

    expect(find.text('Distanz'), findsOneWidget);
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
    await _enter(tester, {'name': 'Nichts', 'length': '100'});
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
    await _enter(tester, {'name': 'Halb', 'length': '100', 'pace-fast': '1:45', 'spm-min': '34', 'spm-max': '30'});
    await tester.tap(find.byType(FilledButton));
    await setup.settle(tester);

    expect(find.text('The pace band is missing a bound.'), findsOneWidget);
    expect(find.text('The lowest stroke rate is above the highest.'), findsOneWidget);
    expect(await tester.runAsync(setup.zones.all), isEmpty);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('lists the zones in English', (tester) async {
    final setup = _Setup();
    await setup.sprintInTwoCourses(tester);
    await tester.runAsync(() => setup.zones.create(_sprint.copyWith(name: 'Lang', length: 200)));
    await setup.pump(tester, locale: const Locale('en'));

    expect(find.text('Distance'), findsOneWidget);
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

    await tester.tap(find.text('Sprint'));
    await setup.settle(tester);

    expect(find.text('Steckt in „2 km Intervall“, „Kurz“'), findsOneWidget);
    final axis = tester.widget<SegmentedButton<CourseAxis>>(find.byType(SegmentedButton<CourseAxis>));
    expect(axis.onSelectionChanged, isNull);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('refuses a change that no longer fits a course', (tester) async {
    final setup = _Setup();
    await setup.sprintInTwoCourses(tester);
    await setup.pump(tester);

    await tester.tap(find.text('Sprint'));
    await setup.settle(tester);
    await _enter(tester, {'length': '1600'});
    await tester.tap(find.byTooltip('Speichern'));
    await setup.settle(tester);

    expect(find.textContaining('Die Änderung passt nicht in „2 km Intervall“, „Kurz“'), findsOneWidget);
    expect((await tester.runAsync(setup.zones.all))!.single.length, 100);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('deletes a zone after confirming the courses it frees', (tester) async {
    final setup = _Setup();
    await setup.sprintInTwoCourses(tester);
    await setup.pump(tester);

    await tester.tap(find.text('Sprint'));
    await setup.settle(tester);
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
