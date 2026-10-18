import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/templates/session_template.dart';
import 'package:aergrow/data/templates/template_repository.dart';
import 'package:aergrow/data/zones/zone.dart';
import 'package:aergrow/data/zones/zone_repository.dart';
import 'package:aergrow/features/sessions/session_summary_screen.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/rowed_sessions.dart';
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

/// The place marks in the lap row with [key].
List<String> _marks(WidgetTester tester, Key key) => [
      for (final text in tester.widgetList<Text>(find.descendant(
        of: find.byKey(key),
        matching: find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains('Platz')),
      )))
        text.data!,
    ];

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
    for (final value in ['Ø Pace 2:05', 'Ø spm 22,5', 'Ø Watt 178', 'Schläge 236']) {
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

  group('places', () {
    late AppDatabase db;

    setUp(() => db = openTestDatabase());

    /// A template "Seerunde x[laps]" on a new 1000 m course.
    Future<SessionTemplate> template(WidgetTester tester, {int laps = 3}) async => (await tester.runAsync(() async {
          final courseId = await CourseRepository(db).create(
            'Seerunde',
            CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
          );
          final templates = TemplateRepository(db);
          return (await templates.get(await templates.create('Seerunde x$laps', courseId: courseId, laps: laps)))!;
        }))!;

    Future<int> row(
      WidgetTester tester,
      SessionTemplate template,
      List<int> seconds, {
      int day = 1,
      ErgSourceKind source = ErgSourceKind.pm5,
    }) async =>
        (await tester.runAsync(() => storeRowedSession(
              db,
              template: template,
              source: source,
              startedAt: DateTime(2026, 10, day, 7),
              laps: [for (final s in seconds) RowedLap.single(s * 1000, 1000)],
            )))!;

    testWidgets('marks a new second best lap', (tester) async {
      final seerunde = await template(tester);
      await row(tester, seerunde, [245, 260, 262]);
      final id = await row(tester, seerunde, [252, 248, 255], day: 2);
      await _pump(tester, db, id);

      expect(_marks(tester, const Key('lap-best')), ['Platz 2']);
      expect(_marks(tester, const Key('lap-1')), ['Platz 3']);
      expect(_marks(tester, const Key('lap-3')), isEmpty);
      // 755 s after 767 s of the earlier session.
      expect(
        find.descendant(of: find.byKey(const Key('session-place')), matching: find.text('Platz 1')),
        findsOneWidget,
      );
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('drops the mark of a lap overtaken later', (tester) async {
      final seerunde = await template(tester, laps: 1);
      final id = await row(tester, seerunde, [248]);
      await row(tester, seerunde, [245], day: 2);
      await row(tester, seerunde, [240], day: 3);
      await row(tester, seerunde, [242], day: 4);
      await _pump(tester, db, id);

      expect(_lap(tester, const Key('lap-best')), '4:08.0');
      expect(_marks(tester, const Key('lap-best')), isEmpty);
      expect(find.byKey(const Key('session-place')), findsNothing);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('gives no marks to a simulated session', (tester) async {
      final seerunde = await template(tester);
      final id = await row(tester, seerunde, [252, 248, 255], source: ErgSourceKind.simulator);
      await _pump(tester, db, id);

      expect(find.textContaining('Platz'), findsNothing);
      expect(find.byKey(const Key('session-place')), findsNothing);
      // The best lap of the session is still marked.
      expect(find.byIcon(Icons.star), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('marks the session on place 1 of its template', (tester) async {
      final seerunde = await template(tester, laps: 2);
      await row(tester, seerunde, [250, 250]);
      final id = await row(tester, seerunde, [246, 249], day: 2);
      await _pump(tester, db, id, locale: const Locale('en'));

      expect(
        find.descendant(of: find.byKey(const Key('session-place')), matching: find.text('Place 1')),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => w is Text && w.semanticsLabel == 'Place 1 for the template'),
        findsOneWidget,
      );
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('marks the runs through a zone', (tester) async {
      final sprintrunde = await tester.runAsync(() async {
        const sprint =
            Zone(name: 'Sprint', axis: CourseAxis.distance, length: 100, paceFastCs: 9000, paceSlowCs: 10000);
        final sprintId = await ZoneRepository(db).create(sprint);
        final placed = sprint.copyWith(id: sprintId).segment;
        final courseId = await CourseRepository(db).create(
          'Sprintrunde',
          CourseDefinition(axis: CourseAxis.distance, length: 1000, segments: [
            const CourseSegment(length: 400),
            placed,
            const CourseSegment(length: 400),
            placed,
          ]),
        );
        final templates = TemplateRepository(db);
        return (await templates.get(await templates.create('Sprintrunde x2', courseId: courseId, laps: 2)))!;
      });
      final id = (await tester.runAsync(() => storeRowedSession(db, template: sprintrunde!, laps: [
            const RowedLap([(100000, 400), (20000, 100), (100000, 400), (21000, 100)]),
            const RowedLap([(100000, 400), (19000, 100), (99000, 400), (22000, 100)]),
          ])))!;
      await _pump(tester, db, id);

      expect(_marks(tester, const Key('lap-1')), ['Platz 2', 'Sprint · Platz 2', 'Sprint · Platz 3']);
      expect(_marks(tester, const Key('lap-best')), ['Platz 1', 'Sprint · Platz 1']);
      await disposeWidgetsWithDatabase(tester);
    });
  });

  group('heart rate', () {
    /// Stores a PM5 session with the given heart rate summary and RR intervals.
    Future<int> heartRateSession(
      AppDatabase db, {
      int? average,
      int? max,
      int? rmssd,
      List<(int, int)> intervals = const [],
    }) async {
      final id = await db.into(db.sessions).insert(SessionsCompanion.insert(
            startedAt: _startedAt,
            status: SessionStatus.complete,
            source: ErgSourceKind.pm5,
            durationMs: const Value(630000),
            distanceDm: const Value(25120),
            averageHeartRate: Value(average),
            maxHeartRate: Value(max),
            rmssdMs: Value(rmssd),
          ));
      for (final (tMs, rrMs) in intervals) {
        await db.into(db.rrIntervals).insert(RrIntervalsCompanion.insert(sessionId: id, tMs: tMs, rrMs: rrMs));
      }
      return id;
    }

    testWidgets('shows average and maximum, the RR curve and the RMSSD with RR intervals', (tester) async {
      final semantics = tester.ensureSemantics();
      final db = openTestDatabase();
      final id = await tester.runAsync(() => heartRateSession(
            db,
            average: 142,
            max: 171,
            rmssd: 16,
            intervals: [(800, 800), (1610, 810), (2400, 790)],
          ));
      await _pump(tester, db, id!);

      expect(find.text('Ø Puls 142'), findsOneWidget);
      expect(find.text('Max. Puls 171'), findsOneWidget);
      expect(find.text('RR-INTERVALLE'), findsOneWidget);
      expect(find.byKey(const Key('summary-rr-curve')), findsOneWidget);
      expect(find.text('HRV (RMSSD) 16 ms'), findsOneWidget);
      expect(find.text('810 ms'), findsOneWidget);
      expect(find.text('790 ms'), findsOneWidget);
      expect(find.bySemanticsLabel('Verlauf der RR-Intervalle zwischen 790 und 810 ms'), findsOneWidget);
      final painter = tester
          .widget<CustomPaint>(find.descendant(
            of: find.byKey(const Key('summary-rr-curve')),
            matching: find.byType(CustomPaint),
          ))
          .painter! as RrCurvePainter;
      expect(painter.points, [(800, 800), (1610, 810), (2400, 790)]);
      semantics.dispose();
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('shows only average and maximum with the heart rate from the rower', (tester) async {
      final db = openTestDatabase();
      final id = await tester.runAsync(() => heartRateSession(db, average: 138, max: 165));
      await _pump(tester, db, id!);

      expect(find.text('Ø Puls 138'), findsOneWidget);
      expect(find.text('Max. Puls 165'), findsOneWidget);
      expect(find.text('RR-INTERVALLE'), findsNothing);
      expect(find.byKey(const Key('summary-rr-curve')), findsNothing);
      expect(find.textContaining('RMSSD'), findsNothing);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('shows no heart rate values without a heart rate', (tester) async {
      final db = openTestDatabase();
      final id = await tester.runAsync(() => heartRateSession(db));
      await _pump(tester, db, id!);

      expect(find.textContaining('Puls'), findsNothing);
      expect(find.text('RR-INTERVALLE'), findsNothing);
      expect(find.textContaining('RMSSD'), findsNothing);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('shows the heart rate values in English', (tester) async {
      final db = openTestDatabase();
      final id = await tester.runAsync(() => heartRateSession(
            db,
            average: 142,
            max: 171,
            rmssd: 16,
            intervals: [(800, 800), (1610, 810), (2400, 790)],
          ));
      await _pump(tester, db, id!, locale: const Locale('en'));

      expect(find.text('Ø Heart rate 142'), findsOneWidget);
      expect(find.text('Max heart rate 171'), findsOneWidget);
      expect(find.text('RR INTERVALS'), findsOneWidget);
      expect(find.text('HRV (RMSSD) 16 ms'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });
  });
}
