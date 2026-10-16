import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_layout.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/zones/zone.dart';
import 'package:aergrow/data/zones/zone_repository.dart';
import 'package:aergrow/features/courses/course_editor_screen.dart';
import 'package:aergrow/features/courses/courses_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';
import '../../support/localized_app.dart';

class _Setup {
  final db = openTestDatabase();
  late final courses = CourseRepository(db);
  late final zones = ZoneRepository(db);
  late final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);

  Future<void> pump(WidgetTester tester, {Widget home = const CoursesScreen(), Locale? locale}) async {
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: LocalizedApp(locale: locale ?? const Locale('de'), home: home),
      ),
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

  Future<List<Course>> stored(WidgetTester tester) async => (await tester.runAsync(courses.all))!;
}

Future<void> _openNew(WidgetTester tester, String name) async {
  await tester.tap(find.text('Strecke anlegen'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('course-name')), name);
}

Future<void> _save(WidgetTester tester, _Setup setup) async {
  await tester.tap(find.byTooltip('Speichern'));
  await setup.settle(tester);
}

/// `frei · 0–500 m` or `Sprint · 500–600 m · 1:45–1:50` for each part of the course.
List<String> _sections(WidgetTester tester) => [
      for (var i = 0; find.byKey(Key('section-$i')).evaluate().isNotEmpty; i++)
        [
          for (final text in tester.widgetList<Text>(
            find.descendant(of: find.byKey(Key('section-$i')), matching: find.byType(Text)),
          ))
            text.data!,
        ].join(' · '),
    ];

