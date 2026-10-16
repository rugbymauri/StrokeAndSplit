import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/sources/ble/ble_transport.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/data/sources/rower_choice.dart';
import 'package:aergrow/features/connection/choose_devices_screen.dart';
import 'package:aergrow/features/connection/start_screen.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/localized_app.dart';
import '../../support/test_database.dart';

const _pm5 = FoundRower(id: 'C0:00:00:00:00:01', name: 'PM5 430000001 Row');
const _ftms = FoundRower(id: 'AA:BB:CC:DD:EE:FF', name: 'AergRow FTMS Rower', protocol: ErgProtocol.ftms);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeBleTransport transport, {
  Locale? locale,
  RowerChoiceStore? store,
}) async {
  final container = ProviderContainer(overrides: [
    bleTransportProvider.overrideWithValue(transport),
    wakelockProvider.overrideWithValue(FakeWakelock()),
    databaseProvider.overrideWithValue(openTestDatabase()),
    rowerChoiceStoreProvider.overrideWithValue(store ?? MemoryRowerChoiceStore()),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: LocalizedApp(
      locale: locale ?? const Locale('de'),
      home: const ChooseDevicesScreen(scanTimeout: Duration(seconds: 15)),
    ),
  ));
  await tester.pump();
  return container;
}

/// Whether the option with [key] is marked as chosen.
bool _isSelected(WidgetTester tester, String key) => tester.any(
      find.descendant(of: find.byKey(Key(key)), matching: find.byIcon(Icons.radio_button_checked)),
    );

FilledButton _next(WidgetTester tester) => tester.widget(find.widgetWithText(FilledButton, 'Weiter'));

