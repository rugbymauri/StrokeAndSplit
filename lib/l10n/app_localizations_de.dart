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
  String get startSimulatorHint =>
      'Ohne Erg ausprobieren, mit simuliertem Ruderer';

  @override
  String get startSessions => 'Sessions';

  @override
  String get languageChoice => 'Sprache';

  @override
  String get startTagline => 'Gegen dich selbst rudern';

  @override
  String get startRow => 'Rudern';

  @override
  String get startRowFree => 'Frei rudern';

  @override
  String get startNoRower => 'Kein Rudergerät gewählt';

  @override
  String get startConnectsLater => 'Verbindet beim Start';

  @override
  String get startSimulatorFtmsHint =>
      'Wie ein FTMS-Rudergerät, ohne Schlagdetails';

  @override
  String get devicesTitle => 'Geräte wählen';

  @override
  String get devicesRower => 'Rudergerät';

  @override
  String get devicesNext => 'Weiter';

  @override
  String get devicesNotFound => 'nicht gefunden';

  @override
  String launchSearching(String device) {
    return 'Suche $device …';
  }

  @override
  String get startAgain => 'Nochmal';

  @override
  String startAgainDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'vor $days Tagen',
      one: 'gestern',
      zero: 'heute',
    );
    return '$_temp0';
  }

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
  String get metricDistance => 'Distanz';

  @override
  String get metricWatts => 'Watt';

  @override
  String get metricStrokeRate => 'Schlagzahl';

  @override
  String get metricHeartRate => 'Puls';

  @override
  String get metricPace => 'Pace /500 m';

  @override
  String get metricCalories => 'Kalorien';

  @override
  String get metricAveragePace => 'Ø Pace';

  @override
  String get metricLapTime => 'Runde';

  @override
  String get metricInZone => 'In Zone';

  @override
  String get liveStopShort => 'Beenden';

  @override
  String get liveForceCurve => 'Kraftkurve';

  @override
  String courseLap(int lap) {
    return 'Runde $lap';
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
  String get paceBoxTotal => 'Gesamt';

  @override
  String paceBoxLapOf(int lap, int laps) {
    return 'Runde $lap / $laps';
  }

  @override
  String get hintInZone => 'In der Zone';

  @override
  String get hintFaster => 'Schneller';

  @override
  String get hintSlower => 'Langsamer';

  @override
  String get hintNoPace => 'Keine Pace';

  @override
  String get hintMoreStrokes => 'Mehr Schläge';

  @override
  String get hintFewerStrokes => 'Weniger Schläge';

  @override
  String get hintNoStrokes => 'Keine Schläge';

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

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionReplay => 'Abspielen';

  @override
  String get actionExport => 'Exportieren';

  @override
  String get actionImport => 'Importieren';

  @override
  String get actionMore => 'Aktionen';

  @override
  String get sessionsTitle => 'Sessions';

  @override
  String get sessionsEmpty => 'Noch keine Sessions aufgezeichnet.';

  @override
  String sessionsLoadFailed(String error) {
    return 'Sessions konnten nicht geladen werden: $error';
  }

  @override
  String get sessionIncomplete => 'unvollständig';

  @override
  String get sessionTitle => 'Session';

  @override
  String get sessionGone => 'Diese Session gibt es nicht mehr.';

  @override
  String sessionLoadFailed(String error) {
    return 'Session konnte nicht geladen werden: $error';
  }

  @override
  String get sessionIncompleteNote =>
      'Unvollständig: Die App wurde während der Session beendet. Gespeichert ist alles bis kurz davor.';

  @override
  String get sessionDistance => 'Distanz';

  @override
  String get sessionTime => 'Zeit';

  @override
  String get sessionAveragePace => 'Ø Pace';

  @override
  String get sessionAverageWatts => 'Ø Watt';

  @override
  String get sessionAverageStrokeRate => 'Ø spm';

  @override
  String get sessionStrokes => 'Schläge';

  @override
  String sessionLap(int lap) {
    return 'Runde $lap';
  }

  @override
  String get summaryTitle => 'Session beendet';

  @override
  String get summaryLaps => 'Runden';

  @override
  String get summaryLapBarHint => 'Balken: Anteil in der Zone pro Runde';

  @override
  String get summaryBestLap => 'Beste Runde';

  @override
  String get actionDone => 'Fertig';

  @override
  String get sourceRower => 'Rudergerät';

  @override
  String get sourceSimulatorName => 'Simulator';

  @override
  String get sourceSimulatorFtmsName => 'Simulator (FTMS)';

  @override
  String get sourceReplayName => 'Replay';

  @override
  String replayName(String date) {
    return 'Replay $date';
  }

  @override
  String get replayNoData =>
      'Für diese Session gibt es keine Rohdaten zum Abspielen.';

  @override
  String get sessionDeleteTitle => 'Session löschen?';

  @override
  String sessionDeleteBody(String date) {
    return 'Die Session vom $date wird mit Verlauf und Rohdaten endgültig gelöscht.';
  }

  @override
  String get sessionExported => 'Session exportiert.';

  @override
  String sessionExportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get sessionImported => 'Session importiert.';

  @override
  String sessionImportFailed(String app, String error) {
    return 'Die Datei ist keine lesbare $app-Session: $error';
  }

  @override
  String get actionEdit => 'Bearbeiten';

  @override
  String get fieldName => 'Name';

  @override
  String lapsCount(int laps) {
    String _temp0 = intl.Intl.pluralLogic(
      laps,
      locale: localeName,
      other: '$laps Runden',
      one: '1 Runde',
    );
    return '$_temp0';
  }

  @override
  String get lapsOpen => 'offen';

  @override
  String get templatesTitle => 'Vorlage rudern';

  @override
  String get tabTemplates => 'Vorlagen';

  @override
  String get tabCourses => 'Strecken';

  @override
  String get tabZones => 'Zonen';

  @override
  String get templateCreate => 'Vorlage anlegen';

  @override
  String get templateStart => 'Starten';

  @override
  String get templatesEmpty => 'Noch keine Vorlagen angelegt.';

  @override
  String templatesLoadFailed(String error) {
    return 'Vorlagen konnten nicht geladen werden: $error';
  }

  @override
  String get templateNeedsCourseTitle => 'Zuerst eine Strecke anlegen';

  @override
  String get templateNeedsCourseBody =>
      'Eine Vorlage rudert eine Strecke. Lege dafür zuerst eine Strecke an.';

  @override
  String get templateNeedsCourse =>
      'Für eine Vorlage brauchst du zuerst eine Strecke.';

  @override
  String get courseCreate => 'Strecke anlegen';

  @override
  String get templateDeleteTitle => 'Vorlage löschen?';

  @override
  String templateDeleteBody(String name) {
    return '„$name“ wird gelöscht. Damit geruderte Sessions bleiben erhalten.';
  }

  @override
  String get templateNew => 'Neue Vorlage';

  @override
  String get templateEdit => 'Vorlage bearbeiten';

  @override
  String get templateNameMissing => 'Der Name fehlt.';

  @override
  String get templateCourseMissing => 'Wähle eine Strecke.';

  @override
  String get templateCourse => 'Strecke';

  @override
  String get templateFixedLaps => 'Feste Anzahl';

  @override
  String get templateOpenLaps => 'Offen bis Stopp';

  @override
  String get templateLaps => 'Runden';

  @override
  String templateLapsUnit(int laps) {
    String _temp0 = intl.Intl.pluralLogic(
      laps,
      locale: localeName,
      other: 'Runden',
      one: 'Runde',
    );
    return '$_temp0';
  }

  @override
  String get templateResult => 'Ergibt';

  @override
  String get templateResultOpen => 'pro Runde, bis du die Session beendest';

  @override
  String get coursesTitle => 'Strecken';

  @override
  String get coursesEmpty => 'Noch keine Strecken angelegt.';

  @override
  String coursesLoadFailed(String error) {
    return 'Strecken konnten nicht geladen werden: $error';
  }

  @override
  String get courseDeleteTitle => 'Strecke löschen?';

  @override
  String courseDeleteBody(String name) {
    return '„$name“ verschwindet aus der Liste. Bereits geruderte Sessions behalten ihre Runden.';
  }

  @override
  String courseDeleteTemplates(String templates) {
    return 'Diese Vorlagen verwenden die Strecke und werden mitgelöscht: $templates.';
  }

  @override
  String get courseNew => 'Neue Strecke';

  @override
  String get courseEdit => 'Strecke bearbeiten';

  @override
  String get courseNameMissing => 'Der Name fehlt.';

  @override
  String get courseSequence => 'Ablauf';

  @override
  String get coursePlaceZone => 'Zone einbauen';

  @override
  String get courseMoveZone => 'Zone verschieben';

  @override
  String get coursePlaceHere => 'Hier eine Zone einbauen';

  @override
  String get courseRemoveZone => 'Zone entfernen';

  @override
  String get coursePlace => 'Einbauen';

  @override
  String get courseMove => 'Verschieben';

  @override
  String get courseNoZones => 'Noch keine Zonen angelegt. Lege zuerst eine an.';

  @override
  String get zoneCreate => 'Neue Zone anlegen';

  @override
  String courseStart(String unit) {
    return 'Start ($unit)';
  }

  @override
  String courseRange(String range) {
    return 'Strecke: $range';
  }

  @override
  String coursePlacedAt(String zone, String range) {
    return '„$zone“ liegt bei $range.';
  }

  @override
  String get courseOtherAxis => 'andere Achse';

  @override
  String get axisDistance => 'Distanz';

  @override
  String get axisTime => 'Zeit';

  @override
  String fieldLength(String unit) {
    return 'Länge ($unit)';
  }

  @override
  String get zonesTitle => 'Zonen';

  @override
  String get zoneCreateShort => 'Zone anlegen';

  @override
  String get zonesEmpty =>
      'Noch keine Zonen angelegt. Eine Zone ist ein Pace- oder Schlagzahl-Band über eine feste Länge, das du in Strecken einbaust.';

  @override
  String zonesLoadFailed(String error) {
    return 'Zonen konnten nicht geladen werden: $error';
  }

  @override
  String zoneUsage(int courses) {
    String _temp0 = intl.Intl.pluralLogic(
      courses,
      locale: localeName,
      other: 'in $courses Strecken',
      one: 'in 1 Strecke',
      zero: 'nicht verwendet',
    );
    return '$_temp0';
  }

  @override
  String get zoneNew => 'Neue Zone';

  @override
  String get zoneEdit => 'Zone bearbeiten';

  @override
  String get zoneDeleteTitle => 'Zone löschen?';

  @override
  String zoneDeleteBody(String name) {
    return '„$name“ verschwindet aus der Liste. Bereits geruderte Sessions behalten den Namen der Zone.';
  }

  @override
  String zoneDeleteCourses(String courses) {
    return 'In diesen Strecken wird ihre Stelle frei: $courses.';
  }

  @override
  String zoneInCourses(String courses) {
    return 'Steckt in $courses';
  }

  @override
  String get zoneInCoursesHint =>
      'Änderungen gelten in allen diesen Strecken. Wurde eine schon gerudert, bekommt sie eine neue Version, alte Sessions bleiben, wie sie waren.';

  @override
  String get zoneNameHint => 'z.B. Sprint';

  @override
  String get zonePaceBand => 'Pace-Band';

  @override
  String get zonePaceFastest => 'Schnellste';

  @override
  String get zonePaceSlowest => 'Langsamste';

  @override
  String get zoneSpmBand => 'Schlagzahl-Band';

  @override
  String get zoneSpmFrom => 'Mindestens';

  @override
  String get zoneSpmTo => 'Höchstens';

  @override
  String get zoneBandHint =>
      'Mindestens ein Band ist nötig, Pace, Schlagzahl oder beides.';

  @override
  String get dateTimePattern => 'dd.MM.yyyy, HH:mm';

  @override
  String get actionOk => 'OK';

  @override
  String oarStepperMore(String step) {
    return '$step mehr';
  }

  @override
  String oarStepperLess(String step) {
    return '$step weniger';
  }

  @override
  String stepSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds Sekunden',
      one: '1 Sekunde',
    );
    return '$_temp0';
  }

  @override
  String stepStrokes(int strokes) {
    String _temp0 = intl.Intl.pluralLogic(
      strokes,
      locale: localeName,
      other: '$strokes Schläge',
      one: '1 Schlag',
    );
    return '$_temp0';
  }

  @override
  String get fieldAxis => 'Achse';

  @override
  String get fieldLengthPlain => 'Länge';

  @override
  String courseZonesSummary(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zonen',
      one: 'Zone $name',
      zero: 'ohne Zonen',
    );
    return '$_temp0';
  }

  @override
  String courseRowedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count× gerudert',
      zero: 'noch nie gerudert',
    );
    return '$_temp0';
  }

  @override
  String get courseLegendShade => 'Helligkeit = Tempo';

  @override
  String rankingLength(String length) {
    return 'Bestenliste $length';
  }

  @override
  String rankingLengthCurrent(String length) {
    return 'Bestenliste $length · aktuell';
  }

  @override
  String rankingPlace(int place) {
    return 'Platz $place';
  }

  @override
  String rankingPace(String pace) {
    return '$pace /500 m';
  }

  @override
  String get rankingPausesHint =>
      'Gemessen nach Wanduhr: Pausen zählen mit, auch in der Pace.';

  @override
  String get rankingEmpty =>
      'Noch keine Bestzeit. Es zählen nur vollständige Runden am Rudergerät, nicht im Simulator.';

  @override
  String rankingLoadFailed(String error) {
    return 'Bestenliste konnte nicht geladen werden: $error';
  }

  @override
  String courseZoneFrom(String start) {
    return 'ab $start';
  }

  @override
  String courseVersionHint(int count) {
    return '$count× gerudert. Änderst du Länge oder Zonen, entsteht eine neue Version. Alte Rundenzeiten bleiben vergleichbar.';
  }
}
