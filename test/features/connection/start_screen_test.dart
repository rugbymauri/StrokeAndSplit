import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/features/connection/start_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/localized_app.dart';

void main() {
  testWidgets('offers PM5, simulator, templates and the recorded sessions', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LocalizedApp(home: StartScreen())));

    expect(find.text('Rudergerät suchen'), findsOneWidget);
    expect(find.text('Simulator'), findsOneWidget);
    expect(find.text('Vorlage rudern'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
  });

  testWidgets('starts the simulator and opens the live display', (tester) async {
    final container = ProviderContainer(overrides: [wakelockProvider.overrideWithValue(FakeWakelock())]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const LocalizedApp(home: StartScreen())));

    await tester.tap(find.text('Simulator'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(container.read(activeErgSourceProvider)?.kind, ErgSourceKind.simulator);
    expect(find.text('SIMULATOR'), findsOneWidget);

    await container.read(activeErgSourceProvider.notifier).clear();
  });
}
