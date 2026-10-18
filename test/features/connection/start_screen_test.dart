import 'package:aergrow/app/aergrow_app.dart';
import 'package:aergrow/app/app_language.dart';
import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/sessions/session_repository.dart';
import 'package:aergrow/data/sources/ble/ble_transport.dart';
import 'package:aergrow/data/sources/ble/heart_rate_transport.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/data/sources/heart_rate_choice.dart';
import 'package:aergrow/data/sources/rower_choice.dart';
import 'package:aergrow/data/templates/template_repository.dart';
import 'package:aergrow/features/connection/choose_devices_screen.dart';
import 'package:aergrow/features/connection/start_screen.dart';
import 'package:aergrow/features/live/live_screen.dart';
import 'package:aergrow/features/sessions/sessions_screen.dart';
import 'package:aergrow/features/templates/templates_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/localized_app.dart';
import '../../support/test_database.dart';

const _pm5 = FoundRower(id: 'C0:00:00:00:00:01', name: 'PM5 430000001 Row');
const _h10 = FoundHeartRateMonitor(id: 'A0:9E:1A:00:00:01', name: 'Polar H10 1A2B3C4D');

ProviderContainer _container({
  RowerChoice? chosen,
  FakeBleTransport? transport,
  LanguageStore? languages,
  AppDatabase? db,
  FoundHeartRateMonitor? strap,
}) {
  final container = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db ?? openTestDatabase()),
    wakelockProvider.overrideWithValue(FakeWakelock()),
    bleTransportProvider.overrideWithValue(transport ?? FakeBleTransport()),
    rowerChoiceStoreProvider.overrideWithValue(MemoryRowerChoiceStore(chosen)),
    languageStoreProvider.overrideWithValue(languages ?? MemoryLanguageStore()),
    heartRateMonitorStoreProvider.overrideWithValue(MemoryHeartRateMonitorStore(strap)),
  ]);
  addTearDown(container.dispose);
  return container;
}

Future<ProviderContainer> _pumpStart(
  WidgetTester tester, {
  RowerChoice? chosen,
  AppDatabase? db,
  FoundHeartRateMonitor? strap,
}) async {
  final container = _container(chosen: chosen, db: db, strap: strap);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const LocalizedApp(home: StartScreen())),
  );
  await _settle(tester);
  return container;
}

/// Lets drift deliver its stream queries.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pumpAndSettle();
  }
}

Future<ProviderContainer> _launch(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AergRowApp()));
  await tester.pump();
  return container;
}

