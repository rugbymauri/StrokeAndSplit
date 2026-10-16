import 'package:aergrow/app/aergrow_app.dart';
import 'package:aergrow/app/app_language.dart';
import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/sessions/session_repository.dart';
import 'package:aergrow/data/sources/ble/ble_transport.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
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

ProviderContainer _container({
  RowerChoice? chosen,
  FakeBleTransport? transport,
  LanguageStore? languages,
  AppDatabase? db,
}) {
  final container = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db ?? openTestDatabase()),
    wakelockProvider.overrideWithValue(FakeWakelock()),
    bleTransportProvider.overrideWithValue(transport ?? FakeBleTransport()),
    rowerChoiceStoreProvider.overrideWithValue(MemoryRowerChoiceStore(chosen)),
    languageStoreProvider.overrideWithValue(languages ?? MemoryLanguageStore()),
  ]);
  addTearDown(container.dispose);
  return container;
}

Future<ProviderContainer> _pumpStart(WidgetTester tester, {RowerChoice? chosen, AppDatabase? db}) async {
  final container = _container(chosen: chosen, db: db);
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
