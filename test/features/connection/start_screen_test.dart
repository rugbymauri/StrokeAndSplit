import 'package:aergrow/app/aergrow_app.dart';
import 'package:aergrow/app/app_language.dart';
import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/sources/ble/ble_transport.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/data/sources/rower_choice.dart';
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

ProviderContainer _container({RowerChoice? chosen, FakeBleTransport? transport, LanguageStore? languages}) {
  final container = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(openTestDatabase()),
    wakelockProvider.overrideWithValue(FakeWakelock()),
    bleTransportProvider.overrideWithValue(transport ?? FakeBleTransport()),
    rowerChoiceStoreProvider.overrideWithValue(MemoryRowerChoiceStore(chosen)),
    languageStoreProvider.overrideWithValue(languages ?? MemoryLanguageStore()),
  ]);
  addTearDown(container.dispose);
  return container;
}

Future<ProviderContainer> _pumpStart(WidgetTester tester, {RowerChoice? chosen}) async {
  final container = _container(chosen: chosen);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const LocalizedApp(home: StartScreen())),
  );
  await tester.pumpAndSettle();
  return container;
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

    testWidgets('opens the sessions', (tester) async {
      await _pumpStart(tester, chosen: const RowerChoice.simulator());

      await tester.tap(find.text('Sessions'));
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

  group('at the start of the app', () {
    testWidgets('shows "Geräte wählen" before the first choice', (tester) async {
      await _launch(tester, _container());

      expect(find.byType(ChooseDevicesScreen), findsOneWidget);
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
