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

final _startedAt = DateTime(2026, 10, 16, 7);

/// Stores a session on [course] with laps of the given (seconds, metres, complete, share in the zone).
Future<int> _session(
  AppDatabase db,
  String name,
  CourseDefinition course,
  List<(int, int, bool, double?)> laps,
) async {
  final courseId = await CourseRepository(db).create(name, course);
  final versionId = (await CourseRepository(db).get(courseId))!.versionId;
  final id = await db.into(db.sessions).insert(SessionsCompanion.insert(
        startedAt: _startedAt,
        status: SessionStatus.complete,
        source: ErgSourceKind.simulator,
        templateName: Value('$name x${laps.length}'),
        courseVersionId: Value(versionId),
        plannedLaps: Value(laps.length),
        durationMs: Value(laps.fold(0, (sum, lap) => sum + lap.$1 * 1000)),
        distanceDm: Value(laps.fold(0, (sum, lap) => sum + lap.$2 * 10)),
      ));
  var wall = 0;
  var distance = 0;
  for (final (i, (seconds, meters, complete, share)) in laps.indexed) {
    await db.into(db.laps).insert(LapsCompanion.insert(
          sessionId: id,
          lapNo: i + 1,
          startWallMs: wall,
          endWallMs: wall += seconds * 1000,
          startDistanceDm: distance,
          endDistanceDm: distance += meters * 10,
          complete: complete,
          inZoneShare: Value(share),
        ));
  }
  return id;
}

Future<void> _pump(WidgetTester tester, AppDatabase db, int id, {Locale locale = const Locale('de')}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: LocalizedApp(
      locale: locale,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => SessionSummaryScreen(sessionId: id))),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// The value of the lap row with [key].
String _lap(WidgetTester tester, Key key) => tester
    .widget<Text>(find.descendant(
      of: find.descendant(of: find.byKey(key), matching: find.byKey(const Key('lap-value'))),
      matching: find.byType(Text),
    ))
    .textSpan!
    .toPlainText();

/// How far the in-zone bar of the lap row with [key] is filled; null without a bar.
double? _bar(WidgetTester tester, Key key) {
  final bar = find.descendant(of: find.byKey(key), matching: find.byType(FractionallySizedBox));
  return bar.evaluate().isEmpty ? null : tester.widget<FractionallySizedBox>(bar).widthFactor;
}

String _caption(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.descendant(of: find.byKey(key), matching: find.byType(Text)).at(1)).data!;

