// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AergRow';

  @override
  String get startFindRower => 'Find rower';

  @override
  String get startFindRowerHint =>
      'Connect to your PM5 or FTMS rower over Bluetooth';

  @override
  String get startSimulator => 'Simulator';

  @override
  String get startSimulatorHint =>
      'Try it without an erg, with a simulated rower';

  @override
  String get startTemplate => 'Row a template';

  @override
  String get startTemplateHint =>
      'Row a course in laps, with zones for pace and stroke rate';

  @override
  String get startSessions => 'Sessions';

  @override
  String get startSessionsHint => 'View, replay and share recorded sessions';

  @override
  String get languageChoice => 'Language';
}
