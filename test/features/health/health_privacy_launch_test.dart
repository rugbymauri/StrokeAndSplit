import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strokesplit/app/platform_providers.dart';
import 'package:strokesplit/app/strokesplit_app.dart';
import 'package:strokesplit/data/health/health_export.dart';
import 'package:strokesplit/data/health/health_platform.dart';
import 'package:strokesplit/features/health/health_privacy_screen.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/fake_health_platform.dart';

Future<ProviderContainer> _pump(WidgetTester tester, HealthPlatform health, {bool available = true}) async {
  final container = ProviderContainer(overrides: [
    bleTransportProvider.overrideWithValue(FakeBleTransport()),
    healthPlatformProvider.overrideWithValue(health),
    healthExportAvailableProvider.overrideWithValue(available),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const StrokeSplitApp()));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('opens the privacy notice when Health Connect started the app for it', (tester) async {
    await _pump(tester, FakeHealthPlatform()..privacy = true);

    expect(find.byType(HealthPrivacyScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('starts on "Geräte wählen" otherwise and opens the notice when asked later', (tester) async {
    final health = FakeHealthPlatform();
    await _pump(tester, health);
    expect(find.byType(HealthPrivacyScreen), findsNothing);
    expect(find.text('Geräte wählen'), findsOneWidget);

    health.requestPrivacy();
    await tester.pumpAndSettle();

    expect(find.byType(HealthPrivacyScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('asks the Android app at the start through the channel', (tester) async {
    final channel = const MethodChannel(ChannelHealthPlatform.name);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'launchAction' ? 'privacy' : null,
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

    await _pump(tester, ChannelHealthPlatform());

    expect(find.byType(HealthPrivacyScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('asks nothing where there is no Health Connect', (tester) async {
    await _pump(tester, FakeHealthPlatform()..privacy = true, available: false);

    expect(find.byType(HealthPrivacyScreen), findsNothing);
    await tester.pump(const Duration(seconds: 15));
  });
}
