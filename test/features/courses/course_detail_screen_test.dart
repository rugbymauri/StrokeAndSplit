import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/features/courses/course_detail_screen.dart';
import 'package:strokesplit/features/courses/course_editor_screen.dart';
import 'package:strokesplit/features/courses/courses_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/localized_app.dart';
import '../../support/rowed_sessions.dart';
import '../../support/test_database.dart';

class _Setup {
  final db = openTestDatabase();
  late final courses = CourseRepository(db);
  late final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);

  Future<void> pump(WidgetTester tester, {Locale locale = const Locale('de')}) async {
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: LocalizedApp(locale: locale, home: const CoursesScreen())),
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

  Future<int> seerunde(WidgetTester tester) async => (await tester.runAsync(
        () => courses.create('Seerunde', CourseDefinition.single(axis: CourseAxis.distance, length: 1000)),
      ))!;

  Future<void> row(WidgetTester tester, int courseId, List<RowedLap> laps, {DateTime? on, ErgSourceKind? source}) =>
      tester.runAsync(() async {
        final versionId = (await courses.get(courseId))!.versionId;
        await storeRowedSession(db,
            courseVersionId: versionId, laps: laps, startedAt: on, source: source ?? ErgSourceKind.pm5);
      });

  Future<void> open(WidgetTester tester, String name) async {
    await tester.tap(find.text(name));
    await settle(tester);
  }
}

/// The texts of place [place] in the ranking of [length].
List<String> _place(WidgetTester tester, String length, int place) => [
      for (final text in tester.widgetList<Text>(find.descendant(
        of: find.descendant(of: find.byKey(Key('ranking-distance-$length')), matching: find.byKey(Key('place-$place'))),
        matching: find.byType(Text),
      )))
        text.data!,
    ];

void main() {
  testWidgets('shows places 1 to 3 with value, pace and date', (tester) async {
    final setup = _Setup();
    final id = await setup.seerunde(tester);
    await setup.row(tester, id, [RowedLap.single(250000, 1000), RowedLap.single(248000, 1000)],
        on: DateTime(2026, 10, 1, 7));
    await setup.row(tester, id, [RowedLap.single(249000, 1000), RowedLap.single(251000, 1000)],
        on: DateTime(2026, 10, 5, 7));
    await setup.pump(tester);

    await setup.open(tester, 'Seerunde');

    expect(find.byType(CourseDetailScreen), findsOneWidget);
    expect(find.text('BESTENLISTE 1000 M · AKTUELL'), findsOneWidget);
    expect(_place(tester, '1000', 1), ['1', '4:08.0', '1.10.2026', '2:04 /500 m']);
    expect(_place(tester, '1000', 2), ['2', '4:09.0', '5.10.2026', '2:05 /500 m']);
    expect(_place(tester, '1000', 3), ['3', '4:10.0', '1.10.2026', '2:05 /500 m']);
    expect(find.byKey(const Key('place-4')), findsNothing);
    expect(
      find.text('Pausen zählen nicht, auch nicht in der Pace. Ausnahme: ältere Sessions ohne automatische Pause.'),
      findsOneWidget,
    );
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('shows the current length first and then the earlier one', (tester) async {
    final setup = _Setup();
    final id = await setup.seerunde(tester);
    await setup.row(tester, id, [RowedLap.single(250000, 1000)]);
    await tester.runAsync(
      () => setup.courses.updateDefinition(id, CourseDefinition.single(axis: CourseAxis.distance, length: 1200)),
    );
    await setup.row(tester, id, [RowedLap.single(300000, 1200)]);
    await setup.pump(tester);

    await setup.open(tester, 'Seerunde');

    final current = find.text('BESTENLISTE 1200 M · AKTUELL');
    final earlier = find.text('BESTENLISTE 1000 M');
    expect(current, findsOneWidget);
    expect(earlier, findsOneWidget);
    expect(tester.getTopLeft(current).dy, lessThan(tester.getTopLeft(earlier).dy));
    expect(_place(tester, '1200', 1)[1], '5:00.0');
    expect(_place(tester, '1000', 1)[1], '4:10.0');
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('shows a hint instead of places for a course without entries', (tester) async {
    final setup = _Setup();
    final id = await setup.seerunde(tester);
    await setup.row(tester, id, [RowedLap.single(250000, 1000)], source: ErgSourceKind.simulator);
    await setup.pump(tester);

    await setup.open(tester, 'Seerunde');

    expect(
      find.text('Noch keine Bestzeit. Es zählen nur vollständige Runden am Rudergerät, nicht im Simulator.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('place-1')), findsNothing);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('leads to the editor and back to the renamed course', (tester) async {
    final setup = _Setup();
    await setup.seerunde(tester);
    await setup.pump(tester);
    await setup.open(tester, 'Seerunde');

    await tester.tap(find.byTooltip('Bearbeiten'));
    await setup.settle(tester);
    expect(find.byType(CourseEditorScreen), findsOneWidget);
    await tester.enterText(find.byKey(const Key('course-name')), 'Seerunde lang');
    await tester.tap(find.byTooltip('Speichern'));
    await setup.settle(tester);

    expect(find.byType(CourseDetailScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Seerunde lang'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('closes with the course deleted while it is open', (tester) async {
    final setup = _Setup();
    final id = await setup.seerunde(tester);
    await setup.pump(tester);
    await setup.open(tester, 'Seerunde');
    expect(find.byType(CourseDetailScreen), findsOneWidget);

    await tester.runAsync(() => setup.courses.delete(id));
    await setup.settle(tester);

    expect(find.byType(CourseDetailScreen), findsNothing);
    expect(find.textContaining('Noch keine Strecken angelegt.'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('shows the details in English', (tester) async {
    final setup = _Setup();
    final id = await setup.seerunde(tester);
    await setup.row(tester, id, [RowedLap.single(250000, 1000)], on: DateTime(2026, 10, 1, 7));
    await setup.pump(tester, locale: const Locale('en'));

    await setup.open(tester, 'Seerunde');

    expect(find.text('BEST RESULTS 1000 M · CURRENT'), findsOneWidget);
    expect(_place(tester, '1000', 1), ['1', '4:10.0', '10/1/2026', '2:05 /500 m']);
    expect(find.byTooltip('Edit'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });
}
