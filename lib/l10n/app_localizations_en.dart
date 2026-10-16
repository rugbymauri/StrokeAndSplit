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

  @override
  String get zoneErrorNameMissing => 'The name is missing.';

  @override
  String get zoneErrorLengthMissing => 'The length is missing.';

  @override
  String get zoneErrorBandMissing =>
      'A band is missing: pace, stroke rate or both.';

  @override
  String get zoneErrorPaceBoundMissing => 'The pace band is missing a bound.';

  @override
  String get zoneErrorPaceReversed =>
      'The fastest pace is slower than the slowest.';

  @override
  String get zoneErrorSpmBoundMissing =>
      'The stroke rate band is missing a bound.';

  @override
  String get zoneErrorSpmReversed =>
      'The lowest stroke rate is above the highest.';

  @override
  String quotedName(String name) {
    return '“$name”';
  }

  @override
  String get placementLengthMissing => 'The length is missing.';

  @override
  String get placementZoneMissing => 'A placed zone no longer exists.';

  @override
  String placementAxisMismatch(
    String zone,
    String zoneAxis,
    String courseAxis,
  ) {
    String _temp0 = intl.Intl.selectLogic(zoneAxis, {
      'distance': 'distance',
      'other': 'time',
    });
    String _temp1 = intl.Intl.selectLogic(courseAxis, {
      'distance': 'distance',
      'other': 'time',
    });
    return '“$zone” is measured in $_temp0, the course in $_temp1.';
  }

  @override
  String placementBeforeStart(String zone) {
    return '“$zone” begins before the start of the course.';
  }

  @override
  String placementBeyondEnd(String zone, String range, String length) {
    return '“$zone” ($range) extends past the end of the course at $length.';
  }

  @override
  String placementOverlap(
    String zone,
    String range,
    String other,
    String otherRange,
  ) {
    return '“$zone” ($range) overlaps “$other” ($otherRange).';
  }

  @override
  String zoneConflict(String courses) {
    return 'The change does not fit $courses: there the zone would extend past the end of the course or overlap another zone.';
  }

  @override
  String get connectFailedTitle => 'Connection failed';

  @override
  String connectFailedBody(String app, String device) {
    return '$app could not connect to $device.\n\nMany rowers allow only one Bluetooth connection at a time. Disconnect other apps such as ErgData and try again.';
  }

  @override
  String get connectNotARowerTitle => 'Not a rower';

  @override
  String connectNotARowerHint(String app) {
    return '$app supports the PM5 on a RowErg and rowers with FTMS.';
  }

  @override
  String get connectErrorSkiErg =>
      'Only rowers are supported. This PM5 belongs to a SkiErg.';

  @override
  String get connectErrorBikeErg =>
      'Only rowers are supported. This PM5 belongs to a BikeErg.';

  @override
  String get connectErrorNoRowerData =>
      'Only rowers are supported. The device sends no rowing data.';
}
