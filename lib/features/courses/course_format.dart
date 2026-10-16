/// Display formats of courses.
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
