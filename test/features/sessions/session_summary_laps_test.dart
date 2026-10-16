import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/features/sessions/session_summary_screen.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';
import '../../support/localized_app.dart';

/// Stores a session on [course] with laps of the given (seconds, metres).
Future<int> _session(AppDatabase db, String name, CourseDefinition course, List<(int, int, bool)> laps) async {
  final courseId = await CourseRepository(db).create(name, course);
  final versionId = (await CourseRepository(db).get(courseId))!.versionId;
  final id = await db.into(db.sessions).insert(SessionsCompanion.insert(
        startedAt: DateTime(2026, 10, 16, 7),
        status: SessionStatus.complete,
        source: ErgSourceKind.simulator,
        templateName: Value('$name x${laps.length}'),
        courseVersionId: Value(versionId),
        plannedLaps: Value(laps.length),
      ));
  var wall = 0;
  var distance = 0;
  for (final (i, (seconds, meters, complete)) in laps.indexed) {
    await db.into(db.laps).insert(LapsCompanion.insert(
          sessionId: id,
          lapNo: i + 1,
          startWallMs: wall,
          endWallMs: wall += seconds * 1000,
          startDistanceDm: distance,
          endDistanceDm: distance += meters * 10,
          complete: complete,
          inZoneShare: const Value(0.75),
        ));
  }
  return id;
}

Future<void> _pump(WidgetTester tester, AppDatabase db, int id) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: LocalizedApp(home: SessionSummaryScreen(sessionId: id)),
  ));
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
  }
}

String _lap(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.descendant(of: find.byKey(key), matching: find.byType(Text)).last).data!;

void main() {
  testWidgets('shows the lap times of a distance course and highlights the best', (tester) async {
    final db = openTestDatabase();
    final id = await tester.runAsync(() => _session(
          db,
          'Seerunde',
          CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
          [(252, 1000, true), (248, 1000, true), (255, 1000, true), (100, 400, false)],
        ));
    await _pump(tester, db, id!);

    expect(find.text('Seerunde x4'), findsOneWidget);
    expect(find.text('Seerunde · 1000 m'), findsOneWidget);
    expect(_lap(tester, const Key('lap-1')), '4:12.0 · Zone 75 %');
    expect(_lap(tester, const Key('lap-best')), '4:08.0 · Zone 75 %');
    expect(_lap(tester, const Key('lap-3')), '4:15.0 · Zone 75 %');
    expect(_lap(tester, const Key('lap-4')), 'unvollständig · 400 m · 1:40.0 · Zone 75 %');
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('shows the lap distances of a time course and highlights the longest', (tester) async {
    final db = openTestDatabase();
    final id = await tester.runAsync(() => _session(
          db,
          'Vier Minuten',
          CourseDefinition.single(axis: CourseAxis.time, length: 240),
          [(240, 1012, true), (240, 1030, true), (240, 998, true)],
        ));
    await _pump(tester, db, id!);

    expect(find.text('Vier Minuten · 4:00'), findsOneWidget);
    expect(_lap(tester, const Key('lap-1')), '1012 m · Zone 75 %');
    expect(_lap(tester, const Key('lap-best')), '1030 m · Zone 75 %');
    expect(_lap(tester, const Key('lap-3')), '998 m · Zone 75 %');
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('shows no laps for a free session', (tester) async {
    final db = openTestDatabase();
    final id = await tester.runAsync(() => db.into(db.sessions).insert(SessionsCompanion.insert(
          startedAt: DateTime(2026, 10, 16, 7),
          status: SessionStatus.complete,
          source: ErgSourceKind.simulator,
        )));
    await _pump(tester, db, id!);

    expect(find.textContaining('Runde'), findsNothing);
    await disposeWidgetsWithDatabase(tester);
  });
}
