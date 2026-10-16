import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// Name of the app, e.g. in the task switcher.
  ///
  /// In de, this message translates to:
  /// **'AergRow'**
  String get appTitle;

  /// Start screen: option that searches for a PM5 or FTMS rower over Bluetooth.
  ///
  /// In de, this message translates to:
  /// **'Rudergerät suchen'**
  String get startFindRower;

  /// Start screen: explanation below 'Find rower'.
  ///
  /// In de, this message translates to:
  /// **'Mit deinem PM5 oder FTMS-Rudergerät über Bluetooth verbinden'**
  String get startFindRowerHint;

  /// Start screen: option that rows with the built-in simulator.
  ///
  /// In de, this message translates to:
  /// **'Simulator'**
  String get startSimulator;

  /// Start screen: explanation below 'Simulator'.
  ///
  /// In de, this message translates to:
  /// **'Ohne Erg ausprobieren, mit simuliertem Ruderer'**
  String get startSimulatorHint;

  /// Start screen: option that opens templates, courses and zones.
  ///
  /// In de, this message translates to:
  /// **'Vorlage rudern'**
  String get startTemplate;

  /// Start screen: explanation below 'Row a template'.
  ///
  /// In de, this message translates to:
  /// **'Eine Strecke in Runden rudern, mit Zonen für Pace und Schlagzahl'**
  String get startTemplateHint;

  /// Start screen: option that opens the recorded sessions.
  ///
  /// In de, this message translates to:
  /// **'Sessions'**
  String get startSessions;

  /// Start screen: explanation below 'Sessions'.
  ///
  /// In de, this message translates to:
  /// **'Aufgezeichnete Sessions ansehen, abspielen und austauschen'**
  String get startSessionsHint;

  /// Tooltip of the language button and title of the language dialog.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get languageChoice;

  /// Zone editor: the zone has no name
  ///
  /// In de, this message translates to:
  /// **'Der Name fehlt.'**
  String get zoneErrorNameMissing;

  /// Zone editor: the zone has no length
  ///
  /// In de, this message translates to:
  /// **'Die Länge fehlt.'**
  String get zoneErrorLengthMissing;

  /// Zone editor: neither a pace nor a stroke rate band is set
  ///
  /// In de, this message translates to:
  /// **'Es fehlt ein Band: Pace, Schlagzahl oder beides.'**
  String get zoneErrorBandMissing;

  /// Zone editor: only one bound of the pace band is set
  ///
  /// In de, this message translates to:
  /// **'Für das Pace-Band fehlt eine Grenze.'**
  String get zoneErrorPaceBoundMissing;

  /// Zone editor: the pace bounds are the wrong way round
  ///
  /// In de, this message translates to:
  /// **'Die schnellste Pace ist langsamer als die langsamste.'**
  String get zoneErrorPaceReversed;

  /// Zone editor: only one bound of the stroke rate band is set
  ///
  /// In de, this message translates to:
  /// **'Für das Schlagzahl-Band fehlt eine Grenze.'**
  String get zoneErrorSpmBoundMissing;

  /// Zone editor: the stroke rate bounds are the wrong way round
  ///
  /// In de, this message translates to:
  /// **'Die niedrigste Schlagzahl liegt über der höchsten.'**
  String get zoneErrorSpmReversed;

  /// A name the user gave, in quotes, e.g. in a list of courses
  ///
  /// In de, this message translates to:
  /// **'„{name}“'**
  String quotedName(String name);

  /// Course editor: the course has no length
  ///
  /// In de, this message translates to:
  /// **'Die Länge fehlt.'**
  String get placementLengthMissing;

  /// Course editor: a zone placed in the course was deleted
  ///
  /// In de, this message translates to:
  /// **'Eine eingebaute Zone gibt es nicht mehr.'**
  String get placementZoneMissing;

  /// Course editor: the zone and the course have different axes; the axes are 'distance' or 'time'
  ///
  /// In de, this message translates to:
  /// **'„{zone}“ misst {zoneAxis, select, distance{Distanz} other{Zeit}}, die Strecke {courseAxis, select, distance{Distanz} other{Zeit}}.'**
  String placementAxisMismatch(String zone, String zoneAxis, String courseAxis);

  /// Course editor: the zone is placed before 0
  ///
  /// In de, this message translates to:
  /// **'„{zone}“ beginnt vor dem Start der Strecke.'**
  String placementBeforeStart(String zone);

  /// Course editor: the zone ends after the course; range and length are formatted, e.g. '1800–2300 m' and '2000 m'
  ///
  /// In de, this message translates to:
  /// **'„{zone}“ ({range}) ragt über das Streckenende bei {length}.'**
  String placementBeyondEnd(String zone, String range, String length);

  /// Course editor: two placed zones overlap; the ranges are formatted, e.g. '1000–1500 m'
  ///
  /// In de, this message translates to:
  /// **'„{zone}“ ({range}) überschneidet „{other}“ ({otherRange}).'**
  String placementOverlap(
    String zone,
    String range,
    String other,
    String otherRange,
  );

  /// Zone editor: the changed zone no longer fits the courses it is placed in; courses is a list of quoted names
  ///
  /// In de, this message translates to:
  /// **'Die Änderung passt nicht in {courses}: Dort würde die Zone über das Streckenende ragen oder eine andere Zone überschneiden.'**
  String zoneConflict(String courses);

  /// Device list: dialog title when the rower could not be connected
  ///
  /// In de, this message translates to:
  /// **'Verbindung fehlgeschlagen'**
  String get connectFailedTitle;

  /// Device list: why a connection may fail; app is the app name, device the name the rower announces
  ///
  /// In de, this message translates to:
  /// **'{app} konnte sich nicht mit {device} verbinden.\n\nViele Rudergeräte erlauben nur eine Bluetooth-Verbindung gleichzeitig. Trenne andere Apps wie ErgData und versuche es erneut.'**
  String connectFailedBody(String app, String device);

  /// Device list: dialog title when the device is no rower
  ///
  /// In de, this message translates to:
  /// **'Kein Rudergerät'**
  String get connectNotARowerTitle;

  /// Device list: which devices the app supports; app is the app name
  ///
  /// In de, this message translates to:
  /// **'{app} unterstützt den PM5 am RowErg und Rudergeräte mit FTMS.'**
  String connectNotARowerHint(String app);

  /// Device list: the PM5 reports a SkiErg
  ///
  /// In de, this message translates to:
  /// **'Nur Rudergeräte werden unterstützt. Dieser PM5 gehört zu einem SkiErg.'**
  String get connectErrorSkiErg;

  /// Device list: the PM5 reports a BikeErg
  ///
  /// In de, this message translates to:
  /// **'Nur Rudergeräte werden unterstützt. Dieser PM5 gehört zu einem BikeErg.'**
  String get connectErrorBikeErg;

  /// Device list: an FTMS machine that is no rower
  ///
  /// In de, this message translates to:
  /// **'Nur Rudergeräte werden unterstützt. Das Gerät liefert keine Rudern-Daten.'**
  String get connectErrorNoRowerData;

  /// Connection indicator: the rower is connected
  ///
  /// In de, this message translates to:
  /// **'Verbunden'**
  String get stateConnected;

  /// Connection indicator and device list: a connection is being set up
  ///
  /// In de, this message translates to:
  /// **'Verbinde …'**
  String get stateConnecting;

  /// Connection indicator: searching for the rower
  ///
  /// In de, this message translates to:
  /// **'Suche …'**
  String get stateScanning;

  /// Connection indicator: the connection dropped and is being restored
  ///
  /// In de, this message translates to:
  /// **'Verbindung unterbrochen, verbinde neu …'**
  String get stateReconnecting;

  /// Connection indicator: no connection
  ///
  /// In de, this message translates to:
  /// **'Getrennt'**
  String get stateDisconnected;

  /// Badge while the simulator delivers the data
  ///
  /// In de, this message translates to:
  /// **'SIMULATOR'**
  String get sourceSimulator;

  /// Badge while the simulator delivers the data as an FTMS rower
  ///
  /// In de, this message translates to:
  /// **'SIMULATOR (FTMS)'**
  String get sourceSimulatorFtms;

  /// Badge while a recorded session is played back
  ///
  /// In de, this message translates to:
  /// **'REPLAY'**
  String get sourceReplay;

  /// Device list: title
  ///
  /// In de, this message translates to:
  /// **'Rudergerät suchen'**
  String get deviceListTitle;

  /// Device list: the scan failed; detail is the technical error
  ///
  /// In de, this message translates to:
  /// **'Die Suche nach Rudergeräten ist fehlgeschlagen.\n\n{detail}'**
  String deviceListScanFailed(String detail);

  /// Device list: button to scan again
  ///
  /// In de, this message translates to:
  /// **'Erneut suchen'**
  String get deviceListRetry;

  /// Device list: the scan found no rower, with hints
  ///
  /// In de, this message translates to:
  /// **'Kein Rudergerät gefunden.\n\n• Wecke das Rudergerät auf, am PM5 mit einer Taste, bis das Hauptmenü erscheint.\n• Trenne andere Apps wie ErgData, viele Rudergeräte erlauben nur eine Verbindung.\n• Geh näher an das Rudergerät.'**
  String get deviceListNothingFound;

  /// Device list: Bluetooth is switched off
  ///
  /// In de, this message translates to:
  /// **'Bluetooth ist ausgeschaltet. Schalte Bluetooth ein, um nach deinem Rudergerät zu suchen.'**
  String get bluetoothOff;

  /// Device list: the app lacks the Bluetooth permission; app is the app name
  ///
  /// In de, this message translates to:
  /// **'{app} darf Bluetooth nicht verwenden. Die Berechtigung ist nötig, um sich mit deinem Rudergerät zu verbinden. Erteile sie in den Systemeinstellungen unter Apps → {app} → Berechtigungen.'**
  String bluetoothUnauthorized(String app);

  /// Device list: the phone or computer has no Bluetooth LE
  ///
  /// In de, this message translates to:
  /// **'Dieses Gerät unterstützt kein Bluetooth LE.'**
  String get bluetoothUnsupported;

  /// Live display: button that ends the connection
  ///
  /// In de, this message translates to:
  /// **'Trennen'**
  String get liveDisconnect;

  /// Live display: banner when the rower stopped sending data
  ///
  /// In de, this message translates to:
  /// **'Keine Daten seit 3 Sekunden, die Werte sind veraltet.'**
  String get liveStale;

  /// Live display: button that starts recording a session
  ///
  /// In de, this message translates to:
  /// **'Session starten'**
  String get liveStartSession;

  /// Live display: button that ends the recorded session
  ///
  /// In de, this message translates to:
  /// **'Session beenden'**
  String get liveStopSession;

  /// Live display: label of the elapsed time
  ///
  /// In de, this message translates to:
  /// **'Zeit'**
  String get metricTime;

  /// Live display: label of the distance rowed
  ///
  /// In de, this message translates to:
  /// **'Meter'**
  String get metricDistance;

  /// Live display: label of the power
  ///
  /// In de, this message translates to:
  /// **'Watt'**
  String get metricWatts;

  /// Live display: label of the stroke rate
  ///
  /// In de, this message translates to:
  /// **'Schläge/min'**
  String get metricStrokeRate;

  /// Live display: label of the heart rate
  ///
  /// In de, this message translates to:
  /// **'Puls'**
  String get metricHeartRate;

  /// Live display: label of the pace per 500 metres
  ///
  /// In de, this message translates to:
  /// **'Pace /500 m'**
  String get metricPace;

  /// Course bar: the current lap of an open number of laps
  ///
  /// In de, this message translates to:
  /// **'Runde {lap}'**
  String courseLap(int lap);

  /// Course bar: the current lap and the planned number of laps
  ///
  /// In de, this message translates to:
  /// **'Runde {lap} von {laps}'**
  String courseLapOf(int lap, int laps);

  /// A part of a course without a zone
  ///
  /// In de, this message translates to:
  /// **'frei'**
  String get segmentFree;

  /// Name shown for a zone whose name is not known
  ///
  /// In de, this message translates to:
  /// **'Zone'**
  String get segmentZone;

  /// Course bar: what is left of the zone or free part; rest is e.g. '280 m' or '1:20'
  ///
  /// In de, this message translates to:
  /// **'noch {rest}'**
  String courseRest(String rest);

  /// Course bar: share of the lap rowed within the zone
  ///
  /// In de, this message translates to:
  /// **'Zone {percent} %'**
  String courseInZoneShare(int percent);

  /// Pace box: legend line of the whole course over all laps, followed by e.g. '1 460 / 3 000 m'
  ///
  /// In de, this message translates to:
  /// **'Gesamt'**
  String get paceBoxTotal;

  /// Pace box: legend line of the lap track with the current lap and the planned number of laps, e.g. 'Runde 2 / 3'
  ///
  /// In de, this message translates to:
  /// **'Runde {lap} / {laps}'**
  String paceBoxLapOf(int lap, int laps);

  /// Live display: the value is within the zone's band
  ///
  /// In de, this message translates to:
  /// **'in der Zone'**
  String get hintInZone;

  /// Live display: row faster to reach the pace band
  ///
  /// In de, this message translates to:
  /// **'schneller'**
  String get hintFaster;

  /// Live display: row slower to reach the pace band
  ///
  /// In de, this message translates to:
  /// **'langsamer'**
  String get hintSlower;

  /// Live display: there is no pace to compare with the band
  ///
  /// In de, this message translates to:
  /// **'keine Pace'**
  String get hintNoPace;

  /// Live display: raise the stroke rate to reach the band
  ///
  /// In de, this message translates to:
  /// **'mehr Schläge'**
  String get hintMoreStrokes;

  /// Live display: lower the stroke rate to reach the band
  ///
  /// In de, this message translates to:
  /// **'weniger Schläge'**
  String get hintFewerStrokes;

  /// Live display: there is no stroke rate to compare with the band
  ///
  /// In de, this message translates to:
  /// **'keine Schläge'**
  String get hintNoStrokes;

  /// Simulator: label of the pace the simulator rows
  ///
  /// In de, this message translates to:
  /// **'Ziel-Pace'**
  String get simTargetPace;

  /// Simulator: label of the stroke rate the simulator rows
  ///
  /// In de, this message translates to:
  /// **'Ziel-SPM'**
  String get simTargetStrokeRate;

  /// Simulator: tooltip to make the pace faster
  ///
  /// In de, this message translates to:
  /// **'Schneller'**
  String get simFaster;

  /// Simulator: tooltip to make the pace slower
  ///
  /// In de, this message translates to:
  /// **'Langsamer'**
  String get simSlower;

  /// Simulator: tooltip to raise the stroke rate
  ///
  /// In de, this message translates to:
  /// **'Mehr Schläge'**
  String get simMoreStrokes;

  /// Simulator: tooltip to lower the stroke rate
  ///
  /// In de, this message translates to:
  /// **'Weniger Schläge'**
  String get simFewerStrokes;

  /// Simulator: button that pauses rowing
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get simPause;

  /// Simulator: button that resumes rowing
  ///
  /// In de, this message translates to:
  /// **'Weiterrudern'**
  String get simResume;

  /// Button that closes a dialog without doing anything
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get actionCancel;

  /// Button or tooltip that deletes something
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get actionDelete;

  /// Button or tooltip that saves an editor
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get actionSave;

  /// Plays a recorded session back in the live display
  ///
  /// In de, this message translates to:
  /// **'Abspielen'**
  String get actionReplay;

  /// Exports a session as a file
  ///
  /// In de, this message translates to:
  /// **'Exportieren'**
  String get actionExport;

  /// Imports a session from a file
  ///
  /// In de, this message translates to:
  /// **'Importieren'**
  String get actionImport;

  /// Tooltip of the menu with the actions of a list entry
  ///
  /// In de, this message translates to:
  /// **'Aktionen'**
  String get actionMore;

  /// Sessions list: title
  ///
  /// In de, this message translates to:
  /// **'Sessions'**
  String get sessionsTitle;

  /// Sessions list: nothing recorded yet
  ///
  /// In de, this message translates to:
  /// **'Noch keine Sessions aufgezeichnet.'**
  String get sessionsEmpty;

  /// Sessions list: loading failed; error is the technical error
  ///
  /// In de, this message translates to:
  /// **'Sessions konnten nicht geladen werden: {error}'**
  String sessionsLoadFailed(String error);

  /// A session or lap that was not finished
  ///
  /// In de, this message translates to:
  /// **'unvollständig'**
  String get sessionIncomplete;

  /// Summary: title while the session is loading
  ///
  /// In de, this message translates to:
  /// **'Session'**
  String get sessionTitle;

  /// Summary: the session was deleted
  ///
  /// In de, this message translates to:
  /// **'Diese Session gibt es nicht mehr.'**
  String get sessionGone;

  /// Summary: loading failed; error is the technical error
  ///
  /// In de, this message translates to:
  /// **'Session konnte nicht geladen werden: {error}'**
  String sessionLoadFailed(String error);

  /// Summary: the app ended while recording
  ///
  /// In de, this message translates to:
  /// **'Unvollständig: Die App wurde während der Session beendet. Gespeichert ist alles bis kurz davor.'**
  String get sessionIncompleteNote;

  /// Summary: label of the distance rowed
  ///
  /// In de, this message translates to:
  /// **'Distanz'**
  String get sessionDistance;

  /// Summary: label of the time rowed
  ///
  /// In de, this message translates to:
  /// **'Zeit'**
  String get sessionTime;

  /// Summary: label of the average pace per 500 metres
  ///
  /// In de, this message translates to:
  /// **'⌀ Pace /500 m'**
  String get sessionAveragePace;

  /// Summary: label of the average power
  ///
  /// In de, this message translates to:
  /// **'⌀ Watt'**
  String get sessionAverageWatts;

  /// Summary: label of the average stroke rate
  ///
  /// In de, this message translates to:
  /// **'⌀ Schläge/min'**
  String get sessionAverageStrokeRate;

  /// Summary: label of the number of strokes
  ///
  /// In de, this message translates to:
  /// **'Schläge'**
  String get sessionStrokes;

  /// Summary: a lap of the course
  ///
  /// In de, this message translates to:
  /// **'Runde {lap}'**
  String sessionLap(int lap);

  /// Source of a session from an FTMS rower without a name
  ///
  /// In de, this message translates to:
  /// **'Rudergerät'**
  String get sourceRower;

  /// Source of a session from the simulator
  ///
  /// In de, this message translates to:
  /// **'Simulator'**
  String get sourceSimulatorName;

  /// Source of a session from the simulator as an FTMS rower
  ///
  /// In de, this message translates to:
  /// **'Simulator (FTMS)'**
  String get sourceSimulatorFtmsName;

  /// Source of a session recorded during a replay
  ///
  /// In de, this message translates to:
  /// **'Replay'**
  String get sourceReplayName;

  /// Name of a replayed session in the live display; date is the start of the session
  ///
  /// In de, this message translates to:
  /// **'Replay {date}'**
  String replayName(String date);

  /// Sessions: the session cannot be played back
  ///
  /// In de, this message translates to:
  /// **'Für diese Session gibt es keine Rohdaten zum Abspielen.'**
  String get replayNoData;

  /// Sessions: title of the delete confirmation
  ///
  /// In de, this message translates to:
  /// **'Session löschen?'**
  String get sessionDeleteTitle;

  /// Sessions: delete confirmation; date is the start of the session
  ///
  /// In de, this message translates to:
  /// **'Die Session vom {date} wird mit Verlauf und Rohdaten endgültig gelöscht.'**
  String sessionDeleteBody(String date);

  /// Sessions: the export was saved
  ///
  /// In de, this message translates to:
  /// **'Session exportiert.'**
  String get sessionExported;

  /// Sessions: the export failed; error is the technical error
  ///
  /// In de, this message translates to:
  /// **'Export fehlgeschlagen: {error}'**
  String sessionExportFailed(String error);

  /// Sessions: the file was imported
  ///
  /// In de, this message translates to:
  /// **'Session importiert.'**
  String get sessionImported;

  /// Sessions: the file could not be imported; app is the app name, error the technical error
  ///
  /// In de, this message translates to:
  /// **'Die Datei ist keine lesbare {app}-Session: {error}'**
  String sessionImportFailed(String app, String error);

  /// Menu entry that opens the editor
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get actionEdit;

  /// Label of the name field in the editors
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// Number of laps of a template
  ///
  /// In de, this message translates to:
  /// **'{laps, plural, =1{1 Runde} other{{laps} Runden}}'**
  String lapsCount(int laps);

  /// A template with an open number of laps
  ///
  /// In de, this message translates to:
  /// **'offen'**
  String get lapsOpen;

  /// Templates: title
  ///
  /// In de, this message translates to:
  /// **'Vorlage rudern'**
  String get templatesTitle;

  /// Templates: tab with the templates
  ///
  /// In de, this message translates to:
  /// **'Vorlagen'**
  String get tabTemplates;

  /// Templates: tab with the courses
  ///
  /// In de, this message translates to:
  /// **'Strecken'**
  String get tabCourses;

  /// Templates: tab with the zones
  ///
  /// In de, this message translates to:
  /// **'Zonen'**
  String get tabZones;

  /// Templates: button that creates a template
  ///
  /// In de, this message translates to:
  /// **'Vorlage anlegen'**
  String get templateCreate;

  /// Templates: there is no template
  ///
  /// In de, this message translates to:
  /// **'Noch keine Vorlagen angelegt.'**
  String get templatesEmpty;

  /// Templates: loading failed; error is the technical error
  ///
  /// In de, this message translates to:
  /// **'Vorlagen konnten nicht geladen werden: {error}'**
  String templatesLoadFailed(String error);

  /// Templates: dialog title when there is no course
  ///
  /// In de, this message translates to:
  /// **'Zuerst eine Strecke anlegen'**
  String get templateNeedsCourseTitle;

  /// Templates: dialog text when there is no course
  ///
  /// In de, this message translates to:
  /// **'Eine Vorlage rudert eine Strecke. Lege dafür zuerst eine Strecke an.'**
  String get templateNeedsCourseBody;

  /// Templates: shown instead of the list when there is no course
  ///
  /// In de, this message translates to:
  /// **'Für eine Vorlage brauchst du zuerst eine Strecke.'**
  String get templateNeedsCourse;

  /// Button that creates a course
  ///
  /// In de, this message translates to:
  /// **'Strecke anlegen'**
  String get courseCreate;

  /// Templates: title of the dialog that picks the source; name is the template
  ///
  /// In de, this message translates to:
  /// **'„{name}“ rudern'**
  String templateRow(String name);

  /// Templates: source that simulates an FTMS rower
  ///
  /// In de, this message translates to:
  /// **'Simulator (FTMS)'**
  String get templateSimulatorFtms;

  /// Templates: what the FTMS simulator leaves out
  ///
  /// In de, this message translates to:
  /// **'Wie ein FTMS-Rudergerät, ohne Schlagdetails'**
  String get templateSimulatorFtmsHint;

  /// Templates: title of the delete confirmation
  ///
  /// In de, this message translates to:
  /// **'Vorlage löschen?'**
  String get templateDeleteTitle;

  /// Templates: delete confirmation; name is the template
  ///
  /// In de, this message translates to:
  /// **'„{name}“ wird gelöscht. Damit geruderte Sessions bleiben erhalten.'**
  String templateDeleteBody(String name);

  /// Template editor: title for a new template
  ///
  /// In de, this message translates to:
  /// **'Neue Vorlage'**
  String get templateNew;

  /// Template editor: title for an existing template
  ///
  /// In de, this message translates to:
  /// **'Vorlage bearbeiten'**
  String get templateEdit;

  /// Template editor: the template has no name
  ///
  /// In de, this message translates to:
  /// **'Der Name fehlt.'**
  String get templateNameMissing;

  /// Template editor: no course chosen
  ///
  /// In de, this message translates to:
  /// **'Wähle eine Strecke.'**
  String get templateCourseMissing;

  /// Template editor: the number of laps is below 1
  ///
  /// In de, this message translates to:
  /// **'Die Rundenzahl muss mindestens 1 sein.'**
  String get templateLapsInvalid;

  /// Template editor: label of the course field
  ///
  /// In de, this message translates to:
  /// **'Strecke'**
  String get templateCourse;

  /// Template editor: switch for an open number of laps
  ///
  /// In de, this message translates to:
  /// **'Offene Rundenzahl'**
  String get templateOpenLaps;

  /// Template editor: what an open number of laps means
  ///
  /// In de, this message translates to:
  /// **'Runden, bis du die Session beendest'**
  String get templateOpenLapsHint;

  /// Template editor: label of the number of laps
  ///
  /// In de, this message translates to:
  /// **'Runden'**
  String get templateLaps;

  /// Courses: title
  ///
  /// In de, this message translates to:
  /// **'Strecken'**
  String get coursesTitle;

  /// Courses: there is no course
  ///
  /// In de, this message translates to:
  /// **'Noch keine Strecken angelegt.'**
  String get coursesEmpty;

  /// Courses: loading failed; error is the technical error
  ///
  /// In de, this message translates to:
  /// **'Strecken konnten nicht geladen werden: {error}'**
  String coursesLoadFailed(String error);

  /// Courses: title of the delete confirmation
  ///
  /// In de, this message translates to:
  /// **'Strecke löschen?'**
  String get courseDeleteTitle;

  /// Courses: delete confirmation; name is the course
  ///
  /// In de, this message translates to:
  /// **'„{name}“ verschwindet aus der Liste. Bereits geruderte Sessions behalten ihre Runden.'**
  String courseDeleteBody(String name);

  /// Courses: templates deleted with the course; templates is a list of quoted names
  ///
  /// In de, this message translates to:
  /// **'Diese Vorlagen verwenden die Strecke und werden mitgelöscht: {templates}.'**
  String courseDeleteTemplates(String templates);

  /// Course editor: title for a new course
  ///
  /// In de, this message translates to:
  /// **'Neue Strecke'**
  String get courseNew;

  /// Course editor: title for an existing course
  ///
  /// In de, this message translates to:
  /// **'Strecke bearbeiten'**
  String get courseEdit;

  /// Course editor: the course has no name
  ///
  /// In de, this message translates to:
  /// **'Der Name fehlt.'**
  String get courseNameMissing;

  /// Course editor: a zone is placed before the length is known
  ///
  /// In de, this message translates to:
  /// **'Gib zuerst die Länge der Strecke ein.'**
  String get courseLengthFirst;

  /// Course editor: shown instead of the parts while there is no length
  ///
  /// In de, this message translates to:
  /// **'Gib eine Länge ein, um Zonen einzubauen.'**
  String get courseLengthHint;

  /// Course editor: heading above the parts of the course
  ///
  /// In de, this message translates to:
  /// **'Ablauf'**
  String get courseSequence;

  /// Course editor: button and dialog title to place a zone
  ///
  /// In de, this message translates to:
  /// **'Zone einbauen'**
  String get coursePlaceZone;

  /// Course editor: dialog title to move a placed zone
  ///
  /// In de, this message translates to:
  /// **'Zone verschieben'**
  String get courseMoveZone;

  /// Course editor: tooltip on a free part
  ///
  /// In de, this message translates to:
  /// **'Hier eine Zone einbauen'**
  String get coursePlaceHere;

  /// Course editor: tooltip on a placed zone
  ///
  /// In de, this message translates to:
  /// **'Zone entfernen'**
  String get courseRemoveZone;

  /// Place dialog: button that places the zone
  ///
  /// In de, this message translates to:
  /// **'Einbauen'**
  String get coursePlace;

  /// Place dialog: button that moves the zone
  ///
  /// In de, this message translates to:
  /// **'Verschieben'**
  String get courseMove;

  /// Place dialog: there is no zone
  ///
  /// In de, this message translates to:
  /// **'Noch keine Zonen angelegt. Lege zuerst eine an.'**
  String get courseNoZones;

  /// Place dialog: button that creates a zone
  ///
  /// In de, this message translates to:
  /// **'Neue Zone anlegen'**
  String get zoneCreate;

  /// Place dialog: label of the start; unit is 'm' or 'm:ss'
  ///
  /// In de, this message translates to:
  /// **'Start ({unit})'**
  String courseStart(String unit);

  /// Place dialog: the range of the course, e.g. '0–2000 m'
  ///
  /// In de, this message translates to:
  /// **'Strecke: {range}'**
  String courseRange(String range);

  /// Place dialog: where the zone would lie, e.g. '500–600 m'
  ///
  /// In de, this message translates to:
  /// **'„{zone}“ liegt bei {range}.'**
  String coursePlacedAt(String zone, String range);

  /// Place dialog: the zone is measured in time on a distance course or the other way round
  ///
  /// In de, this message translates to:
  /// **'andere Achse'**
  String get courseOtherAxis;

  /// Courses and zones measured in metres
  ///
  /// In de, this message translates to:
  /// **'Distanz'**
  String get axisDistance;

  /// Courses and zones measured in time
  ///
  /// In de, this message translates to:
  /// **'Zeit'**
  String get axisTime;

  /// Label of the length; unit is 'm' or 'm:ss'
  ///
  /// In de, this message translates to:
  /// **'Länge ({unit})'**
  String fieldLength(String unit);

  /// Editors: the length typed cannot be read
  ///
  /// In de, this message translates to:
  /// **'Die Länge „{text}“ ist ungültig.'**
  String invalidLength(String text);

  /// Place dialog: the start typed cannot be read
  ///
  /// In de, this message translates to:
  /// **'Der Start „{text}“ ist ungültig.'**
  String invalidStart(String text);

  /// Zones: title
  ///
  /// In de, this message translates to:
  /// **'Zonen'**
  String get zonesTitle;

  /// Zones: button that creates a zone
  ///
  /// In de, this message translates to:
  /// **'Zone anlegen'**
  String get zoneCreateShort;

  /// Zones: there is no zone, with what a zone is
  ///
  /// In de, this message translates to:
  /// **'Noch keine Zonen angelegt. Eine Zone ist ein Pace- oder Schlagzahl-Band über eine feste Länge, das du in Strecken einbaust.'**
  String get zonesEmpty;

  /// Zones: loading failed; error is the technical error
  ///
  /// In de, this message translates to:
  /// **'Zonen konnten nicht geladen werden: {error}'**
  String zonesLoadFailed(String error);

  /// Zones: in how many courses the zone is placed
  ///
  /// In de, this message translates to:
  /// **'{courses, plural, =0{nicht verwendet} =1{in 1 Strecke} other{in {courses} Strecken}}'**
  String zoneUsage(int courses);

  /// Zone editor: title for a new zone
  ///
  /// In de, this message translates to:
  /// **'Neue Zone'**
  String get zoneNew;

  /// Zone editor: title for an existing zone
  ///
  /// In de, this message translates to:
  /// **'Zone bearbeiten'**
  String get zoneEdit;

  /// Zone editor: title of the delete confirmation
  ///
  /// In de, this message translates to:
  /// **'Zone löschen?'**
  String get zoneDeleteTitle;

  /// Zone editor: delete confirmation; name is the zone
  ///
  /// In de, this message translates to:
  /// **'„{name}“ verschwindet aus der Liste. Bereits geruderte Sessions behalten den Namen der Zone.'**
  String zoneDeleteBody(String name);

  /// Zone editor: courses the zone is removed from; courses is a list of quoted names
  ///
  /// In de, this message translates to:
  /// **'In diesen Strecken wird ihre Stelle frei: {courses}.'**
  String zoneDeleteCourses(String courses);

  /// Zone editor: the courses the zone is placed in; courses is a list of quoted names
  ///
  /// In de, this message translates to:
  /// **'Steckt in {courses}'**
  String zoneInCourses(String courses);

  /// Zone editor: what a change to a placed zone does
  ///
  /// In de, this message translates to:
  /// **'Änderungen gelten in allen diesen Strecken. Wurde eine schon gerudert, bekommt sie eine neue Version, alte Sessions bleiben, wie sie waren.'**
  String get zoneInCoursesHint;

  /// Zone editor: example of a zone name
  ///
  /// In de, this message translates to:
  /// **'z.B. Sprint'**
  String get zoneNameHint;

  /// Zone editor: heading of the pace band
  ///
  /// In de, this message translates to:
  /// **'Pace pro 500 m'**
  String get zonePaceBand;

  /// Zone editor: the fastest pace of the band
  ///
  /// In de, this message translates to:
  /// **'schnellste'**
  String get zonePaceFastest;

  /// Zone editor: the slowest pace of the band
  ///
  /// In de, this message translates to:
  /// **'langsamste'**
  String get zonePaceSlowest;

  /// Zone editor: heading of the stroke rate band
  ///
  /// In de, this message translates to:
  /// **'Schlagzahl'**
  String get zoneSpmBand;

  /// Zone editor: the lowest stroke rate of the band
  ///
  /// In de, this message translates to:
  /// **'ab'**
  String get zoneSpmFrom;

  /// Zone editor: the highest stroke rate of the band
  ///
  /// In de, this message translates to:
  /// **'bis'**
  String get zoneSpmTo;

  /// Zone editor: what a zone needs
  ///
  /// In de, this message translates to:
  /// **'Mindestens ein Band ist nötig, Pace, Schlagzahl oder beides.'**
  String get zoneBandHint;

  /// Zone editor: the pace typed cannot be read
  ///
  /// In de, this message translates to:
  /// **'Die Pace „{text}“ ist ungültig.'**
  String invalidPace(String text);

  /// Zone editor: the stroke rate typed cannot be read
  ///
  /// In de, this message translates to:
  /// **'Die Schlagzahl „{text}“ ist ungültig.'**
  String invalidStrokeRate(String text);

  /// Pattern of a date with time for the intl package's DateFormat, e.g. '15.10.2026, 18:30'; keep the 24-hour clock
  ///
  /// In de, this message translates to:
  /// **'dd.MM.yyyy, HH:mm'**
  String get dateTimePattern;

  /// Button that closes a message
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// Screen reader label of the number button whose oar blade points up, e.g. '5 Sekunden mehr'
  ///
  /// In de, this message translates to:
  /// **'{step} mehr'**
  String oarStepperMore(String step);

  /// Screen reader label of the number button whose oar blade points down, e.g. '1 Schlag weniger'
  ///
  /// In de, this message translates to:
  /// **'{step} weniger'**
  String oarStepperLess(String step);

  /// Step of a number button in seconds, read out by screen readers, e.g. for the pace
  ///
  /// In de, this message translates to:
  /// **'{seconds, plural, =1{1 Sekunde} other{{seconds} Sekunden}}'**
  String stepSeconds(int seconds);

  /// Step of a number button in strokes per minute, read out by screen readers
  ///
  /// In de, this message translates to:
  /// **'{strokes, plural, =1{1 Schlag} other{{strokes} Schläge}}'**
  String stepStrokes(int strokes);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