void main() {
  testWidgets('shows the totals and laps of a distance course and marks the best lap', (tester) async {
    final db = openTestDatabase();
    final id = await tester.runAsync(() => _session(
          db,
          'Seerunde',
          CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
          [(252, 1000, true, 0.9), (248, 1000, true, 0.8), (255, 1000, true, 0.6), (100, 400, false, 0.5)],
        ));
    await _pump(tester, db, id!);

    expect(find.text('Session beendet'), findsOneWidget);
    expect(find.text('16.10.2026, 07:00 · 4 × 1000 m'), findsOneWidget);
    expect(find.text('Seerunde x4'), findsOneWidget);
    expect(find.text('Simulator'), findsOneWidget);
    expect(find.text('14:15'), findsOneWidget);
    expect(find.text('3400 m'), findsOneWidget);
    // No share in the zone for the whole session, only per lap.
    expect(find.text('In der Zone'), findsNothing);
    expect(find.text('73 %'), findsNothing);
    expect(find.text('RUNDEN'), findsOneWidget);
    expect(find.text('Balken: Anteil in der Zone pro Runde'), findsOneWidget);

    expect(_lap(tester, const Key('lap-1')), '4:12.0');
    expect(_lap(tester, const Key('lap-best')), '4:08.0');
    expect(_lap(tester, const Key('lap-3')), '4:15.0');
    expect(_lap(tester, const Key('lap-4')), '400 m');
    expect(_caption(tester, const Key('lap-4')), 'unvollständig · 1:40.0');
    expect([for (final key in ['lap-1', 'lap-best', 'lap-3', 'lap-4']) _bar(tester, Key(key))], [0.9, 0.8, 0.6, 0.5]);
    expect(find.descendant(of: find.byKey(const Key('lap-best')), matching: find.byIcon(Icons.star)), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Zone 80 %'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('shows the lap distances of a time course and marks the longest', (tester) async {
    final db = openTestDatabase();
    final id = await tester.runAsync(() => _session(
          db,
          'Vier Minuten',
          CourseDefinition.single(axis: CourseAxis.time, length: 240),
          [(240, 1012, true, 0.75), (240, 1030, true, 0.75), (240, 998, true, 0.75)],
        ));
    await _pump(tester, db, id!);

    expect(find.text('16.10.2026, 07:00 · 3 × 4:00'), findsOneWidget);
    expect(find.text('12:00'), findsOneWidget);
    expect(find.text('3040 m'), findsOneWidget);
    expect(find.text('75 %'), findsNothing);
    expect(_lap(tester, const Key('lap-1')), '1012 m');
    expect(_lap(tester, const Key('lap-best')), '1030 m');
    expect(_lap(tester, const Key('lap-3')), '998 m');
    expect(_bar(tester, const Key('lap-3')), 0.75);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('shows laps without bars on a course without bands', (tester) async {
    final db = openTestDatabase();
    final id = await tester.runAsync(() => _session(
          db,
          'Seerunde',
          CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
          [(252, 1000, true, null), (248, 1000, true, null)],
        ));
    await _pump(tester, db, id!);

    expect(_lap(tester, const Key('lap-1')), '4:12.0');
    expect(_bar(tester, const Key('lap-1')), isNull);
    expect(find.text('In der Zone'), findsNothing);
    expect(find.text('Balken: Anteil in der Zone pro Runde'), findsNothing);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('shows a free session without laps and closes with done', (tester) async {
    final db = openTestDatabase();
    final id = await tester.runAsync(() => db.into(db.sessions).insert(SessionsCompanion.insert(
          startedAt: _startedAt,
          status: SessionStatus.complete,
          source: ErgSourceKind.simulator,
          durationMs: const Value(630000),
          distanceDm: const Value(25120),
          averagePaceCs: const Value(12540),
          averageWatts: const Value(178),
          averageStrokeRate: const Value(22.5),
          strokeCount: const Value(236),
        )));
    await _pump(tester, db, id!);

    expect(find.text('Session beendet'), findsOneWidget);
    expect(find.text('16.10.2026, 07:00'), findsOneWidget);
    expect(find.text('Simulator'), findsOneWidget);
    expect(find.text('10:30'), findsOneWidget);
    expect(find.text('2512 m'), findsOneWidget);
    expect(find.text('In der Zone'), findsNothing);
    expect(find.text('RUNDEN'), findsNothing);
    for (final value in ['Ø Pace 2:05.4', 'Ø spm 22,5', 'Ø Watt 178', 'Schläge 236']) {
      expect(find.text(value), findsOneWidget, reason: value);
    }
    expect(find.widgetWithText(OutlinedButton, 'Abspielen'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Fertig'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionSummaryScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('shows the summary in English', (tester) async {
    final db = openTestDatabase();
    final id = await tester.runAsync(() => _session(
          db,
          'Seerunde',
          CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
          [(252, 1000, true, 0.75), (100, 400, false, 0.75)],
        ));
    await _pump(tester, db, id!, locale: const Locale('en'));

    expect(find.text('Session finished'), findsOneWidget);
    expect(find.text('Simulator'), findsOneWidget);
    for (final label in ['Time', 'Distance', 'LAPS', 'Bar: share in the zone per lap']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(_caption(tester, const Key('lap-2')), 'incomplete · 1:40.0');
    expect(find.textContaining('Ø spm'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Icon && w.semanticLabel == 'Best lap'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Play back'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Done'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });
}
