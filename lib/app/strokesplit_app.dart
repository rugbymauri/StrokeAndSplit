import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/health/health_export.dart';
import '../data/sources/heart_rate_monitor.dart';
import '../features/connection/launch_screen.dart';
import '../features/health/health_privacy_screen.dart';
import '../features/sessions/session_actions.dart';
import '../l10n/l10n.dart';
import 'app_language.dart';
import 'app_theme.dart';

class StrokeSplitApp extends ConsumerStatefulWidget {
  const StrokeSplitApp({super.key});

  @override
  ConsumerState<StrokeSplitApp> createState() => _StrokeSplitAppState();
}

class _StrokeSplitAppState extends ConsumerState<StrokeSplitApp> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  final _navigator = GlobalKey<NavigatorState>();
  StreamSubscription<void>? _privacyRequests;

  @override
  void initState() {
    super.initState();
    // Health Connect opens the app for its privacy notice, at the start or while it runs (health-connect, D7).
    if (!ref.read(healthExportAvailableProvider)) return;
    final health = ref.read(healthPlatformProvider);
    _privacyRequests = health.privacyRequests.listen((_) => _showPrivacy());
    health.openedForPrivacy().then((opened) {
      if (opened) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showPrivacy());
      }
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    _privacyRequests?.cancel();
    super.dispose();
  }

  void _showPrivacy() => _navigator.currentState?.push(
    MaterialPageRoute<void>(builder: (_) => const HealthPrivacyScreen()),
  );

  @override
  Widget build(BuildContext context) {
    // The strap connects as soon as a rower over Bluetooth is connected, which
    // already happens in "Geräte wählen", not only in the live display (heart-rate, Design D7).
    ref.listen(heartRateMonitorProvider, (_, _) {});
    // A failed send after a session shows wherever the user is by then (health-connect, Design D4).
    ref.listen(healthExportFailureProvider, (_, failure) {
      final messenger = _messenger.currentState;
      if (failure == null || messenger == null) return;
      ref.read(healthExportFailureProvider.notifier).clear();
      final l10n = lookupAppLocalizations(ref.read(appLanguageProvider).locale);
      showHealthFailure(
        messenger,
        l10n,
        failure.reason,
        grant: ref.read(healthExportEnabledProvider.notifier).enable,
      );
    });
    return MaterialApp(
      scaffoldMessengerKey: _messenger,
      navigatorKey: _navigator,
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      // Only dark: easier to read at the erg and kinder to the battery (ui-design, design D1).
      theme: appTheme(),
      // Always set, so the system language plays no role (Design D2).
      locale: ref.watch(appLanguageProvider).locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // "Geräte wählen" first, skipped when the rower chosen last is found (ui-design, design D6).
      home: const LaunchScreen(),
    );
  }
}
