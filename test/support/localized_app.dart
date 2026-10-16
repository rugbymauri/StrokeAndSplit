import 'package:aergrow/app/app_theme.dart';
import 'package:aergrow/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// A [MaterialApp] with the app's theme and translations, in German unless
/// [locale] says otherwise.
class LocalizedApp extends StatelessWidget {
  const LocalizedApp({super.key, required this.home, this.locale = const Locale('de')});

  final Widget home;
  final Locale locale;

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: appTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      );
}
