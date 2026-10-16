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
  bool operator ==(Object other) => other is ZonePlacement && other.zoneId == zoneId && other.start == start;

  @override
  int get hashCode => Object.hash(zoneId, start);

  @override
  String toString() => 'ZonePlacement($zoneId at $start)';
}

/// Why a course cannot be laid out, in words for the user.
@immutable
class PlacementError {
  const PlacementError(this.message, {this.placements = const {}});

  final String message;

  /// The indices of the placements concerned; empty for the course itself.
  final Set<int> placements;

  @override
  String toString() => message;
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
        if (s.zoneId != null) ZonePlacement(zoneId: s.zoneId!, start: starts[i]),
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
  if (length <= 0) return const CourseLayout._(null, [PlacementError('Die Länge fehlt.')]);
  final errors = <PlacementError>[];
  final valid = <(int, ZonePlacement, Zone)>[];
  for (final (i, p) in placements.indexed) {
    final zone = zones[p.zoneId];
    if (zone == null) {
      errors.add(PlacementError('Eine eingebaute Zone gibt es nicht mehr.', placements: {i}));
      continue;
    }
    final name = '„${zone.name}“';
    final range = formatCourseRange(axis, p.start, p.start + zone.length);
    if (zone.axis != axis) {
      final message = '$name misst ${_axisWord(zone.axis)}, die Strecke ${_axisWord(axis)}.';
      errors.add(PlacementError(message, placements: {i}));
    } else if (p.start < 0) {
      errors.add(PlacementError('$name beginnt vor dem Start der Strecke.', placements: {i}));
    } else if (p.start + zone.length > length) {
      errors.add(PlacementError(
        '$name ($range) ragt über das Streckenende bei ${formatCourseLength(axis, length)}.',
        placements: {i},
      ));
    } else {
      valid.add((i, p, zone));
    }
  }
  valid.sort((a, b) => a.$2.start.compareTo(b.$2.start));
  for (final (j, (i, p, zone)) in valid.indexed) {
    for (final (k, q, other) in valid.take(j)) {
      if (q.start + other.length <= p.start) continue;
      errors.add(PlacementError(
        '„${zone.name}“ (${formatCourseRange(axis, p.start, p.start + zone.length)}) überschneidet '
        '„${other.name}“ (${formatCourseRange(axis, q.start, q.start + other.length)}).',
        placements: {k, i},
      ));
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
  return CourseLayout._(CourseDefinition(axis: axis, length: length, segments: segments), const []);
}

String _axisWord(CourseAxis axis) => switch (axis) {
      CourseAxis.distance => 'Distanz',
      CourseAxis.time => 'Zeit',
    };
