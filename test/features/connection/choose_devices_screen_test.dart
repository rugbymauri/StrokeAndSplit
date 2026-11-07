import 'package:strokesplit/app/platform_providers.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sources/ble/ble_transport.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/sources/ble/heart_rate_transport.dart';
import 'package:strokesplit/data/sources/erg_source_providers.dart';
import 'package:strokesplit/data/sources/heart_rate_choice.dart';
import 'package:strokesplit/data/sources/rower_choice.dart';
import 'package:strokesplit/features/connection/choose_devices_screen.dart';
import 'package:strokesplit/features/connection/heart_rate_search_screen.dart';
import 'package:strokesplit/features/connection/start_screen.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/fake_heart_rate_transport.dart';
import '../../support/localized_app.dart';
import '../../support/test_database.dart';

const _pm5 = FoundRower(id: 'c0:00:00:00:00:01', name: 'PM5 430000001 Row');
const _ftms = FoundRower(
  id: 'aa:bb:cc:dd:ee:ff',
  name: 'Stroke & Split FTMS',
  protocol: ErgProtocol.ftms,
);
const _h10 = FoundHeartRateMonitor(
  id: 'a0:9e:1a:00:00:01',
  name: 'Polar H10 1A2B3C4D',
);
const _tickr = FoundHeartRateMonitor(
  id: 'd4:22:cd:00:00:02',
  name: 'TICKR 1234',
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeBleTransport transport, {
  Locale? locale,
  RowerChoiceStore? store,
  FakeHeartRateTransport? strapTransport,
  HeartRateMonitorStore? strapStore,
}) async {
  final container = ProviderContainer(
    overrides: [
      bleTransportProvider.overrideWithValue(transport),
      wakelockProvider.overrideWithValue(FakeWakelock()),
      databaseProvider.overrideWithValue(openTestDatabase()),
      rowerChoiceStoreProvider.overrideWithValue(
        store ?? MemoryRowerChoiceStore(),
      ),
      heartRateTransportProvider.overrideWithValue(
        strapTransport ?? FakeHeartRateTransport(),
      ),
      heartRateMonitorStoreProvider.overrideWithValue(
        strapStore ?? MemoryHeartRateMonitorStore(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: LocalizedApp(
        locale: locale ?? const Locale('de'),
        home: const ChooseDevicesScreen(scanTimeout: Duration(seconds: 15)),
      ),
    ),
  );
  await tester.pump();
  return container;
}

/// Whether the option with [key] is marked as chosen.
bool _isSelected(WidgetTester tester, String key) => tester.any(
  find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byIcon(Icons.radio_button_checked),
  ),
);

FilledButton _next(WidgetTester tester) =>
    tester.widget(find.widgetWithText(FilledButton, 'Weiter'));

/// A screen tall enough to show the strap section below the rowers.
void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Lets the rower scan run out, so that later transitions can settle.
Future<void> _finishRowerScan(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 15));
  await tester.pump();
}

