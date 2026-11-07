import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strokesplit/app/platform_providers.dart';
import 'package:strokesplit/app/strokesplit_app.dart';
import 'package:strokesplit/data/health/health_export.dart';
import 'package:strokesplit/data/health/health_platform.dart';
import 'package:strokesplit/data/health/health_exercise.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sessions/session_repository.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/features/sessions/session_summary_screen.dart';
import 'package:strokesplit/features/sessions/sessions_screen.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/fake_health_platform.dart';
import '../../support/localized_app.dart';
import '../../support/test_database.dart';

class _Setup {
  _Setup({bool enabled = true}) : store = MemoryHealthExportStore(enabled);

  final health = FakeHealthPlatform(granted: HealthKind.values.toSet());
  final MemoryHealthExportStore store;
  final db = openTestDatabase();
  late final repository = SessionRepository(db);
  late final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      wakelockProvider.overrideWithValue(FakeWakelock()),
      bleTransportProvider.overrideWithValue(FakeBleTransport()),
      healthPlatformProvider.overrideWithValue(health),
      healthExportStoreProvider.overrideWithValue(store),
      healthExportAvailableProvider.overrideWithValue(true),
    ],
  );

  Future<int> addSession(
    WidgetTester tester, {
    ErgSourceKind source = ErgSourceKind.pm5,
    DateTime? at,
  }) async => (await tester.runAsync(() async {
    final id = await repository.create(
      startedAt: at ?? DateTime(2026, 11, 2, 18),
      source: source,
    );
    await repository.finish(
      id,
      endedAt: (at ?? DateTime(2026, 11, 2, 18)).add(
        const Duration(minutes: 8),
      ),
    );
    return id;
  }))!;

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: LocalizedApp(home: home),
      ),
    );
    await tester.pump();
  }

  /// Sends from the summary; the write runs on the real clock because of the database.
  Future<void> send(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('summary-health-send')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
  }
}

void main() {
  group('session list', () {
    testWidgets('offers sending only sessions from a rower', (tester) async {
      final setup = _Setup();
      await setup.addSession(tester, at: DateTime(2026, 11, 2, 18));
      await setup.addSession(
        tester,
        source: ErgSourceKind.simulator,
        at: DateTime(2026, 11, 1, 18),
      );
      await setup.pump(tester, const SessionsScreen());

      await tester.tap(find.byTooltip('Aktionen').first);
      await tester.pumpAndSettle();
      expect(find.text('An Health Connect senden'), findsOneWidget);
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Aktionen').last);
      await tester.pumpAndSettle();
      expect(find.text('An Health Connect senden'), findsNothing);
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('offers nothing while sending is off', (tester) async {
      final setup = _Setup(enabled: false);
      await setup.addSession(tester);
      await setup.pump(tester, const SessionsScreen());

      await tester.tap(find.byTooltip('Aktionen'));
      await tester.pumpAndSettle();
      expect(find.text('An Health Connect senden'), findsNothing);
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('sends a session from the menu', (tester) async {
      final setup = _Setup();
      await setup.addSession(tester);
      await setup.pump(tester, const SessionsScreen());

      await tester.tap(find.byTooltip('Aktionen'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('An Health Connect senden'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(setup.health.exercises, hasLength(1));
      expect(find.text('An Health Connect übertragen.'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });
  });

  group('summary', () {
    testWidgets('shows the status before and after sending', (tester) async {
      final setup = _Setup();
      final id = await setup.addSession(tester);
      await setup.pump(tester, SessionSummaryScreen(sessionId: id));

      expect(find.text('Nicht an Health Connect übertragen'), findsOneWidget);
      await setup.send(tester);

      expect(setup.health.exercises, hasLength(1));
      expect(
        find.textContaining('An Health Connect übertragen am '),
        findsOneWidget,
      );
      expect(find.text('An Health Connect übertragen.'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('shows neither status nor button for the simulator', (
      tester,
    ) async {
      final setup = _Setup();
      final id = await setup.addSession(
        tester,
        source: ErgSourceKind.simulator,
      );
      await setup.pump(tester, SessionSummaryScreen(sessionId: id));

      expect(find.byKey(const Key('summary-health-status')), findsNothing);
      expect(find.byKey(const Key('summary-health-send')), findsNothing);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('reports a failure and keeps the session not sent', (
      tester,
    ) async {
      final setup = _Setup();
      setup.health.failure = HealthFailure.failed;
      final id = await setup.addSession(tester);
      await setup.pump(tester, SessionSummaryScreen(sessionId: id));

      await setup.send(tester);

      expect(
        find.text('Übertragung an Health Connect fehlgeschlagen.'),
        findsOneWidget,
      );
      expect(find.text('Nicht an Health Connect übertragen'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('offers to grant a withdrawn permission again', (tester) async {
      final setup = _Setup();
      setup.health.granted = {};
      final id = await setup.addSession(tester);
      await setup.pump(tester, SessionSummaryScreen(sessionId: id));

      await setup.send(tester);
      expect(
        find.text('Stroke & Split darf nicht an Health Connect schreiben.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Erteilen'));
      await tester.pumpAndSettle();
      expect(setup.health.granted, HealthKind.values.toSet());
      await disposeWidgetsWithDatabase(tester);
    });
  });

  testWidgets(
    'the app reports a failed send after a session wherever the user is',
    (tester) async {
      final setup = _Setup();
      addTearDown(setup.container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: setup.container,
          child: const StrokeSplitApp(),
        ),
      );
      await tester.pump();

      setup.container
          .read(healthExportFailureProvider.notifier)
          .report(1, HealthFailure.unavailable);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Health Connect ist nicht verfügbar.'), findsOneWidget);
      expect(setup.container.read(healthExportFailureProvider), isNull);
      await tester.pump(const Duration(seconds: 15));
      await disposeWidgetsWithDatabase(tester);
    },
  );
}
