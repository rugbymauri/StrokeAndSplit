/// Input and display formats of courses.
library;

import '../../data/courses/course.dart';

/// A pace bound per 500 m, e.g. `2:05` or `2:05.5`.
String formatPaceBound(int centiseconds) {
  final tenths = centiseconds ~/ 10;
  final seconds = tenths ~/ 10;
  final text = '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  return tenths % 10 == 0 ? text : '$text.${tenths % 10}';
}

/// The bands of a zone's segment, e.g. `2:05–2:10 · 20–22 spm`; empty for a
/// free part.
String formatSegmentBands(CourseSegment segment) {
  return [
    if (segment.hasPaceBand) '${formatPaceBound(segment.paceFastCs!)}–${formatPaceBound(segment.paceSlowCs!)}',
    if (segment.hasSpmBand) '${segment.spmMin}–${segment.spmMax} spm',
  ].join(' · ');
}

/// A length as typed: metres, or `m:ss` (or whole minutes) on a time course.
int? parseCourseLength(CourseAxis axis, String text) {
  final value = text.trim();
  if (axis == CourseAxis.distance) return int.tryParse(value);
  final match = RegExp(r'^(\d+)(?::([0-5]\d))?$').firstMatch(value);
  if (match == null) return null;
  return int.parse(match[1]!) * 60 + int.parse(match[2] ?? '0');
}

/// A pace per 500 m as typed, e.g. `2:05` or `2:05.5`, in centiseconds.
int? parsePace(String text) {
  final match = RegExp(r'^(\d+):([0-5]\d)(?:[.,](\d))?$').firstMatch(text.trim());
  if (match == null) return null;
  return ((int.parse(match[1]!) * 60 + int.parse(match[2]!)) * 10 + int.parse(match[3] ?? '0')) * 10;
}
