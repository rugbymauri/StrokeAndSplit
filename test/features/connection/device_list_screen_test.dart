import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/sources/ble/ble_transport.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/features/connection/device_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_ble_transport.dart';

const _pm5 = FoundPm5(id: 'C0:00:00:00:00:01', name: 'PM5 430000001 Row');

Future<ProviderContainer> _pump(WidgetTester tester, FakeBleTransport transport) async {
  final container = ProviderContainer(overrides: [
    bleTransportProvider.overrideWithValue(transport),
    wakelockProvider.overrideWithValue(FakeWakelock()),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: DeviceListScreen(scanTimeout: Duration(seconds: 15))),
  ));
  await tester.pump();
  return container;
}

void main() {
  testWidgets('lists a PM5 in range', (tester) async {
    await _pump(tester, FakeBleTransport(found: [_pm5]));

    expect(find.text('PM5 430000001 Row'), findsOneWidget);
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('shows tips when no PM5 was found within 15 seconds', (tester) async {
    await _pump(tester, FakeBleTransport());

    expect(find.textContaining('Kein PM5 gefunden'), findsNothing);
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();

    expect(find.textContaining('Kein PM5 gefunden'), findsOneWidget);
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

    expect(find.textContaining('Suche nach dem PM5 ist fehlgeschlagen'), findsOneWidget);
    expect(find.textContaining('adapter busy'), findsOneWidget);
    expect(find.textContaining('kein Bluetooth LE'), findsNothing);
  });

  testWidgets('explains a failed connection with the one-connection limit', (tester) async {
    final container = await _pump(
        tester, FakeBleTransport(found: [_pm5], connectError: const Pm5ConnectException('busy')));

    await tester.tap(find.text('PM5 430000001 Row'));
    await tester.pumpAndSettle();

    expect(find.text('Verbindung fehlgeschlagen'), findsOneWidget);
    expect(find.textContaining('nur eine Bluetooth-Verbindung gleichzeitig'), findsOneWidget);
    expect(container.read(activeErgSourceProvider), isNull);
  });

  testWidgets('opens the live display after connecting', (tester) async {
    final container = await _pump(tester, FakeBleTransport(found: [_pm5]));

    await tester.tap(find.text('PM5 430000001 Row'));
    await tester.pumpAndSettle();

    expect(container.read(activeErgSourceProvider)?.kind, ErgSourceKind.pm5);
    expect(find.text('Verbunden'), findsOneWidget);
    await container.read(activeErgSourceProvider.notifier).clear();
  });
}
