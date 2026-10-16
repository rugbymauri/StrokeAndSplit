import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/features/courses/courses_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

class _Setup {
  final db = openTestDatabase();
  late final courses = CourseRepository(db);
  late final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);

  Future<void> pump(WidgetTester tester) async {
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MaterialApp(home: CoursesScreen())),
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

String _title(WidgetTester tester, int segment) =>
    tester.widget<Text>(find.byKey(Key('segment-$segment-title'))).data!;

void main() {
  testWidgets('creates a distance course', (tester) async {
    final setup = _Setup();
    await setup.pump(tester);
    expect(find.text('Noch keine Strecken angelegt.'), findsOneWidget);

    await _openNew(tester, 'Seerunde');
    await tester.enterText(find.byKey(const Key('course-length')), '1000');
    await tester.pump();
    expect(_title(tester, 0), 'Segment 1 · 0–1000 m · frei');
    await _save(tester, setup);

    expect(find.text('Seerunde'), findsOneWidget);
    expect(find.text('1000 m · 1 Segment'), findsOneWidget);
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

    expect(find.text('4:00 · 1 Segment'), findsOneWidget);
    final course = (await setup.stored(tester)).single;
    expect((course.axis, course.definition.length), (CourseAxis.time, 240));
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('divides a course into segments with bands', (tester) async {
    final setup = _Setup();
    await setup.pump(tester);

    await _openNew(tester, 'Seerunde');
    await tester.enterText(find.byKey(const Key('course-length')), '1000');
    await tester.tap(find.byTooltip('Segment teilen'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('segment-0-length')), '200');
    await tester.tap(find.byTooltip('Segment teilen').at(1));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('segment-1-length')), '600');
    await tester.enterText(find.byKey(const Key('segment-2-length')), '200');
    await tester.enterText(find.byKey(const Key('segment-1-pace-fast')), '2:05');
    await tester.enterText(find.byKey(const Key('segment-1-pace-slow')), '2:10');
    await tester.enterText(find.byKey(const Key('segment-1-spm-min')), '20');
    await tester.enterText(find.byKey(const Key('segment-1-spm-max')), '22');
    await tester.pump();

    expect(_title(tester, 0), 'Segment 1 · 0–200 m · frei');
    expect(_title(tester, 1), 'Segment 2 · 200–800 m · 2:05–2:10 · 20–22 spm');
    expect(_title(tester, 2), 'Segment 3 · 800–1000 m · frei');
    await _save(tester, setup);

    expect((await setup.stored(tester)).single.definition.segments, const [
      CourseSegment(length: 200),
      CourseSegment(length: 600, paceFastCs: 12500, paceSlowCs: 13000, spmMin: 20, spmMax: 22),
      CourseSegment(length: 200),
    ]);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('merges a segment with the next one', (tester) async {
    final setup = _Setup();
    await setup.pump(tester);

    await _openNew(tester, 'Seerunde');
    await tester.enterText(find.byKey(const Key('course-length')), '1000');
    await tester.tap(find.byTooltip('Segment teilen'));
    await tester.pump();
    await tester.tap(find.byTooltip('Mit nächstem zusammenlegen'));
    await tester.pump();

    expect(find.byKey(const Key('segment-1-title')), findsNothing);
    expect(_title(tester, 0), 'Segment 1 · 0–1000 m · frei');
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('shows what keeps a course from being saved', (tester) async {
    final setup = _Setup();
    await setup.pump(tester);

    await _openNew(tester, 'Seerunde');
    await _save(tester, setup);
    expect(find.text('Die Länge fehlt.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('course-length')), '1000');
    await tester.tap(find.byTooltip('Segment teilen'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('segment-1-length')), '400');
    await tester.enterText(find.byKey(const Key('segment-0-pace-fast')), '2:10');
    await tester.enterText(find.byKey(const Key('segment-0-pace-slow')), '2:05');
    await _save(tester, setup);

    expect(find.text('Segment 1: Die schnellste Pace ist langsamer als die langsamste.'), findsOneWidget);
    expect(find.text('Die Segmente ergeben 900 m, das sind 100 m zu wenig.'), findsOneWidget);
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
