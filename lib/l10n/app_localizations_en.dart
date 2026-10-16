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
  String get startSimulatorHint =>
      'Try it without an erg, with a simulated rower';

  @override
  String get startSessions => 'Sessions';

  @override
  String get languageChoice => 'Language';

  @override
  String get startTagline => 'Row against yourself';

  @override
  String get startRow => 'Row';

  @override
  String get startRowFree => 'Just row';

  @override
  String get startNoRower => 'No rower chosen';

  @override
  String get startConnectsLater => 'Connects when you start rowing';

  @override
  String get startSimulatorFtmsHint =>
      'Like an FTMS rower, without stroke details';

  @override
  String get devicesTitle => 'Choose devices';

  @override
  String get devicesRower => 'Rower';

  @override
  String get devicesNext => 'Continue';

  @override
  String get devicesNotFound => 'not found';

  @override
  String get devicesHeartRateMonitor => 'Heart rate strap';

  @override
  String get devicesNoStrap => 'No strap';

  @override
  String get devicesNoStrapHint =>
      'Optional, for heart rate and RR intervals straight from the strap';

  @override
  String get devicesStrapPaired => 'Paired';

  @override
  String get devicesStrapPair => 'Pair strap';

  @override
  String get devicesStrapChange => 'Change strap';

  @override
  String get devicesStrapForget => 'Forget';

  @override
  String get strapSearchTitle => 'Find heart rate strap';

  @override
  String get strapSearchNothingFound =>
      'No strap found.\n\n• Moisten the electrodes and put the strap on, only then does it transmit.\n• Disconnect the strap from other apps or watches, many straps allow only a few connections at a time.\n• Move closer to the strap.';

  @override
  String strapSearchFailed(String detail) {
    return 'Searching for heart rate straps failed.\n\n$detail';
  }

  @override
  String get strapBluetoothOff =>
      'Bluetooth is switched off. Switch Bluetooth on to search for your heart rate strap.';

  @override
  String launchSearching(String device) {
    return 'Looking for $device …';
  }

  @override
  String get startAgain => 'Again';

  @override
  String startAgainDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: 'yesterday',
      zero: 'today',
    );
    return '$_temp0';
  }

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

  @override
  String get stateConnected => 'Connected';

  @override
  String get stateConnecting => 'Connecting …';

  @override
  String get stateScanning => 'Searching …';

  @override
  String get stateReconnecting => 'Connection lost, reconnecting …';

  @override
  String get stateDisconnected => 'Disconnected';

  @override
  String get sourceSimulator => 'SIMULATOR';

  @override
  String get sourceSimulatorFtms => 'SIMULATOR (FTMS)';

  @override
  String get sourceReplay => 'REPLAY';

  @override
  String deviceListScanFailed(String detail) {
    return 'Searching for rowers failed.\n\n$detail';
  }

  @override
  String get deviceListRetry => 'Search again';

  @override
  String get deviceListNothingFound =>
      'No rower found.\n\n• Wake the rower up, on the PM5 with any button until the main menu appears.\n• Disconnect other apps such as ErgData, many rowers allow only one connection.\n• Move closer to the rower.';

  @override
  String get bluetoothOff =>
      'Bluetooth is off. Turn Bluetooth on to search for your rower.';

  @override
  String bluetoothUnauthorized(String app) {
    return '$app may not use Bluetooth. The permission is needed to connect to your rower. Grant it in the system settings under Apps → $app → Permissions.';
  }

  @override
  String get bluetoothUnsupported =>
      'This device does not support Bluetooth LE.';

  @override
  String get liveDisconnect => 'Disconnect';

  @override
  String get liveStale => 'No data for 3 seconds, the values are out of date.';

  @override
  String get liveStartSession => 'Start session';

  @override
  String get liveStopSession => 'End session';

  @override
  String get metricTime => 'Time';

  @override
  String get metricDistance => 'Distance';

  @override
  String get metricWatts => 'Watts';

  @override
  String get metricStrokeRate => 'Stroke rate';

  @override
  String get metricHeartRate => 'Heart rate';

  @override
  String get metricPace => 'Pace /500 m';

  @override
  String get metricCalories => 'Calories';

  @override
  String get metricAveragePace => 'Ø pace';

  @override
  String get metricLapTime => 'Lap';

  @override
  String get metricInZone => 'In zone';

  @override
  String get liveStopShort => 'End';

  @override
  String get liveForceCurve => 'Force curve';

  @override
  String courseLap(int lap) {
    return 'Lap $lap';
  }

  @override
  String get segmentFree => 'free';

  @override
  String get segmentZone => 'Zone';

  @override
  String courseRest(String rest) {
    return '$rest to go';
  }

  @override
  String courseInZoneShare(int percent) {
    return 'Zone $percent %';
  }

  @override
  String get paceBoxTotal => 'Total';

  @override
  String paceBoxLapOf(int lap, int laps) {
    return 'Lap $lap / $laps';
  }

  @override
  String get paceBoxGhost => 'Ghost';

  @override
  String paceBoxGhostAhead(String amount) {
    return '$amount ahead of you';
  }

  @override
  String paceBoxGhostBehind(String amount) {
    return '$amount behind you';
  }

  @override
  String get paceBoxGhostLevel => 'level';

  @override
  String get hintInZone => 'In the zone';

  @override
  String get hintFaster => 'Faster';

  @override
  String get hintSlower => 'Slower';

  @override
  String get hintNoPace => 'No pace';

  @override
  String get hintMoreStrokes => 'More strokes';

  @override
  String get hintFewerStrokes => 'Fewer strokes';

  @override
  String get hintNoStrokes => 'No strokes';

  @override
  String get simTargetPace => 'Target pace';

  @override
  String get simTargetStrokeRate => 'Target SPM';

  @override
  String get simFaster => 'Faster';

  @override
  String get simSlower => 'Slower';

  @override
  String get simMoreStrokes => 'More strokes';

  @override
  String get simFewerStrokes => 'Fewer strokes';

  @override
  String get simPause => 'Pause';

  @override
  String get simResume => 'Resume';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionSave => 'Save';

  @override
  String get actionReplay => 'Play back';

  @override
  String get actionExport => 'Export';

  @override
  String get actionImport => 'Import';

  @override
  String get actionMore => 'Actions';

  @override
  String get sessionsTitle => 'Sessions';

  @override
  String get sessionsEmpty => 'No sessions recorded yet.';

  @override
  String sessionsLoadFailed(String error) {
    return 'Sessions could not be loaded: $error';
  }

  @override
  String get sessionIncomplete => 'incomplete';

  @override
  String get sessionTitle => 'Session';

  @override
  String get sessionGone => 'This session no longer exists.';

  @override
  String sessionLoadFailed(String error) {
    return 'The session could not be loaded: $error';
  }

  @override
  String get sessionIncompleteNote =>
      'Incomplete: the app was closed during the session. Everything up to shortly before is saved.';

  @override
  String get sessionDistance => 'Distance';

  @override
  String get sessionTime => 'Time';

  @override
  String get sessionAveragePace => 'Ø Pace';

  @override
  String get sessionAverageWatts => 'Ø Watts';

  @override
  String get sessionAverageStrokeRate => 'Ø spm';

  @override
  String get sessionStrokes => 'Strokes';

  @override
  String sessionLap(int lap) {
    return 'Lap $lap';
  }

  @override
  String get summaryTitle => 'Session finished';

  @override
  String get summaryLaps => 'Laps';

  @override
  String get summaryLapBarHint => 'Bar: share in the zone per lap';

  @override
  String get summaryBestLap => 'Best lap';

  @override
  String summaryPlace(int place) {
    return 'Place $place';
  }

  @override
  String summaryZonePlace(String zone, int place) {
    return '$zone · place $place';
  }

  @override
  String summarySessionPlace(int place) {
    return 'Place $place for the template';
  }

  @override
  String get actionDone => 'Done';

  @override
  String get sourceRower => 'Rower';

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
  String get replayNoData => 'This session has no raw data to play back.';

  @override
  String get sessionDeleteTitle => 'Delete session?';

  @override
  String sessionDeleteBody(String date) {
    return 'The session of $date is deleted for good with its history and raw data.';
  }

  @override
  String get sessionExported => 'Session exported.';

  @override
  String sessionExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get sessionImported => 'Session imported.';

  @override
  String sessionImportFailed(String app, String error) {
    return 'The file is not a readable $app session: $error';
  }

  @override
  String get actionEdit => 'Edit';

  @override
  String get fieldName => 'Name';

  @override
  String lapsCount(int laps) {
    String _temp0 = intl.Intl.pluralLogic(
      laps,
      locale: localeName,
      other: '$laps laps',
      one: '1 lap',
    );
    return '$_temp0';
  }

  @override
  String get lapsOpen => 'open';

  @override
  String get templatesTitle => 'Row a template';

  @override
  String get tabTemplates => 'Templates';

  @override
  String get tabCourses => 'Courses';

  @override
  String get tabZones => 'Zones';

  @override
  String get templateCreate => 'New template';

  @override
  String get templateStart => 'Start';

  @override
  String get templatePodiumTitle => 'Best results';

  @override
  String get templatePodiumEmpty =>
      'No best time yet. Sessions with all laps on a rower count.';

  @override
  String get templatePodiumOpenLaps =>
      'An open number of laps has no best time.';

  @override
  String templatePodiumPace(String pace) {
    return '$pace /500 m';
  }

  @override
  String get templatesEmpty => 'No templates yet.';

  @override
  String templatesLoadFailed(String error) {
    return 'Templates could not be loaded: $error';
  }

  @override
  String get templateNeedsCourseTitle => 'Create a course first';

  @override
  String get templateNeedsCourseBody =>
      'A template rows a course. Create a course first.';

  @override
  String get templateNeedsCourse => 'For a template you need a course first.';

  @override
  String get courseCreate => 'New course';

  @override
  String get templateDeleteTitle => 'Delete template?';

  @override
  String templateDeleteBody(String name) {
    return '“$name” is deleted. Sessions rowed with it are kept.';
  }

  @override
  String get templateNew => 'New template';

  @override
  String get templateEdit => 'Edit template';

  @override
  String get templateNameMissing => 'The name is missing.';

  @override
  String get templateCourseMissing => 'Choose a course.';

  @override
  String get templateCourse => 'Course';

  @override
  String get templateFixedLaps => 'Fixed number';

  @override
  String get templateOpenLaps => 'Open until stop';

  @override
  String get templateLaps => 'Laps';

  @override
  String templateLapsUnit(int laps) {
    String _temp0 = intl.Intl.pluralLogic(
      laps,
      locale: localeName,
      other: 'laps',
      one: 'lap',
    );
    return '$_temp0';
  }

  @override
  String get templateResult => 'Total';

  @override
  String get templateResultOpen => 'per lap, until you end the session';

  @override
  String get coursesTitle => 'Courses';

  @override
  String get coursesEmpty => 'No courses yet.';

  @override
  String coursesLoadFailed(String error) {
    return 'Courses could not be loaded: $error';
  }

  @override
  String get courseDeleteTitle => 'Delete course?';

  @override
  String courseDeleteBody(String name) {
    return '“$name” disappears from the list. Sessions already rowed keep their laps.';
  }

  @override
  String courseDeleteTemplates(String templates) {
    return 'These templates use the course and are deleted with it: $templates.';
  }

  @override
  String get courseNew => 'New course';

  @override
  String get courseEdit => 'Edit course';

  @override
  String get courseNameMissing => 'The name is missing.';

  @override
  String get courseSequence => 'Sequence';

  @override
  String get coursePlaceZone => 'Place zone';

  @override
  String get courseMoveZone => 'Move zone';

  @override
  String get coursePlaceHere => 'Place a zone here';

  @override
  String get courseRemoveZone => 'Remove zone';

  @override
  String get coursePlace => 'Place';

  @override
  String get courseMove => 'Move';

  @override
  String get courseNoZones => 'No zones yet. Create one first.';

  @override
  String get zoneCreate => 'New zone';

  @override
  String courseStart(String unit) {
    return 'Start ($unit)';
  }

  @override
  String courseRange(String range) {
    return 'Course: $range';
  }

  @override
  String coursePlacedAt(String zone, String range) {
    return '“$zone” lies at $range.';
  }

  @override
  String get courseOtherAxis => 'other axis';

  @override
  String get axisDistance => 'Distance';

  @override
  String get axisTime => 'Time';

  @override
  String fieldLength(String unit) {
    return 'Length ($unit)';
  }

  @override
  String get zonesTitle => 'Zones';

  @override
  String get zoneCreateShort => 'New zone';

  @override
  String get zonesEmpty =>
      'No zones yet. A zone is a pace or stroke rate band over a fixed length that you place in courses.';

  @override
  String zonesLoadFailed(String error) {
    return 'Zones could not be loaded: $error';
  }

  @override
  String zoneUsage(int courses) {
    String _temp0 = intl.Intl.pluralLogic(
      courses,
      locale: localeName,
      other: 'in $courses courses',
      one: 'in 1 course',
      zero: 'not used',
    );
    return '$_temp0';
  }

  @override
  String get zoneNew => 'New zone';

  @override
  String get zoneEdit => 'Edit zone';

  @override
  String get zoneDeleteTitle => 'Delete zone?';

  @override
  String zoneDeleteBody(String name) {
    return '“$name” disappears from the list. Sessions already rowed keep the name of the zone.';
  }

  @override
  String zoneDeleteCourses(String courses) {
    return 'Its place becomes free in these courses: $courses.';
  }

  @override
  String zoneInCourses(String courses) {
    return 'Placed in $courses';
  }

  @override
  String get zoneInCoursesHint =>
      'Changes apply in all these courses. A course already rowed gets a new version, old sessions stay as they were.';

  @override
  String get zoneNameHint => 'e.g. Sprint';

  @override
  String get zonePaceBand => 'Pace band';

  @override
  String get zonePaceFastest => 'Fastest';

  @override
  String get zonePaceSlowest => 'Slowest';

  @override
  String get zoneSpmBand => 'Stroke rate band';

  @override
  String get zoneSpmFrom => 'At least';

  @override
  String get zoneSpmTo => 'At most';

  @override
  String get zoneBandHint =>
      'At least one band is needed: pace, stroke rate or both.';

  @override
  String get dateTimePattern => 'MMM d, y, HH:mm';

  @override
  String get actionOk => 'OK';

  @override
  String oarStepperMore(String step) {
    return '$step more';
  }

  @override
  String oarStepperLess(String step) {
    return '$step less';
  }

  @override
  String stepSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String stepStrokes(int strokes) {
    String _temp0 = intl.Intl.pluralLogic(
      strokes,
      locale: localeName,
      other: '$strokes strokes',
      one: '1 stroke',
    );
    return '$_temp0';
  }

  @override
  String get fieldAxis => 'Axis';

  @override
  String get fieldLengthPlain => 'Length';

  @override
  String courseZonesSummary(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zones',
      one: 'zone $name',
      zero: 'no zones',
    );
    return '$_temp0';
  }

  @override
  String courseRowedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'rowed $count×',
      one: 'rowed once',
      zero: 'never rowed',
    );
    return '$_temp0';
  }

  @override
  String get courseLegendShade => 'Brighter = faster';

  @override
  String rankingLength(String length) {
    return 'Best results $length';
  }

  @override
  String rankingLengthCurrent(String length) {
    return 'Best results $length · current';
  }

  @override
  String rankingPlace(int place) {
    return 'Place $place';
  }

  @override
  String rankingPace(String pace) {
    return '$pace /500 m';
  }

  @override
  String get rankingPausesHint =>
      'Measured by the wall clock: pauses count, also in the pace.';

  @override
  String get rankingEmpty =>
      'No best time yet. Only complete laps on an erg count, not in the simulator.';

  @override
  String rankingLoadFailed(String error) {
    return 'Could not load the best results: $error';
  }

  @override
  String courseZoneFrom(String start) {
    return 'from $start';
  }

  @override
  String courseVersionHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rowed $count×.',
      one: 'Rowed once.',
    );
    return '$_temp0 Changing the length or zones creates a new version. Earlier lap times stay comparable.';
  }

  @override
  String get ghostSymbolLabel => 'Ghost';
}