/// Opens the strap search and waits for the straps found at once.
Future<void> _openStrapSearch(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('strap-search')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// The texts in the card of the strap section.
Finder _inStrapCard(String text) => find.descendant(
  of: find.byKey(const Key('strap')),
  matching: find.text(text),
);

Future<void> _continue(WidgetTester tester, {String label = 'Weiter'}) async {
  await tester.pump();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists a PM5 in range besides the two simulators', (
    tester,
  ) async {
    await _pump(tester, FakeBleTransport(found: [_pm5]));

    expect(find.text('Geräte wählen'), findsOneWidget);
    expect(find.text('PM5 430000001 Row'), findsOneWidget);
    expect(find.text('Concept2 PM5 · C0:00:00:00:00:01'), findsOneWidget);
    expect(find.text('Simulator'), findsOneWidget);
    expect(find.text('Simulator (FTMS)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('lists an FTMS rower with its kind', (tester) async {
    await _pump(tester, FakeBleTransport(found: [_pm5, _ftms]));

    expect(find.text('Stroke & Split FTMS'), findsOneWidget);
    expect(find.text('FTMS · AA:BB:CC:DD:EE:FF'), findsOneWidget);
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('keeps "Weiter" locked until a rower is chosen', (tester) async {
    await _pump(tester, FakeBleTransport(found: [_pm5]));

    expect(_next(tester).onPressed, isNull);
    await tester.tap(find.text('PM5 430000001 Row'));
    await tester.pump();

    expect(_isSelected(tester, 'rower-${_pm5.id}'), isTrue);
    expect(_next(tester).onPressed, isNotNull);
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets(
    'chooses the simulator, remembers it and opens the start screen',
    (tester) async {
      final store = MemoryRowerChoiceStore();
      final container = await _pump(tester, FakeBleTransport(), store: store);

      await tester.tap(find.text('Simulator'));
      await tester.pump();
      expect(_isSelected(tester, 'rower-simulator'), isTrue);
      await _continue(tester);

      expect(find.byType(StartScreen), findsOneWidget);
      expect(
        container.read(chosenRowerProvider),
        const RowerChoice.simulator(),
      );
      expect(RowerChoice.decode(store.read()), const RowerChoice.simulator());
      // The simulator only starts with rowing.
      expect(container.read(activeErgSourceProvider), isNull);
      await disposeWidgetsWithDatabase(tester);
      await tester.pump(const Duration(seconds: 15));
    },
  );

  testWidgets('chooses the FTMS simulator', (tester) async {
    final container = await _pump(tester, FakeBleTransport());

    await tester.tap(find.text('Simulator (FTMS)'));
    await _continue(tester);

    expect(
      container.read(chosenRowerProvider),
      const RowerChoice.simulator(ErgProtocol.ftms),
    );
    expect(find.text('Simulator (FTMS)'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets(
    'connects a rower from the list, remembers it and opens the start screen',
    (tester) async {
      final store = MemoryRowerChoiceStore();
      final container = await _pump(
        tester,
        FakeBleTransport(found: [_pm5]),
        store: store,
      );

      await tester.tap(find.text('PM5 430000001 Row'));
      await _continue(tester);

      expect(find.byType(StartScreen), findsOneWidget);
      expect(container.read(activeErgSourceProvider)?.kind, ErgSourceKind.pm5);
      expect(RowerChoice.decode(store.read())?.device, _pm5);
      expect(find.text('Verbunden'), findsOneWidget);
      await container.read(activeErgSourceProvider.notifier).clear();
      await disposeWidgetsWithDatabase(tester);
      await tester.pump(const Duration(seconds: 15));
    },
  );

  testWidgets('connects to an FTMS rower as an FTMS source', (tester) async {
    final container = await _pump(tester, FakeBleTransport(found: [_ftms]));

    await tester.tap(find.text('Stroke & Split FTMS'));
    await _continue(tester);

    final source = container.read(activeErgSourceProvider);
    expect(
      (source?.kind, source?.protocol),
      (ErgSourceKind.ftms, ErgProtocol.ftms),
    );
    await container.read(activeErgSourceProvider.notifier).clear();
    await disposeWidgetsWithDatabase(tester);
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('preselects the rower chosen last even when it is not in range', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeBleTransport(),
      store: MemoryRowerChoiceStore(const RowerChoice.device(_pm5)),
    );
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();

    expect(find.text('PM5 430000001 Row'), findsOneWidget);
    expect(find.text('Concept2 PM5 · nicht gefunden'), findsOneWidget);
    expect(_isSelected(tester, 'rower-${_pm5.id}'), isTrue);
    expect(_next(tester).onPressed, isNotNull);
  });

  testWidgets('shows tips when no rower was found within 15 seconds', (
    tester,
  ) async {
    await _pump(tester, FakeBleTransport());

    expect(find.textContaining('Kein Rudergerät gefunden'), findsNothing);
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();

    expect(find.textContaining('Kein Rudergerät gefunden'), findsOneWidget);
    expect(find.textContaining('ErgData'), findsOneWidget);
    expect(find.text('Simulator'), findsOneWidget);
  });

  testWidgets('shows the tips in English', (tester) async {
    await _pump(tester, FakeBleTransport(), locale: const Locale('en'));
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();

    expect(find.text('Choose devices'), findsOneWidget);
    expect(find.textContaining('No rower found.'), findsOneWidget);
    expect(find.textContaining('Move closer to the rower.'), findsOneWidget);
    expect(find.text('Search again'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('asks to switch Bluetooth on and still offers the simulators', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeBleTransport(readinessValue: BluetoothReadiness.off),
    );

    expect(find.textContaining('Bluetooth ist ausgeschaltet'), findsOneWidget);
    expect(find.text('Simulator'), findsOneWidget);
  });

  testWidgets('explains a denied Bluetooth permission', (tester) async {
    await _pump(
      tester,
      FakeBleTransport(readinessValue: BluetoothReadiness.unauthorized),
    );

    expect(find.textContaining('Berechtigung ist nötig'), findsOneWidget);
    expect(find.textContaining('Systemeinstellungen'), findsOneWidget);
  });

  testWidgets('explains a permission denied only when the scan starts', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeBleTransport(
        scanError: const BluetoothNotReadyException(
          BluetoothReadiness.unauthorized,
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Berechtigung ist nötig'), findsOneWidget);
    expect(find.textContaining('kein Bluetooth LE'), findsNothing);
  });

  testWidgets('shows other scan errors as they are', (tester) async {
    await _pump(
      tester,
      FakeBleTransport(scanError: StateError('adapter busy')),
    );
    await tester.pump();

    expect(
      find.textContaining('Suche nach Rudergeräten ist fehlgeschlagen'),
      findsOneWidget,
    );
    expect(find.textContaining('adapter busy'), findsOneWidget);
    expect(find.textContaining('kein Bluetooth LE'), findsNothing);
  });

  testWidgets('explains a failed connection with the one-connection limit', (
    tester,
  ) async {
    const error = RowerConnectException(
      RowerConnectError.failed,
      message: 'busy',
    );
    final store = MemoryRowerChoiceStore();
    final container = await _pump(
      tester,
      FakeBleTransport(found: [_pm5], connectError: error),
      store: store,
    );

    await tester.tap(find.text('PM5 430000001 Row'));
    await _continue(tester);

    expect(find.text('Verbindung fehlgeschlagen'), findsOneWidget);
    expect(
      find.textContaining('nur eine Bluetooth-Verbindung gleichzeitig'),
      findsOneWidget,
    );
    expect(container.read(activeErgSourceProvider), isNull);
    expect(store.read(), isNull);
  });

  testWidgets(
    'says that only rowers are supported when the device is no rower',
    (tester) async {
      const error = RowerConnectException(RowerConnectError.bikeErg);
      final container = await _pump(
        tester,
        FakeBleTransport(found: [_pm5], connectError: error),
      );

      await tester.tap(find.text('PM5 430000001 Row'));
      await _continue(tester);

      expect(find.text('Kein Rudergerät'), findsOneWidget);
      expect(
        find.textContaining('Nur Rudergeräte werden unterstützt'),
        findsOneWidget,
      );
      expect(find.textContaining('BikeErg'), findsOneWidget);
      expect(
        find.textContaining('nur eine Bluetooth-Verbindung'),
        findsNothing,
      );
      expect(container.read(activeErgSourceProvider), isNull);
    },
  );

  testWidgets('says in English that a PM5 on a BikeErg is no rower', (
    tester,
  ) async {
    const error = RowerConnectException(RowerConnectError.bikeErg);
    await _pump(
      tester,
      FakeBleTransport(found: [_pm5], connectError: error),
      locale: const Locale('en'),
    );

    await tester.tap(find.text('PM5 430000001 Row'));
    await _continue(tester, label: 'Continue');

    expect(find.text('Not a rower'), findsOneWidget);
    expect(
      find.textContaining('This PM5 belongs to a BikeErg.'),
      findsOneWidget,
    );
    expect(find.textContaining('supports the PM5 on a RowErg'), findsOneWidget);
  });

  group('heart rate strap', () {
    testWidgets('shows "Kein Gurt" and offers to pair one', (tester) async {
      _tallScreen(tester);
      await _pump(tester, FakeBleTransport());

      expect(find.text('PULSGURT'), findsOneWidget);
      expect(_inStrapCard('Kein Gurt'), findsOneWidget);
      expect(find.text('Gurt koppeln'), findsOneWidget);
      expect(find.text('Vergessen'), findsNothing);
      await _finishRowerScan(tester);
    });

    testWidgets('pairs a strap from the strap search and remembers it', (
      tester,
    ) async {
      _tallScreen(tester);
      final strapStore = MemoryHeartRateMonitorStore();
      final strapTransport = FakeHeartRateTransport(found: [_h10]);
      final container = await _pump(
        tester,
        FakeBleTransport(found: [_pm5]),
        strapTransport: strapTransport,
        strapStore: strapStore,
      );
      await _finishRowerScan(tester);

      await _openStrapSearch(tester);
      expect(find.byType(HeartRateSearchScreen), findsOneWidget);
      expect(find.text('Pulsgurt suchen'), findsOneWidget);
      // The strap search lists straps only, apart from the rowers.
      expect(find.text('PM5 430000001 Row'), findsNothing);
      await tester.tap(find.text('Polar H10 1A2B3C4D'));
      await tester.pumpAndSettle();

      expect(find.byType(HeartRateSearchScreen), findsNothing);
      expect(_inStrapCard('Polar H10 1A2B3C4D'), findsOneWidget);
      expect(_inStrapCard('Gekoppelt · A0:9E:1A:00:00:01'), findsOneWidget);
      expect(find.text('Gurt wechseln'), findsOneWidget);
      expect(container.read(chosenHeartRateMonitorProvider), _h10);
      expect(decodeHeartRateMonitor(strapStore.read()), _h10);
      // Pairing connects nothing yet, that happens with the rower.
      expect(strapTransport.attempts, isEmpty);
    });

    testWidgets('changes the paired strap', (tester) async {
      _tallScreen(tester);
      final strapStore = MemoryHeartRateMonitorStore(_h10);
      final container = await _pump(
        tester,
        FakeBleTransport(),
        strapTransport: FakeHeartRateTransport(found: [_h10, _tickr]),
        strapStore: strapStore,
      );
      await _finishRowerScan(tester);
      expect(_inStrapCard('Polar H10 1A2B3C4D'), findsOneWidget);

      await _openStrapSearch(tester);
      expect(
        find.descendant(
          of: find.byKey(Key('strap-${_h10.id}')),
          matching: find.byIcon(Icons.radio_button_checked),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('TICKR 1234'));
      await tester.pumpAndSettle();

      expect(_inStrapCard('TICKR 1234'), findsOneWidget);
      expect(_inStrapCard('Polar H10 1A2B3C4D'), findsNothing);
      expect(container.read(chosenHeartRateMonitorProvider), _tickr);
      expect(decodeHeartRateMonitor(strapStore.read()), _tickr);
    });

    testWidgets('forgets the paired strap', (tester) async {
      _tallScreen(tester);
      final strapStore = MemoryHeartRateMonitorStore(_h10);
      final container = await _pump(
        tester,
        FakeBleTransport(),
        strapStore: strapStore,
      );

      await tester.tap(find.text('Vergessen'));
      await tester.pump();

      expect(_inStrapCard('Kein Gurt'), findsOneWidget);
      expect(find.text('Vergessen'), findsNothing);
      expect(container.read(chosenHeartRateMonitorProvider), isNull);
      expect(strapStore.read(), isNull);
      await _finishRowerScan(tester);
    });

    testWidgets('shows tips when no strap was found within 15 seconds', (
      tester,
    ) async {
      _tallScreen(tester);
      await _pump(tester, FakeBleTransport());
      await _finishRowerScan(tester);

      await _openStrapSearch(tester);
      expect(find.textContaining('Kein Gurt gefunden'), findsNothing);
      await tester.pump(const Duration(seconds: 15));
      await tester.pump();

      expect(find.textContaining('Kein Gurt gefunden'), findsOneWidget);
      expect(find.textContaining('Feuchte die Elektroden an'), findsOneWidget);
      expect(
        find.textContaining('von anderen Apps oder Uhren'),
        findsOneWidget,
      );
      expect(find.text('Erneut suchen'), findsOneWidget);
    });

    testWidgets('shows the strap tips in English', (tester) async {
      _tallScreen(tester);
      await _pump(tester, FakeBleTransport(), locale: const Locale('en'));
      await _finishRowerScan(tester);

      expect(find.text('HEART RATE STRAP'), findsOneWidget);
      expect(_inStrapCard('No strap'), findsOneWidget);
      await _openStrapSearch(tester);
      await tester.pump(const Duration(seconds: 15));
      await tester.pump();

      expect(find.text('Find heart rate strap'), findsOneWidget);
      expect(find.textContaining('No strap found.'), findsOneWidget);
    });

    testWidgets('asks to switch Bluetooth on for the strap search', (
      tester,
    ) async {
      _tallScreen(tester);
      await _pump(
        tester,
        FakeBleTransport(),
        strapTransport: FakeHeartRateTransport(
          readinessValue: BluetoothReadiness.off,
        ),
      );
      await _finishRowerScan(tester);

      await _openStrapSearch(tester);

      expect(
        find.textContaining('nach deinem Pulsgurt zu suchen'),
        findsOneWidget,
      );
    });

    testWidgets('continues without a strap once a rower is chosen', (
      tester,
    ) async {
      _tallScreen(tester);
      final container = await _pump(tester, FakeBleTransport());
      await _finishRowerScan(tester);

      expect(_inStrapCard('Kein Gurt'), findsOneWidget);
      await tester.tap(find.text('Simulator'));
      await tester.pump();
      expect(_next(tester).onPressed, isNotNull);
      await _continue(tester);

      expect(find.byType(StartScreen), findsOneWidget);
      expect(container.read(chosenHeartRateMonitorProvider), isNull);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('keeps "Weiter" locked with a paired strap but no rower', (
      tester,
    ) async {
      _tallScreen(tester);
      await _pump(
        tester,
        FakeBleTransport(),
        strapStore: MemoryHeartRateMonitorStore(_h10),
      );
      await _finishRowerScan(tester);

      expect(_inStrapCard('Polar H10 1A2B3C4D'), findsOneWidget);
      expect(_next(tester).onPressed, isNull);
    });
  });
}
