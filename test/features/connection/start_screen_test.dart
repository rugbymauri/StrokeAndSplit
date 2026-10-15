import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/features/connection/start_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_ble_transport.dart';

void main() {
  testWidgets('offers PM5, simulator and replay as data sources', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: StartScreen())));

    expect(find.text('PM5 suchen'), findsOneWidget);
    expect(find.text('Simulator'), findsOneWidget);
    expect(find.text('Session abspielen'), findsOneWidget);
  });

  testWidgets('starts the simulator and opens the live display', (tester) async {
    final container = ProviderContainer(overrides: [wakelockProvider.overrideWithValue(FakeWakelock())]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MaterialApp(home: StartScreen())));

    await tester.tap(find.text('Simulator'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(container.read(activeErgSourceProvider)?.kind, ErgSourceKind.simulator);
    expect(find.text('SIMULATOR'), findsOneWidget);

    await container.read(activeErgSourceProvider.notifier).clear();
  });
}
