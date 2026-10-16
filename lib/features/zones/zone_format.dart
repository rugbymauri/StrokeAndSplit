/// Display formats of zones.
library;

import '../../data/courses/course.dart';
import '../../data/zones/zone.dart';
import '../courses/course_format.dart';

/// The bands of a zone, e.g. `1:45–1:50 · 30–34 spm`.
String formatZoneBands(Zone zone) => formatSegmentBands(zone.segment);

/// `100 m · 1:45–1:50 · 30–34 spm`
String zoneSummary(Zone zone) => '${formatCourseLength(zone.axis, zone.length)} · ${formatZoneBands(zone)}';
