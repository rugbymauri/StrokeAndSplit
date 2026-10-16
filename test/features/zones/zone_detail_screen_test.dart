import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/zones/zone.dart';
import 'package:aergrow/data/zones/zone_repository.dart';
import 'package:aergrow/features/zones/zone_detail_screen.dart';
import 'package:aergrow/features/zones/zone_editor_screen.dart';
import 'package:aergrow/features/zones/zones_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/localized_app.dart';
import '../../support/rowed_sessions.dart';
import '../../support/test_database.dart';

const _sprint = Zone(name: 'Sprint', axis: CourseAxis.distance, length: 100, paceFastCs: 9000, paceSlowCs: 10000);

class _Setup {
  final db = openTestDatabase();
  late final zones = ZoneRepository(db);
  late final courses = CourseRepository(db);
  late final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);

  Future<void> pump(WidgetTester tester) async {
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LocalizedApp(locale: Locale('de'), home: ZonesScreen()),
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

  /// The sprint in the middle of a 1000 m lake round; returns the zone id
  /// and the course id.
  Future<(int, int)> sprintInSeerunde(WidgetTester tester) async => (await tester.runAsync(() async {
        final id = await zones.create(_sprint);
        final course = await courses.create(
          'Seerunde',
          CourseDefinition(axis: CourseAxis.distance, length: 1000, segments: [
            const CourseSegment(length: 450),
            _sprint.copyWith(id: id).segment,
            const CourseSegment(length: 450),
          ]),
        );
        return (id, course);
      }))!;

  /// Rows the lake round once per sprint time in [sprints], in ms.
  Future<void> row(WidgetTester tester, int course, List<int> sprints, {int metres = 100, DateTime? on}) =>
      tester.runAsync(() async {
        final versionId = (await courses.get(course))!.versionId;
        await storeRowedSession(db, courseVersionId: versionId, startedAt: on, laps: [
          for (final ms in sprints) RowedLap([(110000, 450), (ms, metres), (110000, 450)]),
        ]);
      });

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('Sprint'));
    await settle(tester);
  }
}

/// The texts of place [place] in the ranking of [length] m.
List<String> _place(WidgetTester tester, int length, int place) => [
      for (final text in tester.widgetList<Text>(find.descendant(
        of: find.descendant(of: find.byKey(Key('ranking-distance-$length')), matching: find.byKey(Key('place-$place'))),
        matching: find.byType(Text),
      )))
        text.data!,
    ];

void main() {
  testWidgets('shows the three fastest sprints with time, pace and date', (tester) async {
    final setup = _Setup();
    final (_, course) = await setup.sprintInSeerunde(tester);
    await setup.row(tester, course, [18900, 18200], on: DateTime(2026, 10, 1, 7));
    await setup.row(tester, course, [19500, 18500], on: DateTime(2026, 10, 5, 7));
    await setup.pump(tester);

    await setup.open(tester);

    expect(find.byType(ZoneDetailScreen), findsOneWidget);
    expect(find.text('BESTENLISTE 100 M · AKTUELL'), findsOneWidget);
    expect(_place(tester, 100, 1), ['1', '0:18.2', '1.10.2026', '1:31.0 /500 m']);
    expect(_place(tester, 100, 2), ['2', '0:18.5', '5.10.2026', '1:32.5 /500 m']);
    expect(_place(tester, 100, 3), ['3', '0:18.9', '1.10.2026', '1:34.5 /500 m']);
    expect(find.byKey(const Key('place-4')), findsNothing);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('shows a ranking per length of the zone, the current one first', (tester) async {
    final setup = _Setup();
    final (id, course) = await setup.sprintInSeerunde(tester);
    await setup.row(tester, course, [18200]);
    await tester.runAsync(() => setup.zones.update(_sprint.copyWith(id: id, length: 150)));
    await setup.row(tester, course, [28000], metres: 150);
    await setup.pump(tester);

    await setup.open(tester);

    final current = find.text('BESTENLISTE 150 M · AKTUELL');
    final earlier = find.text('BESTENLISTE 100 M');
    expect(current, findsOneWidget);
    expect(earlier, findsOneWidget);
    expect(tester.getTopLeft(current).dy, lessThan(tester.getTopLeft(earlier).dy));
    expect(_place(tester, 150, 1)[1], '0:28.0');
    expect(_place(tester, 100, 1)[1], '0:18.2');
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('shows a hint for a zone never rowed and leads to the editor', (tester) async {
    final setup = _Setup();
    await setup.sprintInSeerunde(tester);
    await setup.pump(tester);
    await setup.open(tester);

    expect(find.byKey(const Key('ranking-empty')), findsOneWidget);
    await tester.tap(find.byTooltip('Bearbeiten'));
    await setup.settle(tester);

    expect(find.byType(ZoneEditorScreen), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('closes with the zone deleted in the editor', (tester) async {
    final setup = _Setup();
    await tester.runAsync(() => setup.zones.create(_sprint));
    await setup.pump(tester);
    await setup.open(tester);
    await tester.tap(find.byTooltip('Bearbeiten'));
    await setup.settle(tester);

    await tester.tap(find.byTooltip('Löschen'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Löschen')));
    await setup.settle(tester);

    expect(find.byType(ZoneDetailScreen), findsNothing);
    expect(find.textContaining('Noch keine Zonen angelegt.'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });
}