void main() {
  testWidgets('creates a distance course', (tester) async {
    final setup = _Setup();
    await setup.pump(tester);
    expect(find.text('Noch keine Strecken angelegt.'), findsOneWidget);

    await _openNew(tester, 'Seerunde');
    await tester.enterText(find.byKey(const Key('course-length')), '1000');
    await tester.pump();
    expect(_sections(tester), ['frei · 0–1000 m']);
    await _save(tester, setup);

    expect(find.text('Seerunde'), findsOneWidget);
    expect(find.text('1000 m · frei'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('creates a time course entered as m:ss', (tester) async {
    final setup = _Setup();
    await setup.pump(tester);

    await _openNew(tester, 'Vier Minuten');
    await tester.tap(find.text('Zeit'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('course-length')), '4:00');
    await _save(tester, setup);

    expect(find.text('4:00 · frei'), findsOneWidget);
    final course = (await setup.stored(tester)).single;
    expect((course.axis, course.definition.length), (CourseAxis.time, 240));
    await disposeWidgetsWithDatabase(tester);
  });

  group('with zones', () {
    late _Setup setup;
    late int sprint;
    late int endurance;
    late int minutes;

    Future<void> pumpWithZones(WidgetTester tester, {Widget home = const CoursesScreen(), Locale? locale}) async {
      setup = _Setup();
      await tester.runAsync(() async {
        sprint = await setup.zones.create(const Zone(
          name: 'Sprint',
          axis: CourseAxis.distance,
          length: 100,
          paceFastCs: 10500,
          paceSlowCs: 11000,
          spmMin: 30,
          spmMax: 34,
        ));
        endurance = await setup.zones.create(const Zone(
          name: 'Ausdauer 2:30',
          axis: CourseAxis.distance,
          length: 500,
          paceFastCs: 14800,
          paceSlowCs: 15200,
        ));
        minutes = await setup.zones
            .create(const Zone(name: 'Vier Minuten', axis: CourseAxis.time, length: 240, spmMin: 20, spmMax: 22));
      });
      await setup.pump(tester, home: home, locale: locale);
    }

    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('place-zone')));
      await setup.settle(tester);
    }

    Future<void> choose(WidgetTester tester, int zone, String start) async {
      await tester.tap(find.byKey(Key('zone-option-$zone')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('place-start')), start);
      await tester.pump();
    }

    Future<void> place(WidgetTester tester, int zone, String start) async {
      await openDialog(tester);
      await choose(tester, zone, start);
      await tester.tap(find.text('Einbauen'));
      await tester.pumpAndSettle();
    }

    FilledButton placeButton(WidgetTester tester) =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Einbauen'));

    testWidgets('builds the interval course from the stored zones', (tester) async {
      await pumpWithZones(tester);
      await _openNew(tester, '2 km Intervall');
      await tester.enterText(find.byKey(const Key('course-length')), '2000');
      await tester.pump();

      await openDialog(tester);
      await choose(tester, sprint, '500');
      expect(find.text('„Sprint“ liegt bei 500–600 m.'), findsOneWidget);
      await tester.tap(find.text('Einbauen'));
      await tester.pumpAndSettle();
      await place(tester, endurance, '1000');

      expect(_sections(tester), [
        'frei · 0–500 m',
        'Sprint · 500–600 m · 1:45–1:50 · 30–34 spm',
        'frei · 600–1000 m',
        'Ausdauer 2:30 · 1000–1500 m · 2:28–2:32',
        'frei · 1500–2000 m',
      ]);
      await _save(tester, setup);

      expect(find.text('2000 m · Sprint, Ausdauer 2:30'), findsOneWidget);
      final course = (await setup.stored(tester)).single;
      expect(course.definition.placements, [
        ZonePlacement(zoneId: sprint, start: 500),
        ZonePlacement(zoneId: endurance, start: 1000),
      ]);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('does not place a zone over another one', (tester) async {
      await pumpWithZones(tester);
      await _openNew(tester, '2 km Intervall');
      await tester.enterText(find.byKey(const Key('course-length')), '2000');
      await place(tester, endurance, '1000');

      await openDialog(tester);
      await choose(tester, endurance, '1300');

      expect(find.text('„Ausdauer 2:30“ (1300–1800 m) überschneidet „Ausdauer 2:30“ (1000–1500 m).'), findsOneWidget);
      expect(placeButton(tester).onPressed, isNull);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('does not place a zone beyond the end of the course', (tester) async {
      await pumpWithZones(tester);
      await _openNew(tester, '2 km Intervall');
      await tester.enterText(find.byKey(const Key('course-length')), '2000');

      await openDialog(tester);
      await choose(tester, endurance, '1800');

      expect(find.text('„Ausdauer 2:30“ (1800–2300 m) ragt über das Streckenende bei 2000 m.'), findsOneWidget);
      expect(placeButton(tester).onPressed, isNull);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('says in English that a zone extends past the end of the course', (tester) async {
      await pumpWithZones(tester, home: const CourseEditorScreen(), locale: const Locale('en'));
      await tester.enterText(find.byKey(const Key('course-length')), '2000');

      await openDialog(tester);
      await choose(tester, endurance, '1800');

      expect(
        find.text('“Ausdauer 2:30” (1800–2300 m) extends past the end of the course at 2000 m.'),
        findsOneWidget,
      );
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('offers no zone of the other axis', (tester) async {
      await pumpWithZones(tester);
      await _openNew(tester, '2 km Intervall');
      await tester.enterText(find.byKey(const Key('course-length')), '2000');

      await openDialog(tester);

      expect(tester.widget<ListTile>(find.byKey(Key('zone-option-$minutes'))).enabled, isFalse);
      expect(find.text('4:00 · 20–22 spm · andere Achse'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('places a zone at a free gap and removes it again', (tester) async {
      await pumpWithZones(tester);
      await _openNew(tester, 'Seerunde');
      await tester.enterText(find.byKey(const Key('course-length')), '1000');
      await place(tester, endurance, '200');

      await tester.tap(find.byTooltip('Hier eine Zone einbauen').last);
      await setup.settle(tester);
      expect(tester.widget<TextField>(find.byKey(const Key('place-start'))).controller!.text, '700');
      await tester.tap(find.byKey(Key('zone-option-$sprint')));
      await tester.pump();
      await tester.tap(find.text('Einbauen'));
      await tester.pumpAndSettle();
      expect(_sections(tester).map((s) => s.split(' · ').take(2).join(' · ')), [
        'frei · 0–200 m',
        'Ausdauer 2:30 · 200–700 m',
        'Sprint · 700–800 m',
        'frei · 800–1000 m',
      ]);

      await tester.tap(find.byTooltip('Zone entfernen').first);
      await tester.pump();

      expect(_sections(tester).map((s) => s.split(' · ').take(2).join(' · ')), [
        'frei · 0–700 m',
        'Sprint · 700–800 m',
        'frei · 800–1000 m',
      ]);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('does not shorten a course below its zones', (tester) async {
      await pumpWithZones(tester);
      await _openNew(tester, '2 km Intervall');
      await tester.enterText(find.byKey(const Key('course-length')), '2000');
      await place(tester, endurance, '1000');
      await _save(tester, setup);

      await tester.tap(find.text('2 km Intervall'));
      await setup.settle(tester);
      await tester.enterText(find.byKey(const Key('course-length')), '1200');
      await _save(tester, setup);

      expect(find.text('„Ausdauer 2:30“ (1000–1500 m) ragt über das Streckenende bei 1200 m.'), findsWidgets);
      expect((await setup.stored(tester)).single.definition.length, 2000);
      await disposeWidgetsWithDatabase(tester);
    });
  });

  testWidgets('shows what keeps a course from being saved', (tester) async {
    final setup = _Setup();
    await setup.pump(tester);

    await _openNew(tester, ' ');
    await _save(tester, setup);

    expect(find.text('Der Name fehlt.'), findsOneWidget);
    expect(find.text('Die Länge fehlt.'), findsOneWidget);
    expect(await setup.stored(tester), isEmpty);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('renames a course', (tester) async {
    final setup = _Setup();
    await tester.runAsync(
      () => setup.courses.create('Seerunde', CourseDefinition.single(axis: CourseAxis.distance, length: 1000)),
    );
    await setup.pump(tester);

    await tester.tap(find.text('Seerunde'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('course-name')), 'Seerunde lang');
    await _save(tester, setup);

    expect(find.text('Seerunde lang'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('deletes a course after confirmation and names the templates it takes along', (tester) async {
    final setup = _Setup();
    await tester.runAsync(() async {
      final id = await setup.courses
          .create('Seerunde', CourseDefinition.single(axis: CourseAxis.distance, length: 1000));
      final template = await setup.db
          .into(setup.db.templates)
          .insert(TemplatesCompanion.insert(name: 'Seerunde x3', createdAt: DateTime(2026)));
      await setup.db
          .into(setup.db.templateBlocks)
          .insert(TemplateBlocksCompanion.insert(templateId: template, position: 0, courseId: id));
    });
    await setup.pump(tester);

    await tester.tap(find.byTooltip('Löschen'));
    await setup.settle(tester);
    expect(find.text('Strecke löschen?'), findsOneWidget);
    expect(find.textContaining('„Seerunde x3“'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.text('Seerunde'), findsOneWidget);

    await tester.tap(find.byTooltip('Löschen'));
    await setup.settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
    await setup.settle(tester);

    expect(find.text('Noch keine Strecken angelegt.'), findsOneWidget);
    expect(await tester.runAsync(() => setup.db.select(setup.db.templates).get()), isEmpty);
    await disposeWidgetsWithDatabase(tester);
  });
}
