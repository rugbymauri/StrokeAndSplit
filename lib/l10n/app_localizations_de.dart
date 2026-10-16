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

  @override
  String get connectFailedTitle => 'Verbindung fehlgeschlagen';

  @override
  String connectFailedBody(String app, String device) {
    return '$app konnte sich nicht mit $device verbinden.\n\nViele Rudergeräte erlauben nur eine Bluetooth-Verbindung gleichzeitig. Trenne andere Apps wie ErgData und versuche es erneut.';
  }

  @override
  String get connectNotARowerTitle => 'Kein Rudergerät';

  @override
  String connectNotARowerHint(String app) {
    return '$app unterstützt den PM5 am RowErg und Rudergeräte mit FTMS.';
  }

  @override
  String get connectErrorSkiErg =>
      'Nur Rudergeräte werden unterstützt. Dieser PM5 gehört zu einem SkiErg.';

  @override
  String get connectErrorBikeErg =>
      'Nur Rudergeräte werden unterstützt. Dieser PM5 gehört zu einem BikeErg.';

  @override
  String get connectErrorNoRowerData =>
      'Nur Rudergeräte werden unterstützt. Das Gerät liefert keine Rudern-Daten.';

  @override
  String get stateConnected => 'Verbunden';

  @override
  String get stateConnecting => 'Verbinde …';

  @override
  String get stateScanning => 'Suche …';

  @override
  String get stateReconnecting => 'Verbindung unterbrochen, verbinde neu …';

  @override
  String get stateDisconnected => 'Getrennt';

  @override
  String get sourceSimulator => 'SIMULATOR';

  @override
  String get sourceSimulatorFtms => 'SIMULATOR (FTMS)';

  @override
  String get sourceReplay => 'REPLAY';

  @override
  String get deviceListTitle => 'Rudergerät suchen';

  @override
  String deviceListScanFailed(String detail) {
    return 'Die Suche nach Rudergeräten ist fehlgeschlagen.\n\n$detail';
  }

  @override
  String get deviceListRetry => 'Erneut suchen';

  @override
  String get deviceListNothingFound =>
      'Kein Rudergerät gefunden.\n\n• Wecke das Rudergerät auf, am PM5 mit einer Taste, bis das Hauptmenü erscheint.\n• Trenne andere Apps wie ErgData, viele Rudergeräte erlauben nur eine Verbindung.\n• Geh näher an das Rudergerät.';

  @override
  String get bluetoothOff =>
      'Bluetooth ist ausgeschaltet. Schalte Bluetooth ein, um nach deinem Rudergerät zu suchen.';

  @override
  String bluetoothUnauthorized(String app) {
    return '$app darf Bluetooth nicht verwenden. Die Berechtigung ist nötig, um sich mit deinem Rudergerät zu verbinden. Erteile sie in den Systemeinstellungen unter Apps → $app → Berechtigungen.';
  }

  @override
  String get bluetoothUnsupported =>
      'Dieses Gerät unterstützt kein Bluetooth LE.';

  @override
  String get liveDisconnect => 'Trennen';

  @override
  String get liveStale =>
      'Keine Daten seit 3 Sekunden, die Werte sind veraltet.';

  @override
  String get liveStartSession => 'Session starten';

  @override
  String get liveStopSession => 'Session beenden';

  @override
  String get metricTime => 'Zeit';

  @override
  String get metricDistance => 'Meter';

  @override
  String get metricWatts => 'Watt';

  @override
  String get metricStrokeRate => 'Schläge/min';

  @override
  String get metricHeartRate => 'Puls';

  @override
  String get metricPace => 'Pace /500 m';

  @override
  String courseLap(int lap) {
    return 'Runde $lap';
  }

  @override
  String courseLapOf(int lap, int laps) {
    return 'Runde $lap von $laps';
  }

  @override
  String get segmentFree => 'frei';

  @override
  String get segmentZone => 'Zone';

  @override
  String courseRest(String rest) {
    return 'noch $rest';
  }

  @override
  String courseInZoneShare(int percent) {
    return 'Zone $percent %';
  }

  @override
  String get hintInZone => 'in der Zone';

  @override
  String get hintFaster => 'schneller';

  @override
  String get hintSlower => 'langsamer';

  @override
  String get hintNoPace => 'keine Pace';

  @override
  String get hintMoreStrokes => 'mehr Schläge';

  @override
  String get hintFewerStrokes => 'weniger Schläge';

  @override
  String get hintNoStrokes => 'keine Schläge';

  @override
  String get simTargetPace => 'Ziel-Pace';

  @override
  String get simTargetStrokeRate => 'Ziel-SPM';

  @override
  String get simFaster => 'Schneller';

  @override
  String get simSlower => 'Langsamer';

  @override
  String get simMoreStrokes => 'Mehr Schläge';

  @override
  String get simFewerStrokes => 'Weniger Schläge';

  @override
  String get simPause => 'Pause';

  @override
  String get simResume => 'Weiterrudern';
}