void main() {
  group('start screen', () {
    testWidgets('shows the chosen rower, "Rudern", "Frei rudern" and the sessions', (tester) async {
      await _pumpStart(tester, chosen: const RowerChoice.simulator());

      expect(find.descendant(of: find.byKey(const Key('device-row')), matching: find.text('Simulator')),
          findsOneWidget);
      expect(find.text('Rudern'), findsOneWidget);
      expect(find.text('Frei rudern'), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('shows only the rower in the device row without a strap', (tester) async {
      await _pumpStart(tester, chosen: const RowerChoice.device(_pm5));

      final row = find.byKey(const Key('device-row'));
      expect(find.descendant(of: row, matching: find.text('PM5 430000001 Row')), findsOneWidget);
      expect(find.byKey(const Key('device-row-strap')), findsNothing);
      expect(find.descendant(of: row, matching: find.byIcon(Icons.favorite)), findsNothing);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('shows the paired strap next to the rower in the device row', (tester) async {
      await _pumpStart(tester, chosen: const RowerChoice.device(_pm5), strap: _h10);

      final row = find.byKey(const Key('device-row'));
      expect(find.descendant(of: row, matching: find.text('PM5 430000001 Row')), findsOneWidget);
      final strap = find.descendant(of: row, matching: find.byKey(const Key('device-row-strap')));
      expect(find.descendant(of: strap, matching: find.text('Polar H10 1A2B3C4D')), findsOneWidget);
      expect(find.descendant(of: strap, matching: find.byIcon(Icons.favorite)), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('leads to "Geräte wählen" from the device row with a strap', (tester) async {
      await _pumpStart(tester, chosen: const RowerChoice.simulator(), strap: _h10);

      await tester.tap(find.text('Polar H10 1A2B3C4D'));
      await tester.pumpAndSettle();

      expect(find.byType(ChooseDevicesScreen), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('leads back to "Geräte wählen" from the device row', (tester) async {
      final container = await _pumpStart(tester, chosen: const RowerChoice.simulator());

      await tester.tap(find.byKey(const Key('device-row')));
      await tester.pumpAndSettle();
      expect(find.byType(ChooseDevicesScreen), findsOneWidget);
      expect(find.text('Geräte wählen'), findsOneWidget);

      await tester.tap(find.text('Simulator (FTMS)'));
      await tester.pump();
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();

      expect(find.byType(ChooseDevicesScreen), findsNothing);
      expect(find.descendant(of: find.byKey(const Key('device-row')), matching: find.text('Simulator (FTMS)')),
          findsOneWidget);
      expect(container.read(chosenRowerProvider)?.isSimulator, isTrue);
      await disposeWidgetsWithDatabase(tester);
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('"Rudern" opens the templates', (tester) async {
      await _pumpStart(tester, chosen: const RowerChoice.simulator());

      await tester.tap(find.text('Rudern'));
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pumpAndSettle();
      }

      expect(find.byType(TemplatesScreen), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('"Frei rudern" starts the chosen simulator in the live display', (tester) async {
      final container = await _pumpStart(tester, chosen: const RowerChoice.simulator());

      await tester.tap(find.text('Frei rudern'));
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      expect(find.byType(LiveScreen), findsOneWidget);
      expect(container.read(activeErgSourceProvider)?.kind, ErgSourceKind.simulator);
      expect(find.text('SIMULATOR'), findsOneWidget);
      await container.read(activeErgSourceProvider.notifier).clear();
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('"Frei rudern" without a chosen rower opens "Geräte wählen"', (tester) async {
      await _pumpStart(tester);

      expect(find.text('Kein Rudergerät gewählt'), findsOneWidget);
      await tester.tap(find.text('Frei rudern'));
      await tester.pumpAndSettle();

      expect(find.byType(ChooseDevicesScreen), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
      await tester.pump(const Duration(seconds: 15));
    });

    for (final (name, size) in const [
      ('portrait', Size(390, 844)),
      ('landscape', Size(844, 390)),
      ('a small window', Size(320, 480)),
    ]) {
      testWidgets('shows "Sessions" as a button across the width, $name', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _pumpStart(tester, chosen: const RowerChoice.simulator());

        final button = find.byKey(const Key('start-sessions'));
        await tester.scrollUntilVisible(button, 100);
        expect(find.descendant(of: button, matching: find.text('Sessions')), findsOneWidget);
        expect(find.descendant(of: button, matching: find.byIcon(Icons.history)), findsOneWidget);
        expect(tester.widget(button), isA<OutlinedButton>());
        expect(tester.getSize(button).width, tester.getSize(find.widgetWithText(OutlinedButton, 'Frei rudern')).width);
        expect(tester.takeException(), isNull);
        await disposeWidgetsWithDatabase(tester);
      });
    }

    testWidgets('opens the sessions with the button', (tester) async {
      await _pumpStart(tester, chosen: const RowerChoice.simulator());

      await tester.tap(find.byKey(const Key('start-sessions')));
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pumpAndSettle();
      }

      expect(find.byType(SessionsScreen), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('switches the app to English at once and keeps it after a restart', (tester) async {
      final languages = MemoryLanguageStore();
      Future<void> start() async {
        await _launch(tester, _container(chosen: const RowerChoice.simulator(), languages: languages));
        await tester.pumpAndSettle();
      }

      await start();
      expect(find.text('Frei rudern'), findsOneWidget);

      await tester.tap(find.byTooltip('Sprache'));
      await tester.pumpAndSettle();
      expect(find.text('Deutsch'), findsOneWidget);
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text('Just row'), findsOneWidget);
      expect(find.text('Row'), findsOneWidget);
      expect(find.byTooltip('Language'), findsOneWidget);

      // A restart: a new app with the same store.
      await disposeWidgetsWithDatabase(tester);
      await start();
      expect(find.text('Just row'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });
  });

  group('with a connected rower', () {
    /// The start screen with the PM5 chosen and connected, as after rowing.
    Future<ProviderContainer> pumpConnected(WidgetTester tester, {AppDatabase? db}) async {
      final container = _container(
        chosen: const RowerChoice.device(_pm5),
        transport: FakeBleTransport(found: [_pm5]),
        db: db,
      );
      await container.read(activeErgSourceProvider.notifier).use(
            const RowerChoice.device(_pm5).createSource(container.read(bleTransportProvider)),
          );
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const LocalizedApp(home: StartScreen())),
      );
      await _settle(tester);
      return container;
    }

    Future<void> end(WidgetTester tester, ProviderContainer container) async {
      await container.read(activeErgSourceProvider.notifier).clear();
      await disposeWidgetsWithDatabase(tester);
      await tester.pump(const Duration(seconds: 10));
    }

    testWidgets('shows it as connected and offers to disconnect', (tester) async {
      final container = await pumpConnected(tester);

      final row = find.byKey(const Key('device-row'));
      expect(find.descendant(of: row, matching: find.text('PM5 430000001 Row')), findsOneWidget);
      expect(find.descendant(of: row, matching: find.text('Verbunden')), findsOneWidget);
      final disconnect = find.descendant(of: row, matching: find.byKey(const Key('device-row-disconnect')));
      expect(find.descendant(of: disconnect, matching: find.text('Trennen')), findsOneWidget);
      expect(find.descendant(of: disconnect, matching: find.byIcon(Icons.link_off)), findsOneWidget);
      expect(tester.getSize(disconnect).height, greaterThanOrEqualTo(48));
      await end(tester, container);
    });

    testWidgets('fits "Trennen" into the device row of a small window', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = await pumpConnected(tester);

      expect(tester.takeException(), isNull);
      final row = tester.getRect(find.byKey(const Key('device-row')));
      final disconnect = tester.getRect(find.byKey(const Key('device-row-disconnect')));
      expect(disconnect.right, lessThanOrEqualTo(row.right));
      await end(tester, container);
    });

    testWidgets('"Trennen" ends the connection and shows the rower as before', (tester) async {
      final container = await pumpConnected(tester);
      final source = container.read(activeErgSourceProvider)!;

      await tester.tap(find.text('Trennen'));
      await tester.pumpAndSettle();

      expect(container.read(activeErgSourceProvider), isNull);
      expect(source.connectionState, ErgConnectionState.disconnected);
      expect(find.text('Verbindet beim Start'), findsOneWidget);
      expect(find.text('Trennen'), findsNothing);
      expect(container.read(chosenRowerProvider)?.device, _pm5);
      await end(tester, container);
    });

    testWidgets('"Frei rudern" uses the connection without connecting again', (tester) async {
      final container = await pumpConnected(tester);
      final source = container.read(activeErgSourceProvider);

      await tester.tap(find.text('Frei rudern'));
      await tester.pumpAndSettle();

      expect(find.byType(LiveScreen), findsOneWidget);
      expect(container.read(activeErgSourceProvider), same(source));
      await end(tester, container);
    });

    testWidgets('"Rudern" starts a template with the connection without connecting again', (tester) async {
      final db = openTestDatabase();
      await tester.runAsync(() async {
        final course = await CourseRepository(db)
            .create('Seerunde', CourseDefinition.single(axis: CourseAxis.distance, length: 1000));
        await TemplateRepository(db).create('Seerunde x3', courseId: course, laps: 3);
      });
      final container = await pumpConnected(tester, db: db);
      final source = container.read(activeErgSourceProvider);

      await tester.tap(find.text('Rudern'));
      await _settle(tester);
      await tester.tap(find.text('Seerunde x3'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Starten'));
      await _settle(tester);

      expect(find.byType(LiveScreen), findsOneWidget);
      expect(container.read(activeErgSourceProvider), same(source));
      await tester.runAsync(() => container.read(sessionRecorderProvider.notifier).stop());
      await end(tester, container);
    });

    testWidgets('going back from the live display keeps it connected', (tester) async {
      final container = await pumpConnected(tester);
      final source = container.read(activeErgSourceProvider);
      await tester.tap(find.text('Frei rudern'));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(StartScreen), findsOneWidget);
      expect(container.read(activeErgSourceProvider), same(source));
      expect(find.text('Verbunden'), findsOneWidget);
      await end(tester, container);
    });

    testWidgets('a simulator chosen in "Geräte wählen" ends the connection to the rower', (tester) async {
      final container = await pumpConnected(tester);
      final source = container.read(activeErgSourceProvider)!;

      await tester.tap(find.text('PM5 430000001 Row'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simulator'));
      await tester.pump();
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();

      expect(source.connectionState, ErgConnectionState.disconnected);
      expect(container.read(activeErgSourceProvider), isNull);
      expect(find.text('Trennen'), findsNothing);
      await end(tester, container);
    });
  });

  group('"Nochmal"', () {
    /// Two templates and a session with each; the one with [newest] is rowed yesterday.
    Future<(AppDatabase, Map<String, int>)> rowed(WidgetTester tester, {String newest = 'Seerunde x3'}) async {
      final db = openTestDatabase();
      final ids = (await tester.runAsync(() async {
        final course = await CourseRepository(db).create(
          'Seerunde',
          CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
        );
        final templates = TemplateRepository(db);
        final ids = {
          'Seerunde x3': await templates.create('Seerunde x3', courseId: course, laps: 3),
          'Seerunde offen': await templates.create('Seerunde offen', courseId: course, laps: null),
        };
        final now = DateTime.now();
        for (final name in ids.keys) {
          await SessionRepository(db).create(
            startedAt: now.subtract(Duration(days: name == newest ? 1 : 3)),
            source: ErgSourceKind.simulator,
            template: await templates.get(ids[name]!),
          );
        }
        return ids;
      }))!;
      return (db, ids);
    }

    testWidgets('shows the template of the newest session and opens it chosen', (tester) async {
      final (db, ids) = await rowed(tester);
      await _pumpStart(tester, chosen: const RowerChoice.simulator(), db: db);

      final tile = find.byKey(const Key('row-again'));
      expect(find.text('NOCHMAL'), findsOneWidget);
      expect(find.descendant(of: tile, matching: find.text('Seerunde x3')), findsOneWidget);
      expect(find.descendant(of: tile, matching: find.text('gestern')), findsOneWidget);

      await tester.tap(tile);
      await _settle(tester);

      expect(find.byType(TemplatesScreen), findsOneWidget);
      Finder start(String name) =>
          find.descendant(of: find.byKey(Key('template-${ids[name]}')), matching: find.text('Starten'));
      expect(start('Seerunde x3'), findsOneWidget);
      expect(start('Seerunde offen'), findsNothing);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('says how many days ago the session was', (tester) async {
      final (db, _) = await rowed(tester, newest: 'none');
      await _pumpStart(tester, chosen: const RowerChoice.simulator(), db: db);

      expect(find.text('vor 3 Tagen'), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('is missing without a session', (tester) async {
      await _pumpStart(tester, chosen: const RowerChoice.simulator());

      expect(find.byKey(const Key('row-again')), findsNothing);
      expect(find.text('NOCHMAL'), findsNothing);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('is missing when the template of the only session is deleted', (tester) async {
      final db = openTestDatabase();
      await tester.runAsync(() async {
        final course = await CourseRepository(db).create(
          'Seerunde',
          CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
        );
        final templates = TemplateRepository(db);
        final id = await templates.create('Seerunde x3', courseId: course, laps: 3);
        await SessionRepository(db).create(
          startedAt: DateTime.now(),
          source: ErgSourceKind.simulator,
          template: await templates.get(id),
        );
        await templates.delete(id);
      });
      await _pumpStart(tester, chosen: const RowerChoice.simulator(), db: db);

      expect(find.byKey(const Key('row-again')), findsNothing);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('skips the newest session when its template is deleted', (tester) async {
      final (db, ids) = await rowed(tester);
      await tester.runAsync(() => TemplateRepository(db).delete(ids['Seerunde x3']!));
      await _pumpStart(tester, chosen: const RowerChoice.simulator(), db: db);

      final tile = find.byKey(const Key('row-again'));
      expect(find.descendant(of: tile, matching: find.text('Seerunde offen')), findsOneWidget);
      expect(find.descendant(of: tile, matching: find.text('vor 3 Tagen')), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });
  });

  group('at the start of the app', () {
    testWidgets('shows "Geräte wählen" before the first choice', (tester) async {
      await _launch(tester, _container());

      expect(find.byType(ChooseDevicesScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('offers the language choice on "Geräte wählen" at the first start', (tester) async {
      final languages = MemoryLanguageStore();
      await _launch(tester, _container(languages: languages));
      expect(find.text('Geräte wählen'), findsOneWidget);

      await tester.tap(find.byTooltip('Sprache'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.byType(ChooseDevicesScreen), findsOneWidget);
      expect(find.text('Choose devices'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byTooltip('Language'), findsOneWidget);
      expect(languages.read(), 'en');
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('goes straight to the start screen after a simulator', (tester) async {
      await _launch(tester, _container(chosen: const RowerChoice.simulator()));

      expect(find.byType(StartScreen), findsOneWidget);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('connects the rower chosen last and goes straight to the start screen', (tester) async {
      final container = _container(chosen: const RowerChoice.device(_pm5), transport: FakeBleTransport(found: [_pm5]));
      await _launch(tester, container);
      await tester.pump();

      expect(find.byType(StartScreen), findsOneWidget);
      expect(find.byType(ChooseDevicesScreen), findsNothing);
      expect(container.read(activeErgSourceProvider)?.kind, ErgSourceKind.pm5);
      expect(find.text('Verbunden'), findsOneWidget);
      await container.read(activeErgSourceProvider.notifier).clear();
      await disposeWidgetsWithDatabase(tester);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('shows "Geräte wählen" with the rower preselected when it is not found in 10 s', (tester) async {
      final container = _container(chosen: const RowerChoice.device(_pm5));
      await _launch(tester, container);

      await tester.pump(const Duration(seconds: 9));
      expect(find.text('Suche PM5 430000001 Row …'), findsOneWidget);
      expect(find.byType(ChooseDevicesScreen), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.byType(ChooseDevicesScreen), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(Key('rower-${_pm5.id}')), matching: find.byIcon(Icons.radio_button_checked)),
        findsOneWidget,
      );
      expect(container.read(activeErgSourceProvider), isNull);
      await tester.pump(const Duration(seconds: 15));
    });
  });
}
