import 'package:flutter/material.dart';

import '../features/connection/start_screen.dart';
import '../l10n/l10n.dart';

class AergRowApp extends StatelessWidget {
  const AergRowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF0B6E99), brightness: Brightness.light),
      // Dark by default: easier to read at the erg and kinder to the battery.
      darkTheme: ThemeData(colorSchemeSeed: const Color(0xFF0B6E99), brightness: Brightness.dark),
      themeMode: ThemeMode.dark,
      // Always set, so the system language plays no role (Design D2).
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const StartScreen(),
    );
  }
}
