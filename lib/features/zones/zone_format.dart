/// Display formats of zones.
library;

import '../../data/courses/course.dart';
import '../../data/zones/zone.dart';
import '../../l10n/l10n.dart';
import '../courses/course_format.dart';

/// The bands of a zone with its resistance level, e.g. `1:45–1:50 · 30–34 spm · Stufe 10`.
String formatZoneBands(AppLocalizations l10n, Zone zone) => formatSegmentBands(l10n, zone.segment);

/// `100 m · 1:45–1:50 · 30–34 spm`
String zoneSummary(AppLocalizations l10n, Zone zone) =>
    '${formatCourseLength(zone.axis, zone.length)} · ${formatZoneBands(l10n, zone)}';
