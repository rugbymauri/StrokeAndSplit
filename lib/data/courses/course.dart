import 'package:flutter/foundation.dart' show immutable, listEquals;

import '../db/database.dart';

export '../db/database.dart' show CourseAxis;

/// A part of a course: a placed zone with a copy of its bands, or a free gap.
@immutable
class CourseSegment {
  const CourseSegment({
    required this.length,
    this.paceFastCs,
    this.paceSlowCs,
    this.spmMin,
    this.spmMax,
    this.resistanceLevel,
    this.zoneId,
    this.zoneName,
  });

  /// In the unit of the course: metres or seconds.
  final int length;

  /// Fastest and slowest pace per 500 m, in centiseconds.
  final int? paceFastCs;
  final int? paceSlowCs;
  final int? spmMin;
  final int? spmMax;

  /// Resistance level of the placed zone; null rows on the base level
  /// (Change resistance-control). It makes a zone without a band, so a
  /// segment with only a level is not free but has nothing to measure
  /// (Change zone-level-only, Design D1).
  final int? resistanceLevel;

  /// The placed zone; null for a free gap and in rowed versions from before
  /// zones, which only keep [zoneName].
  final int? zoneId;

  /// The name of the zone when the version was stored.
  final String? zoneName;

  bool get hasPaceBand => paceFastCs != null && paceSlowCs != null;
  bool get hasSpmBand => spmMin != null && spmMax != null;

  /// Whether the segment has a band to measure the rowing against.
  bool get hasBand => hasPaceBand || hasSpmBand;

  /// A segment without any band and without a level is rowed freely.
  bool get isFree => !hasBand && resistanceLevel == null;

  CourseSegment withLength(int length) => CourseSegment(
    length: length,
    paceFastCs: paceFastCs,
    paceSlowCs: paceSlowCs,
    spmMin: spmMin,
    spmMax: spmMax,
    resistanceLevel: resistanceLevel,
    zoneId: zoneId,
    zoneName: zoneName,
  );

  /// Whether both row the same, whichever zone they were placed from.
  bool sameAs(CourseSegment other) =>
      other.length == length &&
      other.paceFastCs == paceFastCs &&
      other.paceSlowCs == paceSlowCs &&
      other.spmMin == spmMin &&
      other.spmMax == spmMax &&
      other.resistanceLevel == resistanceLevel &&
      other.zoneName == zoneName;

  @override
  bool operator ==(Object other) =>
      other is CourseSegment && other.zoneId == zoneId && sameAs(other);

  @override
  int get hashCode => Object.hash(
    length,
    paceFastCs,
    paceSlowCs,
    spmMin,
    spmMax,
    resistanceLevel,
    zoneId,
    zoneName,
  );

  @override
  String toString() =>
      'CourseSegment($length, pace $paceFastCs–$paceSlowCs, spm $spmMin–$spmMax, level $resistanceLevel, zone $zoneId $zoneName)';
}

/// What a course asks for: its axis, its length and its segments.
@immutable
class CourseDefinition {
  const CourseDefinition({
    required this.axis,
    required this.length,
    required this.segments,
  });

  /// A new course starts with a single segment over its whole length.
  CourseDefinition.single({required CourseAxis axis, required int length})
    : this(
        axis: axis,
        length: length,
        segments: [CourseSegment(length: length)],
      );

  final CourseAxis axis;

  /// In metres or seconds, depending on [axis].
  final int length;
  final List<CourseSegment> segments;

  /// Where each segment ends, from the start of the course.
  List<int> get segmentEnds {
    var end = 0;
    return [for (final s in segments) end += s.length];
  }

  /// Where each segment starts, from the start of the course.
  List<int> get segmentStarts {
    var start = 0;
    return [for (final s in segments) (start += s.length) - s.length];
  }

  /// Whether both row the same, whichever zones they were placed from.
  bool sameAs(CourseDefinition other) =>
      other.axis == axis &&
      other.length == length &&
      other.segments.length == segments.length &&
      [for (final (i, s) in segments.indexed) s.sameAs(other.segments[i])]
          .every((same) => same);

  @override
  bool operator ==(Object other) =>
      other is CourseDefinition &&
      other.axis == axis &&
      other.length == length &&
      listEquals(other.segments, segments);

  @override
  int get hashCode => Object.hash(axis, length, Object.hashAll(segments));
}

/// A stored course in its newest version.
@immutable
class Course {
  const Course({
    required this.id,
    required this.name,
    required this.versionId,
    required this.version,
    required this.definition,
  });

  final int id;
  final String name;
  final int versionId;
  final int version;
  final CourseDefinition definition;

  CourseAxis get axis => definition.axis;
}

/// A course length as entered: `1000 m` or `4:00`.
String formatCourseLength(CourseAxis axis, int length) => switch (axis) {
  CourseAxis.distance => '$length m',
  CourseAxis.time =>
    '${length ~/ 60}:${(length % 60).toString().padLeft(2, '0')}',
};

/// A range on a course: `500–600 m` or `1:00–2:00`.
String formatCourseRange(CourseAxis axis, int start, int end) => switch (axis) {
  CourseAxis.distance => '$start–$end m',
  CourseAxis.time =>
    '${formatCourseLength(axis, start)}–${formatCourseLength(axis, end)}',
};
