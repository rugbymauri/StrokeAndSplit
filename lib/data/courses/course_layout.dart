import 'package:flutter/foundation.dart' show immutable;

import '../zones/zone.dart';
import 'course.dart';

/// A zone placed in a course from [start] on, in the unit of the course.
@immutable
class ZonePlacement {
  const ZonePlacement({required this.zoneId, required this.start});

  final int zoneId;
  final int start;

  @override
  bool operator ==(Object other) =>
      other is ZonePlacement && other.zoneId == zoneId && other.start == start;

  @override
  int get hashCode => Object.hash(zoneId, start);

  @override
  String toString() => 'ZonePlacement($zoneId at $start)';
}

/// What keeps a course from being laid out (Design D4 of translations).
enum PlacementErrorKind {
  lengthMissing,
  zoneMissing,
  axisMismatch,
  beforeStart,
  beyondEnd,
  overlap,
}

/// Why a course cannot be laid out; the screens put it into words. Ranges and
/// lengths come formatted, as in `500–600 m` or `4:00`.
@immutable
class PlacementError {
  const PlacementError(
    this.kind, {
    this.placements = const {},
    this.zone,
    this.range,
    this.zoneAxis,
    this.courseAxis,
    this.courseLength,
    this.other,
    this.otherRange,
  });

  final PlacementErrorKind kind;

  /// The indices of the placements concerned; empty for the course itself.
  final Set<int> placements;

  /// The name of the zone concerned and the range it covers.
  final String? zone;
  final String? range;

  /// The axis of the zone and of the course, for [PlacementErrorKind.axisMismatch].
  final CourseAxis? zoneAxis;
  final CourseAxis? courseAxis;

  /// The length of the course, for [PlacementErrorKind.beyondEnd].
  final String? courseLength;

  /// The zone that [zone] overlaps, for [PlacementErrorKind.overlap].
  final String? other;
  final String? otherRange;

  @override
  String toString() => 'PlacementError(${kind.name}, $zone, $placements)';
}

/// A course laid out from its zones (Change zones, Design D2): either the
/// [definition] or the [errors] that keep it from being one.
@immutable
class CourseLayout {
  const CourseLayout._(this.definition, this.errors);

  final CourseDefinition? definition;
  final List<PlacementError> errors;

  bool get isValid => definition != null;
}

extension CoursePlacements on CourseDefinition {
  /// The zones placed in the course, in order.
  List<ZonePlacement> get placements {
    final starts = segmentStarts;
    return [
      for (final (i, s) in segments.indexed)
        if (s.zoneId != null)
          ZonePlacement(zoneId: s.zoneId!, start: starts[i]),
    ];
  }
}

/// Lays out a course of [length] from its [placements]: each must name one of
/// [zones] with the axis of the course, lie within the course and overlap no
/// other one; the gaps between them are free.
CourseLayout resolveCourse({
  required CourseAxis axis,
  required int length,
  required List<ZonePlacement> placements,
  required Map<int, Zone> zones,
}) {
  if (length <= 0) {
    return const CourseLayout._(null, [
      PlacementError(PlacementErrorKind.lengthMissing),
    ]);
  }
  final errors = <PlacementError>[];
  final valid = <(int, ZonePlacement, Zone)>[];
  for (final (i, p) in placements.indexed) {
    final zone = zones[p.zoneId];
    if (zone == null) {
      errors.add(
        PlacementError(PlacementErrorKind.zoneMissing, placements: {i}),
      );
      continue;
    }
    final range = formatCourseRange(axis, p.start, p.start + zone.length);
    if (zone.axis != axis) {
      errors.add(
        PlacementError(
          PlacementErrorKind.axisMismatch,
          placements: {i},
          zone: zone.name,
          zoneAxis: zone.axis,
          courseAxis: axis,
        ),
      );
    } else if (p.start < 0) {
      errors.add(
        PlacementError(
          PlacementErrorKind.beforeStart,
          placements: {i},
          zone: zone.name,
        ),
      );
    } else if (p.start + zone.length > length) {
      errors.add(
        PlacementError(
          PlacementErrorKind.beyondEnd,
          placements: {i},
          zone: zone.name,
          range: range,
          courseLength: formatCourseLength(axis, length),
        ),
      );
    } else {
      valid.add((i, p, zone));
    }
  }
  valid.sort((a, b) => a.$2.start.compareTo(b.$2.start));
  for (final (j, (i, p, zone)) in valid.indexed) {
    for (final (k, q, other) in valid.take(j)) {
      if (q.start + other.length <= p.start) continue;
      errors.add(
        PlacementError(
          PlacementErrorKind.overlap,
          placements: {k, i},
          zone: zone.name,
          range: formatCourseRange(axis, p.start, p.start + zone.length),
          other: other.name,
          otherRange: formatCourseRange(axis, q.start, q.start + other.length),
        ),
      );
    }
  }
  if (errors.isNotEmpty) return CourseLayout._(null, errors);

  final segments = <CourseSegment>[];
  var cursor = 0;
  for (final (_, p, zone) in valid) {
    if (p.start > cursor) segments.add(CourseSegment(length: p.start - cursor));
    segments.add(zone.segment);
    cursor = p.start + zone.length;
  }
  if (cursor < length) segments.add(CourseSegment(length: length - cursor));
  return CourseLayout._(
    CourseDefinition(axis: axis, length: length, segments: segments),
    const [],
  );
}
