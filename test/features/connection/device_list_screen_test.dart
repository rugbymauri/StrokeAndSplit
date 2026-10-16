import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/sources/ble/ble_transport.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/features/connection/device_list_screen.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/localized_app.dart';

const _pm5 = FoundRower(id: 'C0:00:00:00:00:01', name: 'PM5 430000001 Row');
const _ftms = FoundRower(id: 'AA:BB:CC:DD:EE:FF', name: 'AergRow FTMS Rower', protocol: ErgProtocol.ftms);

Future<ProviderContainer> _pump(WidgetTester tester, FakeBleTransport transport, {Locale? locale}) async {
  final container = ProviderContainer(overrides: [
    bleTransportProvider.overrideWithValue(transport),
    wakelockProvider.overrideWithValue(FakeWakelock()),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: LocalizedApp(
      locale: locale ?? const Locale('de'),
      home: const DeviceListScreen(scanTimeout: Duration(seconds: 15)),
    ),
  ));
  await tester.pump();
  return container;
}

void main() {
  testWidgets('lists a PM5 in range', (tester) async {
    await _pump(tester, FakeBleTransport(found: [_pm5]));

    expect(find.text('PM5 430000001 Row'), findsOneWidget);
    expect(find.text('Concept2 PM5 · C0:00:00:00:00:01'), findsOneWidget);
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('lists an FTMS rower with its kind', (tester) async {
    await _pump(tester, FakeBleTransport(found: [_pm5, _ftms]));

    expect(find.text('AergRow FTMS Rower'), findsOneWidget);
    expect(find.text('FTMS · AA:BB:CC:DD:EE:FF'), findsOneWidget);
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('shows tips when no rower was found within 15 seconds', (tester) async {
    await _pump(tester, FakeBleTransport());

    expect(find.textContaining('Kein Rudergerät gefunden'), findsNothing);
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();

    expect(find.textContaining('Kein Rudergerät gefunden'), findsOneWidget);
    expect(find.textContaining('ErgData'), findsOneWidget);
  });

  testWidgets('asks to switch Bluetooth on instead of showing an empty list', (tester) async {
    await _pump(tester, FakeBleTransport(readinessValue: BluetoothReadiness.off));

    expect(find.textContaining('Bluetooth ist ausgeschaltet'), findsOneWidget);
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
    final container = await _pump(tester, FakeBleTransport(found: [_pm5], connectError: error));

    await tester.tap(find.text('PM5 430000001 Row'));
    await tester.pumpAndSettle();

    expect(find.text('Verbindung fehlgeschlagen'), findsOneWidget);
    expect(find.textContaining('nur eine Bluetooth-Verbindung gleichzeitig'), findsOneWidget);
    expect(container.read(activeErgSourceProvider), isNull);
  });

  testWidgets('says that only rowers are supported when the device is no rower', (tester) async {
    const error = RowerConnectException(RowerConnectError.bikeErg);
    final container = await _pump(tester, FakeBleTransport(found: [_pm5], connectError: error));

    await tester.tap(find.text('PM5 430000001 Row'));
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    expect(find.text('Not a rower'), findsOneWidget);
    expect(find.textContaining('This PM5 belongs to a BikeErg.'), findsOneWidget);
    expect(find.textContaining('supports the PM5 on a RowErg'), findsOneWidget);
  });

  testWidgets('opens the live display after connecting', (tester) async {
    final container = await _pump(tester, FakeBleTransport(found: [_pm5]));

    await tester.tap(find.text('PM5 430000001 Row'));
    await tester.pumpAndSettle();

    expect(container.read(activeErgSourceProvider)?.kind, ErgSourceKind.pm5);
    expect(find.text('Verbunden'), findsOneWidget);
    await container.read(activeErgSourceProvider.notifier).clear();
  });

  testWidgets('connects to an FTMS rower as an FTMS source', (tester) async {
    final container = await _pump(tester, FakeBleTransport(found: [_ftms]));

    await tester.tap(find.text('AergRow FTMS Rower'));
    await tester.pumpAndSettle();

    final source = container.read(activeErgSourceProvider);
    expect((source?.kind, source?.protocol), (ErgSourceKind.ftms, ErgProtocol.ftms));
    expect(find.text('Verbunden'), findsOneWidget);
    await container.read(activeErgSourceProvider.notifier).clear();
  });
}
