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
  /// **'Stroke & Split'**
  String get appTitle;

  /// Choose devices and start screen: explanation below 'Simulator'
  ///
  /// In de, this message translates to:
  /// **'Ohne Erg ausprobieren, mit simuliertem Ruderer'**
  String get startSimulatorHint;

  /// Start screen: option that opens the recorded sessions.
  ///
  /// In de, this message translates to:
  /// **'Sessions'**
  String get startSessions;

  /// Tooltip of the language button and title of the language dialog.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get languageChoice;

  /// Start screen: line below the name of the app
  ///
  /// In de, this message translates to:
  /// **'Gegen dich selbst rudern'**
  String get startTagline;

  /// Start screen: button that opens the templates to pick one
  ///
  /// In de, this message translates to:
  /// **'Rudern'**
  String get startRow;

  /// Start screen: button that starts rowing without a template
  ///
  /// In de, this message translates to:
  /// **'Frei rudern'**
  String get startRowFree;

  /// Start screen: device row before a rower is chosen
  ///
  /// In de, this message translates to:
  /// **'Kein Rudergerät gewählt'**
  String get startNoRower;

  /// Start screen: device row, the chosen rower is not connected right now
  ///
  /// In de, this message translates to:
  /// **'Verbindet beim Start'**
  String get startConnectsLater;

  /// Start screen: button in the device row that ends the connection to the rower
  ///
  /// In de, this message translates to:
  /// **'Trennen'**
  String get startDisconnect;

  /// Choose devices and start screen: explanation below 'Simulator (FTMS)'
  ///
  /// In de, this message translates to:
  /// **'Wie ein FTMS-Rudergerät, ohne Schlagdetails'**
  String get startSimulatorFtmsHint;

  /// Title of the first screen, where the rower is chosen; also the link to it
  ///
  /// In de, this message translates to:
  /// **'Geräte wählen'**
  String get devicesTitle;

  /// Choose devices: label above the rowers and simulators
  ///
  /// In de, this message translates to:
  /// **'Rudergerät'**
  String get devicesRower;

  /// Choose devices: button that connects the chosen rower and opens the start screen
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get devicesNext;

  /// Choose devices: the rower chosen last is not in range
  ///
  /// In de, this message translates to:
  /// **'nicht gefunden'**
  String get devicesNotFound;

  /// Choose devices: label above the heart rate strap
  ///
  /// In de, this message translates to:
  /// **'Pulsgurt'**
  String get devicesHeartRateMonitor;

  /// Choose devices: no heart rate strap is paired
  ///
  /// In de, this message translates to:
  /// **'Kein Gurt'**
  String get devicesNoStrap;

  /// Choose devices: explanation below 'Kein Gurt', the strap is optional
  ///
  /// In de, this message translates to:
  /// **'Optional, für Puls und RR-Intervalle direkt vom Gurt'**
  String get devicesNoStrapHint;

  /// Choose devices: line below the name of the paired heart rate strap
  ///
  /// In de, this message translates to:
  /// **'Gekoppelt'**
  String get devicesStrapPaired;

  /// Choose devices: button that opens the strap search when no strap is paired
  ///
  /// In de, this message translates to:
  /// **'Gurt koppeln'**
  String get devicesStrapPair;

  /// Choose devices: button that opens the strap search to pair another strap
  ///
  /// In de, this message translates to:
  /// **'Gurt wechseln'**
  String get devicesStrapChange;

  /// Choose devices: button that forgets the paired heart rate strap
  ///
  /// In de, this message translates to:
  /// **'Vergessen'**
  String get devicesStrapForget;

  /// Strap search: title of the screen listing the heart rate straps in range
  ///
  /// In de, this message translates to:
  /// **'Pulsgurt suchen'**
  String get strapSearchTitle;

  /// Strap search: the scan found no strap within 15 seconds, with hints
  ///
  /// In de, this message translates to:
  /// **'Kein Gurt gefunden.\n\n• Feuchte die Elektroden an und lege den Gurt an, erst dann sendet er.\n• Trenne den Gurt von anderen Apps oder Uhren, viele Gurte erlauben nur wenige Verbindungen gleichzeitig.\n• Geh näher an den Gurt.'**
  String get strapSearchNothingFound;

  /// Strap search: the scan failed; detail is the technical error
  ///
  /// In de, this message translates to:
  /// **'Die Suche nach Pulsgurten ist fehlgeschlagen.\n\n{detail}'**
  String strapSearchFailed(String detail);

  /// Strap search: Bluetooth is switched off
  ///
  /// In de, this message translates to:
  /// **'Bluetooth ist ausgeschaltet. Schalte Bluetooth ein, um nach deinem Pulsgurt zu suchen.'**
  String get strapBluetoothOff;

  /// Shown at the start while the rower chosen last is searched; device is its name
  ///
  /// In de, this message translates to:
  /// **'Suche {device} …'**
  String launchSearching(String device);

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

  /// Zone editor: the resistance level of the zone is below 1
  ///
  /// In de, this message translates to:
  /// **'Die Stufe muss mindestens 1 sein.'**
  String get zoneErrorResistanceLevelTooLow;

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

  /// Live display: screen reader text and tooltip of the dot that shows the heart rate strap's connection state
  ///
  /// In de, this message translates to:
  /// **'Pulsgurt: {state}'**
  String heartRateStateLabel(String state);

  /// Live display: the heart rate strap is paired, but waits for the rower to be connected before it connects
  ///
  /// In de, this message translates to:
  /// **'Wartet auf das Rudergerät'**
  String get heartRateStateWaiting;

  /// Live display: the heart rate strap could not be connected, e.g. because it is already connected to a watch or the rower
  ///
  /// In de, this message translates to:
  /// **'Pulsgurt nicht erreichbar. Viele Gurte erlauben nur eine oder zwei Bluetooth-Verbindungen gleichzeitig. Trenne ihn von Uhr oder Rudergerät und versuche es erneut.'**
  String get heartRateFailedUnreachable;

  /// Live display: the paired device offers no Heart Rate service; „Geräte wählen“ is the screen to choose rower and strap
  ///
  /// In de, this message translates to:
  /// **'Das gekoppelte Gerät liefert keinen Puls. Koppele in „Geräte wählen“ einen Pulsgurt.'**
  String get heartRateFailedNoService;

  /// Live display: the heart rate strap dropped and could not be reconnected within 30 seconds
  ///
  /// In de, this message translates to:
  /// **'Verbindung zum Pulsgurt verloren. Sitzt er richtig und ist er in Reichweite?'**
  String get heartRateFailedLost;

  /// Live display: button that tries again to connect the heart rate strap
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get heartRateRetry;

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
  /// **'Distanz'**
  String get metricDistance;

  /// Live display: label of the power
  ///
  /// In de, this message translates to:
  /// **'Watt'**
  String get metricWatts;

  /// Live display: resistance level the rower reports, small below the watts
  ///
  /// In de, this message translates to:
  /// **'Stufe {level}'**
  String metricResistanceLevel(int level);

  /// Live display: shown for a moment below the watts when the rower refused a new resistance level
  ///
  /// In de, this message translates to:
  /// **'Stufe nicht gesetzt'**
  String get metricResistanceRefused;

  /// Live display: label of the button that lowers the resistance level by one (for screen readers)
  ///
  /// In de, this message translates to:
  /// **'Stufe senken'**
  String get resistanceLower;

  /// Live display: label of the button that raises the resistance level by one (for screen readers)
  ///
  /// In de, this message translates to:
  /// **'Stufe erhöhen'**
  String get resistanceRaise;

  /// Live display: label of the stroke rate
  ///
  /// In de, this message translates to:
  /// **'Schlagzahl'**
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

  /// Live display: label of the calories burnt, in the line below the tiles
  ///
  /// In de, this message translates to:
  /// **'Kalorien'**
  String get metricCalories;

  /// Live display: label of the average pace per 500 metres since the start, in the line below the tiles
  ///
  /// In de, this message translates to:
  /// **'Ø Pace'**
  String get metricAveragePace;

  /// Live display on a template: label of the time rowed in the current lap
  ///
  /// In de, this message translates to:
  /// **'Runde'**
  String get metricLapTime;

  /// Live display in landscape on a template: short button that ends the recorded session
  ///
  /// In de, this message translates to:
  /// **'Beenden'**
  String get liveStopShort;

  /// Live display on a template: notice while the session waits for the first stroke to start
  ///
  /// In de, this message translates to:
  /// **'Bereit – startet mit dem ersten Schlag'**
  String get liveReadyForFirstStroke;

  /// Live display: large notice while the session is paused because the rower stopped; it goes on with the next stroke
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get livePaused;

  /// Live display: title of the force curve of the last stroke
  ///
  /// In de, this message translates to:
  /// **'Kraftkurve'**
  String get liveForceCurve;

  /// Live display on a template: short label of the narrow strip with the force curve
  ///
  /// In de, this message translates to:
  /// **'Kraft'**
  String get liveForceCurveShort;

  /// Live display: legend of the force curve of the last stroke
  ///
  /// In de, this message translates to:
  /// **'Letzter'**
  String get liveForceCurveLast;

  /// Live display: legend of the force curve of the stroke before the last one, drawn in grey
  ///
  /// In de, this message translates to:
  /// **'Vorheriger'**
  String get liveForceCurvePrevious;

  /// Live display: force curve card before the first curve of the session has arrived
  ///
  /// In de, this message translates to:
  /// **'Warte auf ersten Schlag'**
  String get liveForceCurveWaiting;

  /// Live display: a force in whole Newton, on the scale beside the force curve and as the peak force of the last stroke
  ///
  /// In de, this message translates to:
  /// **'{newtons} N'**
  String liveForceNewtons(int newtons);

  /// Course bar: the current lap of an open number of laps
  ///
  /// In de, this message translates to:
  /// **'Runde {lap}'**
  String courseLap(int lap);

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

  /// Pace box: legend line with the gap to the ghost of the template, i.e. its best session rowed again for comparison; followed by e.g. '7.6 s vor dir'
  ///
  /// In de, this message translates to:
  /// **'Ghost'**
  String get paceBoxGhost;

  /// Pace box: the ghost is ahead of the rower, who is behind, by a time or a distance
  ///
  /// In de, this message translates to:
  /// **'{amount} vor dir'**
  String paceBoxGhostAhead(String amount);

  /// Pace box: the ghost is behind the rower, who is ahead, by a time or a distance
  ///
  /// In de, this message translates to:
  /// **'{amount} hinter dir'**
  String paceBoxGhostBehind(String amount);

  /// Pace box: the rower and the ghost are level
  ///
  /// In de, this message translates to:
  /// **'gleichauf'**
  String get paceBoxGhostLevel;

  /// Live display: the band of the zone that starts in a few seconds, e.g. 'Gleich 2:05–2:10' or 'Gleich 20–24 spm'
  ///
  /// In de, this message translates to:
  /// **'Gleich {band}'**
  String hintUpcoming(String band);

  /// Live display: the value is within the zone's band
  ///
  /// In de, this message translates to:
  /// **'In der Zone'**
  String get hintInZone;

  /// Live display: row faster to reach the pace band
  ///
  /// In de, this message translates to:
  /// **'Schneller'**
  String get hintFaster;

  /// Live display: row slower to reach the pace band
  ///
  /// In de, this message translates to:
  /// **'Langsamer'**
  String get hintSlower;

  /// Live display: there is no pace to compare with the band
  ///
  /// In de, this message translates to:
  /// **'Keine Pace'**
  String get hintNoPace;

  /// Live display: raise the stroke rate to reach the band
  ///
  /// In de, this message translates to:
  /// **'Mehr Schläge'**
  String get hintMoreStrokes;

  /// Live display: lower the stroke rate to reach the band
  ///
  /// In de, this message translates to:
  /// **'Weniger Schläge'**
  String get hintFewerStrokes;

  /// Live display: there is no stroke rate to compare with the band
  ///
  /// In de, this message translates to:
  /// **'Keine Schläge'**
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
  /// **'Ø Pace'**
  String get sessionAveragePace;

  /// Summary: label of the average power
  ///
  /// In de, this message translates to:
  /// **'Ø Watt'**
  String get sessionAverageWatts;

  /// Summary: label of the average stroke rate
  ///
  /// In de, this message translates to:
  /// **'Ø spm'**
  String get sessionAverageStrokeRate;

  /// Summary: label of the number of strokes
  ///
  /// In de, this message translates to:
  /// **'Schläge'**
  String get sessionStrokes;

  /// Summary: label of the tile with the total time of the pauses of a session, with their number (Change auto-pause)
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Pause} other{{count} Pausen}}'**
  String summaryPauses(int count);

  /// Summary: a lap of the course
  ///
  /// In de, this message translates to:
  /// **'Runde {lap}'**
  String sessionLap(int lap);

  /// Summary: title above the totals of a session
  ///
  /// In de, this message translates to:
  /// **'Session beendet'**
  String get summaryTitle;

  /// Summary: label of the average heart rate in beats per minute
  ///
  /// In de, this message translates to:
  /// **'Ø Puls'**
  String get sessionAverageHeartRate;

  /// Summary: label of the lowest heart rate in beats per minute
  ///
  /// In de, this message translates to:
  /// **'Min. Puls'**
  String get sessionMinHeartRate;

  /// Summary: label of the highest heart rate in beats per minute
  ///
  /// In de, this message translates to:
  /// **'Max. Puls'**
  String get sessionMaxHeartRate;

  /// Summary: title above the curve of the intervals from one heart beat to the next, as sent by the heart rate strap
  ///
  /// In de, this message translates to:
  /// **'RR-Intervalle'**
  String get summaryRrIntervals;

  /// Summary: screen reader text of the curve of the RR intervals over the session
  ///
  /// In de, this message translates to:
  /// **'Verlauf der RR-Intervalle zwischen {min} und {max} ms'**
  String summaryRrCurve(int min, int max);

  /// Summary: title above the curve of the pace over the session
  ///
  /// In de, this message translates to:
  /// **'Pace /500 m'**
  String get summaryPace;

  /// Summary: label of the fastest pace of a step of the session
  ///
  /// In de, this message translates to:
  /// **'Schnellste'**
  String get summaryPaceFastest;

  /// Summary: label of the slowest pace of a step of the session
  ///
  /// In de, this message translates to:
  /// **'Langsamste'**
  String get summaryPaceSlowest;

  /// Summary: label of the average pace beside the fastest and slowest one, and of its line in the curve
  ///
  /// In de, this message translates to:
  /// **'Ø'**
  String get summaryPaceAverage;

  /// Summary: screen reader text of the curve of the pace over the session
  ///
  /// In de, this message translates to:
  /// **'Verlauf der Pace zwischen {fastest} und {slowest}, im Durchschnitt {average}'**
  String summaryPaceCurve(String fastest, String slowest, String average);

  /// Summary: heart rate variability of the session as RMSSD in whole milliseconds
  ///
  /// In de, this message translates to:
  /// **'HRV (RMSSD) {ms} ms'**
  String summaryRmssd(int ms);

  /// Summary: heading above the laps, written in capitals
  ///
  /// In de, this message translates to:
  /// **'Runden'**
  String get summaryLaps;

  /// Summary: explains the bar in each lap row
  ///
  /// In de, this message translates to:
  /// **'Balken: Anteil in der Zone pro Runde'**
  String get summaryLapBarHint;

  /// Summary: marks the fastest lap of a distance course or the longest of a time course
  ///
  /// In de, this message translates to:
  /// **'Beste Runde'**
  String get summaryBestLap;

  /// Summary: mark of a lap or the session on place 1 to 3 of its ranking
  ///
  /// In de, this message translates to:
  /// **'Platz {place}'**
  String summaryPlace(int place);

  /// Summary: mark of a run through a zone on place 1 to 3 of the zone's ranking; zone is its name
  ///
  /// In de, this message translates to:
  /// **'{zone} · Platz {place}'**
  String summaryZonePlace(String zone, int place);

  /// Summary: screen reader label of the mark of a session on place 1 to 3 of its template's ranking
  ///
  /// In de, this message translates to:
  /// **'Platz {place} der Vorlage'**
  String summarySessionPlace(int place);

  /// Closes the summary of a session
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get actionDone;

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

  /// Template screen: button that starts rowing the template
  ///
  /// In de, this message translates to:
  /// **'Starten'**
  String get templateStart;

  /// Template screen: switch above Start that turns the ghost on or off for the session started from there
  ///
  /// In de, this message translates to:
  /// **'Gegen den Ghost rudern'**
  String get templateGhost;

  /// Templates: heading above places 1–3 of the template's ranking in the opened template
  ///
  /// In de, this message translates to:
  /// **'Bestleistungen'**
  String get templatePodiumTitle;

  /// Templates: hint in the opened template when it was never rowed completely on a rower
  ///
  /// In de, this message translates to:
  /// **'Noch keine Bestzeit. Es zählen Sessions mit allen Runden an einem Rudergerät.'**
  String get templatePodiumEmpty;

  /// Templates: hint in the opened template with an open number of laps, which has no ranking
  ///
  /// In de, this message translates to:
  /// **'Bei offener Rundenzahl gibt es keine Bestzeit.'**
  String get templatePodiumOpenLaps;

  /// Templates: pace per 500 m of a place, pauses left out
  ///
  /// In de, this message translates to:
  /// **'{pace} /500 m'**
  String templatePodiumPace(String pace);

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

  /// Template editor: label of the course field
  ///
  /// In de, this message translates to:
  /// **'Strecke'**
  String get templateCourse;

  /// Template editor: choice for a fixed number of laps
  ///
  /// In de, this message translates to:
  /// **'Feste Anzahl'**
  String get templateFixedLaps;

  /// Template editor: choice for an open number of laps, rowed until the session ends
  ///
  /// In de, this message translates to:
  /// **'Offen bis Stopp'**
  String get templateOpenLaps;

  /// Template editor: label of the number of laps
  ///
  /// In de, this message translates to:
  /// **'Runden'**
  String get templateLaps;

  /// Template editor: unit after the number of laps, without the number
  ///
  /// In de, this message translates to:
  /// **'{laps, plural, =1{Runde} other{Runden}}'**
  String templateLapsUnit(int laps);

  /// Template editor: label of the line with the total length of all laps
  ///
  /// In de, this message translates to:
  /// **'Ergibt'**
  String get templateResult;

  /// Template editor: after the length of one lap when the number of laps is open
  ///
  /// In de, this message translates to:
  /// **'pro Runde, bis du die Session beendest'**
  String get templateResultOpen;

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

  /// Zone editor: title and switch of the pace band per 500 m
  ///
  /// In de, this message translates to:
  /// **'Pace-Band'**
  String get zonePaceBand;

  /// Zone editor: label of the fastest pace of the band
  ///
  /// In de, this message translates to:
  /// **'Schnellste'**
  String get zonePaceFastest;

  /// Zone editor: label of the slowest pace of the band
  ///
  /// In de, this message translates to:
  /// **'Langsamste'**
  String get zonePaceSlowest;

  /// Zone editor: title and switch of the stroke rate band
  ///
  /// In de, this message translates to:
  /// **'Schlagzahl-Band'**
  String get zoneSpmBand;

  /// Zone editor: label of the lowest stroke rate of the band
  ///
  /// In de, this message translates to:
  /// **'Mindestens'**
  String get zoneSpmFrom;

  /// Zone editor: label of the highest stroke rate of the band
  ///
  /// In de, this message translates to:
  /// **'Höchstens'**
  String get zoneSpmTo;

  /// Zone editor: title and switch of the resistance level that a rower with an adjustable brake is set to in this zone
  ///
  /// In de, this message translates to:
  /// **'Widerstandsstufe'**
  String get zoneResistance;

  /// Zone editor: label of the resistance level
  ///
  /// In de, this message translates to:
  /// **'Stufe'**
  String get zoneResistanceLevel;

  /// Zone list, course and template: resistance level of a zone after its bands
  ///
  /// In de, this message translates to:
  /// **'Stufe {level}'**
  String zoneResistanceLevelShort(int level);

  /// Zone editor: what the resistance level does
  ///
  /// In de, this message translates to:
  /// **'Bei FTMS-Rudergeräten mit verstellbarem Widerstand setzt die App diese Stufe, sobald die Zone beginnt.'**
  String get zoneResistanceHint;

  /// Oar stepper: size of a step in resistance levels, for screen readers
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Stufe} other{{count} Stufen}}'**
  String stepLevels(int count);

  /// Zone editor: what a zone needs
  ///
  /// In de, this message translates to:
  /// **'Mindestens ein Band ist nötig, Pace, Schlagzahl oder beides.'**
  String get zoneBandHint;

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

  /// Label of the axis of a course: distance or time
  ///
  /// In de, this message translates to:
  /// **'Achse'**
  String get fieldAxis;

  /// Label above the length of a course, written in capitals
  ///
  /// In de, this message translates to:
  /// **'Länge'**
  String get fieldLengthPlain;

  /// Course list: the zones placed in a course; name is the zone when there is only one
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{ohne Zonen} =1{Zone {name}} other{{count} Zonen}}'**
  String courseZonesSummary(int count, String name);

  /// Course list: how often a course was rowed in sessions
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{noch nie gerudert} other{{count}× gerudert}}'**
  String courseRowedCount(int count);

  /// Course list: legend saying that brighter zones in the bar have a faster pace band
  ///
  /// In de, this message translates to:
  /// **'Helligkeit = Tempo'**
  String get courseLegendShade;

  /// Course and zone details: label above places 1–3 of one length, e.g. 'Bestenliste 1000 m'
  ///
  /// In de, this message translates to:
  /// **'Bestenliste {length}'**
  String rankingLength(String length);

  /// Course and zone details: label above places 1–3 of the length the course or zone has today
  ///
  /// In de, this message translates to:
  /// **'Bestenliste {length} · aktuell'**
  String rankingLengthCurrent(String length);

  /// Rankings: screen reader label of a place, e.g. 'Platz 1'
  ///
  /// In de, this message translates to:
  /// **'Platz {place}'**
  String rankingPlace(int place);

  /// Rankings: pace per 500 metres of an entry, pauses left out
  ///
  /// In de, this message translates to:
  /// **'{pace} /500 m'**
  String rankingPace(String pace);

  /// Course and zone details: hint below the rankings that times and paces leave out pauses, except in sessions recorded before the automatic pause (Change auto-pause)
  ///
  /// In de, this message translates to:
  /// **'Pausen zählen nicht, auch nicht in der Pace. Ausnahme: ältere Sessions ohne automatische Pause.'**
  String get rankingPausesHint;

  /// Course and zone details: shown instead of places when nothing was rowed yet
  ///
  /// In de, this message translates to:
  /// **'Noch keine Bestzeit. Es zählen nur vollständige Runden am Rudergerät, nicht im Simulator.'**
  String get rankingEmpty;

  /// Course and zone details: the rankings could not be computed
  ///
  /// In de, this message translates to:
  /// **'Bestenliste konnte nicht geladen werden: {error}'**
  String rankingLoadFailed(String error);

  /// Course editor: where a placed zone starts, e.g. 'ab 500 m'
  ///
  /// In de, this message translates to:
  /// **'ab {start}'**
  String courseZoneFrom(String start);

  /// Course editor: hint that changing a course already rowed in its newest version stores a new version
  ///
  /// In de, this message translates to:
  /// **'{count}× gerudert. Änderst du Länge oder Zonen, entsteht eine neue Version. Alte Rundenzeiten bleiben vergleichbar.'**
  String courseVersionHint(int count);

  /// Screen reader label of the ghost symbol (a small violet rhombus) in the pace box legend and the template choice; the ghost is the best result rowed again for comparison
  ///
  /// In de, this message translates to:
  /// **'Ghost'**
  String get ghostSymbolLabel;

  /// Title of a session without a template as a workout in Health Connect (and Google Fit)
  ///
  /// In de, this message translates to:
  /// **'Freies Rudern'**
  String get healthFreeTitle;

  /// Tooltip of the app bar button on the sessions screen that opens the Health Connect settings (Android only); Health Connect is the product name of the Android health data store
  ///
  /// In de, this message translates to:
  /// **'Health Connect'**
  String get healthConnectTooltip;

  /// Explanation at the top of the Health Connect sheet
  ///
  /// In de, this message translates to:
  /// **'Überträgt Sessions vom Rudergerät nach dem Rudern an Health Connect. Von dort lesen Apps wie Google Fit sie.'**
  String get healthConnectIntro;

  /// Switch in the Health Connect sheet that turns sending finished sessions on or off
  ///
  /// In de, this message translates to:
  /// **'An Health Connect übertragen'**
  String get healthConnectSwitch;

  /// Status in the Health Connect sheet while sending is on and allowed
  ///
  /// In de, this message translates to:
  /// **'Sessions werden nach dem Rudern übertragen.'**
  String get healthConnectActive;

  /// Status in the Health Connect sheet when the device has no Health Connect
  ///
  /// In de, this message translates to:
  /// **'Health Connect ist auf diesem Gerät nicht installiert.'**
  String get healthConnectMissing;

  /// Button in the Health Connect sheet that opens the store page of Health Connect
  ///
  /// In de, this message translates to:
  /// **'Installieren'**
  String get healthConnectInstall;

  /// Status in the Health Connect sheet when the installed Health Connect is too old
  ///
  /// In de, this message translates to:
  /// **'Health Connect muss aktualisiert werden.'**
  String get healthConnectOutdated;

  /// Button in the Health Connect sheet that opens the store page to update Health Connect
  ///
  /// In de, this message translates to:
  /// **'Aktualisieren'**
  String get healthConnectUpdate;

  /// Status in the Health Connect sheet when the user refused or later withdrew the permission to write workouts
  ///
  /// In de, this message translates to:
  /// **'Ohne die Berechtigung für Trainingseinheiten kann Stroke & Split nichts an Health Connect übertragen.'**
  String get healthConnectPermissionMissing;

  /// Button that asks Android again for the Health Connect write permissions
  ///
  /// In de, this message translates to:
  /// **'Berechtigung erteilen'**
  String get healthConnectGrant;

  /// Entry in the Health Connect sheet that opens Health Connect itself
  ///
  /// In de, this message translates to:
  /// **'Health Connect öffnen'**
  String get healthConnectOpen;

  /// Subtitle of the entry that opens Health Connect
  ///
  /// In de, this message translates to:
  /// **'Berechtigungen und übertragene Daten verwalten'**
  String get healthConnectOpenHint;

  /// Title of the page about what the app writes to Health Connect, and the link to it in the Health Connect sheet
  ///
  /// In de, this message translates to:
  /// **'Datenschutz-Hinweis'**
  String get healthPrivacyTitle;

  /// Privacy notice, paragraph 1: what is written to Health Connect
  ///
  /// In de, this message translates to:
  /// **'Wenn du die Übertragung einschaltest oder eine Session selbst sendest, schreibt Stroke & Split Sessions von deinem Rudergerät an Health Connect: Beginn und Ende, Titel, Distanz, Kalorien, Puls, Leistung, Geschwindigkeit, Runden und Pausen.'**
  String get healthPrivacyWhat;

  /// Privacy notice, paragraph 2: what is not written
  ///
  /// In de, this message translates to:
  /// **'Schlagzahl, Kraftkurve und Rohdaten bleiben in der App.'**
  String get healthPrivacyKept;

  /// Privacy notice, paragraph 3
  ///
  /// In de, this message translates to:
  /// **'Stroke & Split liest keine Daten aus Health Connect.'**
  String get healthPrivacyNoRead;

  /// Privacy notice, paragraph 4
  ///
  /// In de, this message translates to:
  /// **'Über Stroke & Split verlassen deine Daten das Gerät nicht. Welche anderen Apps sie in Health Connect lesen dürfen, legst du in Health Connect fest.'**
  String get healthPrivacyDevice;

  /// Privacy notice, paragraph 5
  ///
  /// In de, this message translates to:
  /// **'Du kannst die Übertragung jederzeit ausschalten. Übertragene Einheiten löschst du in Health Connect.'**
  String get healthPrivacyStop;

  /// Menu entry in the session list and button in the summary that sends one session to Health Connect
  ///
  /// In de, this message translates to:
  /// **'An Health Connect senden'**
  String get healthSend;

  /// Message after a session was sent to Health Connect
  ///
  /// In de, this message translates to:
  /// **'An Health Connect übertragen.'**
  String get healthSent;

  /// Status in the summary of a session that is in Health Connect; date is date and time of the last successful send
  ///
  /// In de, this message translates to:
  /// **'An Health Connect übertragen am {date}'**
  String healthSentAt(String date);

  /// Status in the summary of a session that is not in Health Connect
  ///
  /// In de, this message translates to:
  /// **'Nicht an Health Connect übertragen'**
  String get healthNotSent;

  /// Message when sending a session failed because the permission is missing; offered with a button to grant it
  ///
  /// In de, this message translates to:
  /// **'Stroke & Split darf nicht an Health Connect schreiben.'**
  String get healthFailedPermission;

  /// Message when sending a session failed because Health Connect is missing or too old
  ///
  /// In de, this message translates to:
  /// **'Health Connect ist nicht verfügbar.'**
  String get healthFailedUnavailable;

  /// Message when Health Connect refused a session for another reason
  ///
  /// In de, this message translates to:
  /// **'Übertragung an Health Connect fehlgeschlagen.'**
  String get healthFailed;

  /// Short button in the message about a missing Health Connect permission that asks for it again; must stay short to fit next to the message
  ///
  /// In de, this message translates to:
  /// **'Erteilen'**
  String get healthGrantShort;

  /// Course detail: button that opens the start screen to row the course without a template
  ///
  /// In de, this message translates to:
  /// **'Rudern'**
  String get courseRow;

  /// Course start screen: option to row a number of laps
  ///
  /// In de, this message translates to:
  /// **'Runden'**
  String get courseStartLaps;

  /// Course start screen: option to row for a total rowing time; also the name of its input for screen readers
  ///
  /// In de, this message translates to:
  /// **'Dauer'**
  String get courseStartDuration;

  /// Course start screen: option to row until the user ends the session
  ///
  /// In de, this message translates to:
  /// **'Offen'**
  String get courseStartOpen;

  /// Course start screen: hint shown instead of an input when the open option is chosen
  ///
  /// In de, this message translates to:
  /// **'Du ruderst, bis du die Session beendest.'**
  String get courseStartOpenHint;

  /// Course start screen: button that starts rowing the course
  ///
  /// In de, this message translates to:
  /// **'Starten'**
  String get courseStartStart;

  /// Step of a stepper in minutes for screen readers, as in '1 Minute mehr'
  ///
  /// In de, this message translates to:
  /// **'{minutes, plural, =1{1 Minute} other{{minutes} Minuten}}'**
  String stepMinutes(int minutes);

  /// Planned total rowing time of a session without a template, after the course name, e.g. 'Seerunde · 30 min'
  ///
  /// In de, this message translates to:
  /// **'{minutes} min'**
  String planMinutes(int minutes);

  /// Planned length of a session without a template that runs until the rower ends it, after the course name, e.g. 'Seerunde · offen'
  ///
  /// In de, this message translates to:
  /// **'offen'**
  String get planOpen;
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