Future<void> _continue(WidgetTester tester, {String label = 'Weiter'}) async {
  await tester.pump();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists a PM5 in range besides the two simulators', (tester) async {
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

    expect(find.text('AergRow FTMS Rower'), findsOneWidget);
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

  testWidgets('chooses the simulator, remembers it and opens the start screen', (tester) async {
    final store = MemoryRowerChoiceStore();
    final container = await _pump(tester, FakeBleTransport(), store: store);

    await tester.tap(find.text('Simulator'));
    await tester.pump();
    expect(_isSelected(tester, 'rower-simulator'), isTrue);
    await _continue(tester);

    expect(find.byType(StartScreen), findsOneWidget);
    expect(container.read(chosenRowerProvider), const RowerChoice.simulator());
    expect(RowerChoice.decode(store.read()), const RowerChoice.simulator());
    // The simulator only starts with rowing.
    expect(container.read(activeErgSourceProvider), isNull);
    await disposeWidgetsWithDatabase(tester);
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('chooses the FTMS simulator', (tester) async {
    final container = await _pump(tester, FakeBleTransport());

    await tester.tap(find.text('Simulator (FTMS)'));
    await _continue(tester);

    expect(container.read(chosenRowerProvider), const RowerChoice.simulator(ErgProtocol.ftms));
    expect(find.text('Simulator (FTMS)'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('connects a rower from the list, remembers it and opens the start screen', (tester) async {
    final store = MemoryRowerChoiceStore();
    final container = await _pump(tester, FakeBleTransport(found: [_pm5]), store: store);

    await tester.tap(find.text('PM5 430000001 Row'));
    await _continue(tester);

    expect(find.byType(StartScreen), findsOneWidget);
    expect(container.read(activeErgSourceProvider)?.kind, ErgSourceKind.pm5);
    expect(RowerChoice.decode(store.read())?.device, _pm5);
    expect(find.text('Verbunden'), findsOneWidget);
    await container.read(activeErgSourceProvider.notifier).clear();
    await disposeWidgetsWithDatabase(tester);
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('connects to an FTMS rower as an FTMS source', (tester) async {
    final container = await _pump(tester, FakeBleTransport(found: [_ftms]));

    await tester.tap(find.text('AergRow FTMS Rower'));
    await _continue(tester);

    final source = container.read(activeErgSourceProvider);
    expect((source?.kind, source?.protocol), (ErgSourceKind.ftms, ErgProtocol.ftms));
    await container.read(activeErgSourceProvider.notifier).clear();
    await disposeWidgetsWithDatabase(tester);
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('preselects the rower chosen last even when it is not in range', (tester) async {
    await _pump(tester, FakeBleTransport(), store: MemoryRowerChoiceStore(const RowerChoice.device(_pm5)));
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();

    expect(find.text('PM5 430000001 Row'), findsOneWidget);
    expect(find.text('Concept2 PM5 · nicht gefunden'), findsOneWidget);
    expect(_isSelected(tester, 'rower-${_pm5.id}'), isTrue);
    expect(_next(tester).onPressed, isNotNull);
  });

  testWidgets('shows tips when no rower was found within 15 seconds', (tester) async {
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

  testWidgets('asks to switch Bluetooth on and still offers the simulators', (tester) async {
    await _pump(tester, FakeBleTransport(readinessValue: BluetoothReadiness.off));

    expect(find.textContaining('Bluetooth ist ausgeschaltet'), findsOneWidget);
    expect(find.text('Simulator'), findsOneWidget);
  });

  testWidgets('explains a denied Bluetooth permission', (tester) async {
    await _pump(tester, FakeBleTransport(readinessValue: BluetoothReadiness.unauthorized));

    expect(find.textContaining('Berechtigung ist nötig'), findsOneWidget);
    expect(find.textContaining('Systemeinstellungen'), findsOneWidget);
  });

  testWidgets('explains a permission denied only when the scan starts', (tester) async {
    await _pump(
      tester,
      FakeBleTransport(scanError: const BluetoothNotReadyException(BluetoothReadiness.unauthorized)),
    );
    await tester.pump();

    expect(find.textContaining('Berechtigung ist nötig'), findsOneWidget);
    expect(find.textContaining('kein Bluetooth LE'), findsNothing);
  });

  testWidgets('shows other scan errors as they are', (tester) async {
    await _pump(tester, FakeBleTransport(scanError: StateError('adapter busy')));
    await tester.pump();

    expect(find.textContaining('Suche nach Rudergeräten ist fehlgeschlagen'), findsOneWidget);
    expect(find.textContaining('adapter busy'), findsOneWidget);
    expect(find.textContaining('kein Bluetooth LE'), findsNothing);
  });

  testWidgets('explains a failed connection with the one-connection limit', (tester) async {
    const error = RowerConnectException(RowerConnectError.failed, message: 'busy');
    final store = MemoryRowerChoiceStore();
    final container = await _pump(tester, FakeBleTransport(found: [_pm5], connectError: error), store: store);

    await tester.tap(find.text('PM5 430000001 Row'));
    await _continue(tester);

    expect(find.text('Verbindung fehlgeschlagen'), findsOneWidget);
    expect(find.textContaining('nur eine Bluetooth-Verbindung gleichzeitig'), findsOneWidget);
    expect(container.read(activeErgSourceProvider), isNull);
    expect(store.read(), isNull);
  });

  testWidgets('says that only rowers are supported when the device is no rower', (tester) async {
    const error = RowerConnectException(RowerConnectError.bikeErg);
    final container = await _pump(tester, FakeBleTransport(found: [_pm5], connectError: error));

    await tester.tap(find.text('PM5 430000001 Row'));
    await _continue(tester);

    expect(find.text('Kein Rudergerät'), findsOneWidget);
    expect(find.textContaining('Nur Rudergeräte werden unterstützt'), findsOneWidget);
    expect(find.textContaining('BikeErg'), findsOneWidget);
    expect(find.textContaining('nur eine Bluetooth-Verbindung'), findsNothing);
    expect(container.read(activeErgSourceProvider), isNull);
  });

  testWidgets('says in English that a PM5 on a BikeErg is no rower', (tester) async {
    const error = RowerConnectException(RowerConnectError.bikeErg);
    await _pump(tester, FakeBleTransport(found: [_pm5], connectError: error), locale: const Locale('en'));

    await tester.tap(find.text('PM5 430000001 Row'));
    await _continue(tester, label: 'Continue');

    expect(find.text('Not a rower'), findsOneWidget);
    expect(find.textContaining('This PM5 belongs to a BikeErg.'), findsOneWidget);
    expect(find.textContaining('supports the PM5 on a RowErg'), findsOneWidget);
  });
}
