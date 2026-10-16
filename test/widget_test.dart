import 'package:aergrow/app/aergrow_app.dart';
import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/sources/ble/ble_rower_source.dart';
import 'package:aergrow/data/sources/ble/ble_transport.dart';
import 'package:aergrow/data/sources/ble/heart_rate_transport.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/data/sources/heart_rate_choice.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_ble_transport.dart';
import 'support/fake_heart_rate_transport.dart';

void main() {
  testWidgets('the app starts on "Geräte wählen"', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [bleTransportProvider.overrideWithValue(FakeBleTransport())],
      child: const AergRowApp(),
    ));
    await tester.pump();

    expect(find.text('Geräte wählen'), findsOneWidget);
    expect(find.text('Weiter'), findsOneWidget);
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('connects the paired strap as soon as the rower is connected, before the live display', (tester) async {
    const h10 = FoundHeartRateMonitor(id: 'A0:9E:1A:12:34:56', name: 'Polar H10 1A2B3C4D');
    final rowers = FakeBleTransport();
    final straps = FakeHeartRateTransport();
    final container = ProviderContainer(overrides: [
      bleTransportProvider.overrideWithValue(rowers),
      heartRateTransportProvider.overrideWithValue(straps),
      heartRateMonitorStoreProvider.overrideWithValue(MemoryHeartRateMonitorStore(h10)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AergRowApp()));

    await container
        .read(activeErgSourceProvider.notifier)
        .use(BleRowerSource(transport: rowers, device: const FoundRower(id: 'CE:A5', name: 'PM5 430000001 Row')));
    await tester.pump();

    expect(straps.attempts, [h10]);
    await tester.pump(const Duration(seconds: 15));
  });
}
