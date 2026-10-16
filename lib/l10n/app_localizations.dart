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
