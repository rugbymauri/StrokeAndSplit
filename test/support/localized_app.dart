import 'package:aergrow/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// A [MaterialApp] with the app's translations, in German unless [locale]
/// says otherwise.
class LocalizedApp extends StatelessWidget {
  const LocalizedApp({super.key, required this.home, this.locale = const Locale('de')});

  final Widget home;
  final Locale locale;

  @override
  Widget build(BuildContext context) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      );
}
