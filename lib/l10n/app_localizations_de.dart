// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'AergRow';

  @override
  String get startFindRower => 'Rudergerät suchen';

  @override
  String get startFindRowerHint =>
      'Mit deinem PM5 oder FTMS-Rudergerät über Bluetooth verbinden';

  @override
  String get startSimulator => 'Simulator';

  @override
  String get startSimulatorHint =>
      'Ohne Erg ausprobieren, mit simuliertem Ruderer';

  @override
  String get startTemplate => 'Vorlage rudern';

  @override
  String get startTemplateHint =>
      'Eine Strecke in Runden rudern, mit Zonen für Pace und Schlagzahl';

  @override
  String get startSessions => 'Sessions';

  @override
  String get startSessionsHint =>
      'Aufgezeichnete Sessions ansehen, abspielen und austauschen';

  @override
  String get languageChoice => 'Sprache';

  @override
  String get zoneErrorNameMissing => 'Der Name fehlt.';

  @override
  String get zoneErrorLengthMissing => 'Die Länge fehlt.';

  @override
  String get zoneErrorBandMissing =>
      'Es fehlt ein Band: Pace, Schlagzahl oder beides.';

  @override
  String get zoneErrorPaceBoundMissing =>
      'Für das Pace-Band fehlt eine Grenze.';

  @override
  String get zoneErrorPaceReversed =>
      'Die schnellste Pace ist langsamer als die langsamste.';

  @override
  String get zoneErrorSpmBoundMissing =>
      'Für das Schlagzahl-Band fehlt eine Grenze.';

  @override
  String get zoneErrorSpmReversed =>
      'Die niedrigste Schlagzahl liegt über der höchsten.';

  @override
  String quotedName(String name) {
    return '„$name“';
  }

  @override
  String get placementLengthMissing => 'Die Länge fehlt.';

  @override
  String get placementZoneMissing => 'Eine eingebaute Zone gibt es nicht mehr.';

  @override
  String placementAxisMismatch(
    String zone,
    String zoneAxis,
    String courseAxis,
  ) {
    String _temp0 = intl.Intl.selectLogic(zoneAxis, {
      'distance': 'Distanz',
      'other': 'Zeit',
    });
    String _temp1 = intl.Intl.selectLogic(courseAxis, {
      'distance': 'Distanz',
      'other': 'Zeit',
    });
    return '„$zone“ misst $_temp0, die Strecke $_temp1.';
  }

  @override
  String placementBeforeStart(String zone) {
    return '„$zone“ beginnt vor dem Start der Strecke.';
  }

  @override
  String placementBeyondEnd(String zone, String range, String length) {
    return '„$zone“ ($range) ragt über das Streckenende bei $length.';
  }

  @override
  String placementOverlap(
    String zone,
    String range,
    String other,
    String otherRange,
  ) {
    return '„$zone“ ($range) überschneidet „$other“ ($otherRange).';
  }

  @override
  String zoneConflict(String courses) {
    return 'Die Änderung passt nicht in $courses: Dort würde die Zone über das Streckenende ragen oder eine andere Zone überschneiden.';
  }
}
