import 'package:aergrow/app/aergrow_app.dart';
import 'package:aergrow/app/platform_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_ble_transport.dart';

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
}
