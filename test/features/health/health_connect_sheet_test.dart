import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strokesplit/app/platform_providers.dart';
import 'package:strokesplit/data/health/health_export.dart';
import 'package:strokesplit/data/health/health_platform.dart';
import 'package:strokesplit/data/health/health_workout.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/features/health/health_privacy_screen.dart';
import 'package:strokesplit/features/sessions/sessions_screen.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/fake_health_platform.dart';
import '../../support/localized_app.dart';
import '../../support/test_database.dart';

class _Setup {
  _Setup({this.available = true, HealthStatus status = HealthStatus.available, Set<HealthKind>? grants})
      : health = FakeHealthPlatform(health: status, grants: grants);

  final bool available;
  final FakeHealthPlatform health;
  final store = MemoryHealthExportStore();
  final db = openTestDatabase();
  late final container = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db),
    wakelockProvider.overrideWithValue(FakeWakelock()),
    healthPlatformProvider.overrideWithValue(health),
    healthExportStoreProvider.overrideWithValue(store),
    healthExportAvailableProvider.overrideWithValue(available),
  ]);

  Future<void> pump(WidgetTester tester, {Widget home = const SessionsScreen(), Locale? locale}) async {
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: LocalizedApp(home: home, locale: locale ?? const Locale('de')),
    ));
    await tester.pump();
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('health-connect-button')));
    await tester.pumpAndSettle();
  }

  Future<void> toggle(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('health-connect-switch')));
    await tester.pumpAndSettle();
  }

  bool get switchedOn => container.read(healthExportEnabledProvider);
}

void main() {
  testWidgets('offers nothing without Health Connect on the platform, as on Linux', (tester) async {
    final setup = _Setup(available: false);
    await setup.pump(tester);

    expect(find.byKey(const Key('health-connect-button')), findsNothing);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('switches on once the permissions are granted', (tester) async {
    final setup = _Setup();
    await setup.pump(tester);
    await setup.openSheet(tester);

    expect(find.text('An Health Connect übertragen'), findsOneWidget);
    await setup.toggle(tester);

    expect(setup.switchedOn, isTrue);
    expect(setup.store.read(), isTrue);
    expect(setup.health.granted, HealthKind.values.toSet());
    expect(find.byKey(const Key('health-connect-active')), findsOneWidget);

    await setup.toggle(tester);
    expect(setup.switchedOn, isFalse);
    expect(setup.store.read(), isFalse);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('stays off when the permission for workouts is refused', (tester) async {
    final setup = _Setup(grants: {HealthKind.heartRate});
    await setup.pump(tester);
    await setup.openSheet(tester);

    await setup.toggle(tester);

    expect(setup.switchedOn, isFalse);
    expect(find.byKey(const Key('health-connect-permission')), findsOneWidget);
    expect(find.text('Berechtigung erteilen'), findsOneWidget);

    setup.health.grants = HealthKind.values.toSet();
    await tester.tap(find.text('Berechtigung erteilen'));
    await tester.pumpAndSettle();
    expect(setup.switchedOn, isTrue);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('says that Health Connect is missing and offers to install it', (tester) async {
    final setup = _Setup(status: HealthStatus.unavailable);
    await setup.pump(tester);
    await setup.openSheet(tester);

    expect(find.byKey(const Key('health-connect-missing')), findsOneWidget);
    expect(find.text('Health Connect öffnen'), findsNothing);
    await setup.toggle(tester);
    expect(setup.switchedOn, isFalse);

    await tester.tap(find.text('Installieren'));
    expect(setup.health.installs, 1);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('offers an update of an old Health Connect', (tester) async {
    final setup = _Setup(status: HealthStatus.updateRequired);
    await setup.pump(tester);
    await setup.openSheet(tester);

    expect(find.byKey(const Key('health-connect-outdated')), findsOneWidget);
    await tester.tap(find.text('Aktualisieren'));
    expect(setup.health.installs, 1);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('says when a granted permission was withdrawn', (tester) async {
    final setup = _Setup();
    await setup.store.write(true);
    await setup.pump(tester);
    await setup.openSheet(tester);

    expect(setup.switchedOn, isTrue);
    expect(find.byKey(const Key('health-connect-permission')), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('opens Health Connect and the privacy notice', (tester) async {
    final setup = _Setup();
    await setup.pump(tester);
    await setup.openSheet(tester);

    await tester.tap(find.text('Health Connect öffnen'));
    expect(setup.health.settings, 1);

    await tester.tap(find.text('Datenschutz-Hinweis'));
    await tester.pumpAndSettle();
    expect(find.byType(HealthPrivacyScreen), findsOneWidget);
    expect(find.text('Stroke & Split liest keine Daten aus Health Connect.'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });

  testWidgets('the privacy notice reads in English', (tester) async {
    final setup = _Setup();
    await setup.pump(tester, home: const HealthPrivacyScreen(), locale: const Locale('en'));

    expect(find.text('Privacy notice'), findsOneWidget);
    expect(find.text('Stroke & Split reads no data from Health Connect.'), findsOneWidget);
    await disposeWidgetsWithDatabase(tester);
  });
}
