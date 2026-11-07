import 'course.dart';

/// How hard a zone is, from its pace band, stroke-rate band and resistance
/// level (change `zone-intensity-colors`).
enum ZoneIntensity { easy, medium, hard }

/// The middle of a pace band from this on (3:00 /500 m) is easy.
const easyPaceFromCs = 18000;

/// The middle of a pace band from this on (2:30 /500 m) is at least medium.
const mediumPaceFromCs = 15000;

/// The middle of a stroke-rate band up to this is easy.
const easySpmUpTo = 21;

/// The middle of a stroke-rate band from this on is hard.
const hardSpmFrom = 24;

/// A resistance level up to this is easy.
const easyLevelUpTo = 5;

/// A resistance level up to this is at least medium.
const mediumLevelUpTo = 10;

/// The intensity of [segment]: the hardest of its targets, or `null` for a
/// free segment. A band counts with its middle.
ZoneIntensity? zoneIntensity(CourseSegment segment) {
  if (segment.isFree) return null;
  final intensities = [
    if (segment.hasPaceBand)
      _pace((segment.paceFastCs! + segment.paceSlowCs!) / 2),
    if (segment.hasSpmBand) _spm((segment.spmMin! + segment.spmMax!) / 2),
    if (segment.resistanceLevel case final level?) _level(level),
  ];
  return intensities.reduce((a, b) => a.index >= b.index ? a : b);
}

ZoneIntensity _pace(double middleCs) => middleCs >= easyPaceFromCs
    ? ZoneIntensity.easy
    : middleCs >= mediumPaceFromCs
    ? ZoneIntensity.medium
    : ZoneIntensity.hard;

ZoneIntensity _spm(double middle) => middle <= easySpmUpTo
    ? ZoneIntensity.easy
    : middle < hardSpmFrom
    ? ZoneIntensity.medium
    : ZoneIntensity.hard;

ZoneIntensity _level(int level) => level <= easyLevelUpTo
    ? ZoneIntensity.easy
    : level <= mediumLevelUpTo
    ? ZoneIntensity.medium
    : ZoneIntensity.hard;
