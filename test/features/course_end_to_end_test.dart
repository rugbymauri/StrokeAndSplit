import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_layout.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/sessions/session_repository.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/data/sources/rower_choice.dart';
import 'package:aergrow/data/sources/simulated_source.dart';
import 'package:aergrow/data/templates/template_repository.dart';
import 'package:aergrow/data/zones/zone.dart';
import 'package:aergrow/data/zones/zone_repository.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:aergrow/features/connection/start_screen.dart';
import 'package:aergrow/features/sessions/session_summary_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_ble_transport.dart';
import '../support/test_database.dart';
import '../support/localized_app.dart';

/// Laps and segments of a session, to compare two copies.
Future<List<Object>> _results(AppDatabase db, int id) async => [
      for (final l in await SessionRepository(db).laps(id))
        (l.lapNo, l.endWallMs - l.startWallMs, l.endDistanceDm - l.startDistanceDm, l.complete, l.inZoneShare),
      for (final s in await (db.select(db.lapSegments)..where((s) => s.sessionId.equals(id))).get())
        (s.lapNo, s.position, s.durationMs, s.distanceDm, s.inZoneShare),
    ];

void main() {
  testWidgets('rows a template with the simulator, pauses, and exports and imports the session', (tester) async {
    final db = openTestDatabase();
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      wakelockProvider.overrideWithValue(FakeWakelock()),
      rowerChoiceStoreProvider.overrideWithValue(MemoryRowerChoiceStore(const RowerChoice.simulator())),
    ]);
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      final course = await CourseRepository(db).create(
        'Dreiteiler',
        const CourseDefinition(axis: CourseAxis.distance, length: 120, segments: [
          CourseSegment(length: 40),
          CourseSegment(length: 40, paceFastCs: 12500, paceSlowCs: 13500),
          CourseSegment(length: 40, spmMin: 20, spmMax: 24),
        ]),
      );
      await TemplateRepository(db).create('Dreiteiler x2', courseId: course, laps: 2);
    });
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const LocalizedApp(home: StartScreen()),
    ));

    await tester.tap(find.text('Rudern'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Dreiteiler x2'));
    Future<void> row(Duration duration) async {
      for (var i = 0; i < duration.inMilliseconds ~/ 250; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    await row(const Duration(seconds: 2));
    expect(find.text('Runde 1 / 2'), findsOneWidget);
    final simulator = container.read(activeErgSourceProvider)! as SimulatedSource;
    await row(const Duration(seconds: 15));
    // Too slow for the band of segment 2, then a pause in it.
    simulator.targetPace = const Duration(minutes: 2, seconds: 25);
    await row(const Duration(seconds: 5));
    simulator.pause();
    await row(const Duration(seconds: 10));
    simulator
      ..resume()
      ..targetPace = const Duration(minutes: 2, seconds: 10);
    await row(const Duration(seconds: 90));

    expect(find.byType(SessionSummaryScreen), findsOneWidget);
    final id = (await tester.runAsync(() => db.select(db.sessions).getSingle()))!.id;
    final recorded = (await tester.runAsync(() => _results(db, id)))!;
    final laps = (await tester.runAsync(() => SessionRepository(db).laps(id)))!;
    expect([for (final l in laps) l.complete], [true, true]);
    expect(laps.first.inZoneShare, lessThan(laps.last.inZoneShare!));
    // The pause counts in the time of lap 1.
    int duration(LapRow lap) => lap.endWallMs - lap.startWallMs;
    expect(duration(laps.first), greaterThan(duration(laps.last) + 8000));

    final laptop = openTestDatabase();
    final imported = await tester.runAsync(() async {
      final bytes = await SessionRepository(db).export(id);
      final imported = await SessionRepository(laptop).import(bytes);
      return _results(laptop, imported);
    });
    expect(imported, recorded);

    await container.read(activeErgSourceProvider.notifier).clear();
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('rows a template with a zone with the simulator as an FTMS rower', (tester) async {
    final db = openTestDatabase();
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      wakelockProvider.overrideWithValue(FakeWakelock()),
      rowerChoiceStoreProvider.overrideWithValue(MemoryRowerChoiceStore(const RowerChoice.simulator(ErgProtocol.ftms))),
    ]);
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      const tempo = Zone(name: 'Tempo', axis: CourseAxis.distance, length: 40, paceFastCs: 12500, paceSlowCs: 13500);
      final zoneId = await ZoneRepository(db).create(tempo);
      final definition = resolveCourse(
        axis: CourseAxis.distance,
        length: 120,
        placements: [ZonePlacement(zoneId: zoneId, start: 40)],
        zones: {zoneId: tempo.copyWith(id: zoneId)},
      ).definition!;
      final course = await CourseRepository(db).create('Seerunde', definition);
      await TemplateRepository(db).create('Seerunde x2', courseId: course, laps: 2);
    });
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const LocalizedApp(home: StartScreen()),
    ));

    await tester.tap(find.text('Rudern'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Seerunde x2'));
    for (var i = 0; i < 100 * 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.byType(SessionSummaryScreen), findsOneWidget);
    expect(find.text('Simulator (FTMS)'), findsOneWidget);
    final session = (await tester.runAsync(() => db.select(db.sessions).getSingle()))!;
    expect((session.protocol, session.templateName), (ErgProtocol.ftms, 'Seerunde x2'));
    final laps = (await tester.runAsync(() => SessionRepository(db).laps(session.id)))!;
    expect([for (final l in laps) l.complete], [true, true]);
    expect(laps.every((l) => l.inZoneShare != null), isTrue);
    final strokes = (await tester.runAsync(() => db.select(db.strokes).get()))!;
    expect(strokes, isNotEmpty);
    expect(strokes.every((s) => s.driveTimeMs == null), isTrue);

    await container.read(activeErgSourceProvider.notifier).clear();
    await disposeWidgetsWithDatabase(tester);
  });
}
