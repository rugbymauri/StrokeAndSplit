import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/connection/launch_screen.dart';
import '../l10n/l10n.dart';
import 'app_language.dart';
import 'app_theme.dart';

class AergRowApp extends ConsumerWidget {
  const AergRowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
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
