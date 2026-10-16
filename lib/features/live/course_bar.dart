import 'package:flutter/material.dart';

import '../../data/courses/course.dart';
import '../../data/courses/lap_tracker.dart';
import '../../l10n/l10n.dart';
import '../courses/course_format.dart';
import 'formatters.dart';

/// Lap, zone or free gap, what is left of it, its bands and the share in the zone,
/// above the core values while rowing a template.
class CourseBar extends StatelessWidget {
  const CourseBar({super.key, required this.lap, required this.course});

  final LapProgress lap;
  final CourseDefinition course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strong = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final share = lap.lapInZoneShare;
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 20,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              switch (lap.plannedLaps) {
                null => l10n.courseLap(lap.lap),
                final laps => l10n.courseLapOf(lap.lap, laps),
              },
              key: const Key('course-lap'),
              style: strong,
            ),
            // The zone the rower is in, or a free gap (Change zones, Design D7).
            Text(
              lap.segment.isFree ? l10n.segmentFree : lap.segment.zoneName ?? l10n.segmentZone,
              key: const Key('course-segment'),
              style: strong,
            ),
            Text(_range(), key: const Key('course-range')),
            Text(l10n.courseRest(_remaining()), key: const Key('course-rest'), style: strong),
            if (!lap.segment.isFree) Text(formatSegmentBands(lap.segment), key: const Key('course-bands')),
            if (share != null) Text(l10n.courseInZoneShare((share * 100).round()), key: const Key('course-zone')),
          ],
        ),
      ),
    );
  }

  String _range() => formatCourseRange(course.axis, lap.segmentStart, lap.segmentEnd);

  String _remaining() => course.axis == CourseAxis.distance
      ? '${lap.remaining.ceil()} m'
      : formatElapsed(Duration(seconds: lap.remaining.ceil()));
}

/// How a zone is shown on a value: colour, symbol and a word, so it does
/// not depend on colour alone.
class ZoneHint {
  const ZoneHint({required this.inZone, required this.icon, required this.text});

  final bool inZone;
  final IconData icon;
  final String text;

  /// For the pace; null without a pace band.
  static ZoneHint? pace(AppLocalizations l10n, BandStatus? status) => switch (status) {
        null || BandStatus.none => null,
        BandStatus.inBand => ZoneHint(inZone: true, icon: Icons.check_circle, text: l10n.hintInZone),
        BandStatus.above => ZoneHint(inZone: false, icon: Icons.arrow_upward, text: l10n.hintFaster),
        BandStatus.below => ZoneHint(inZone: false, icon: Icons.arrow_downward, text: l10n.hintSlower),
        BandStatus.missing => ZoneHint(inZone: false, icon: Icons.pause, text: l10n.hintNoPace),
      };

  /// For the stroke rate; null without a stroke rate band.
  static ZoneHint? strokeRate(AppLocalizations l10n, BandStatus? status) => switch (status) {
        null || BandStatus.none => null,
        BandStatus.inBand => ZoneHint(inZone: true, icon: Icons.check_circle, text: l10n.hintInZone),
        BandStatus.below => ZoneHint(inZone: false, icon: Icons.arrow_upward, text: l10n.hintMoreStrokes),
        BandStatus.above => ZoneHint(inZone: false, icon: Icons.arrow_downward, text: l10n.hintFewerStrokes),
        BandStatus.missing => ZoneHint(inZone: false, icon: Icons.pause, text: l10n.hintNoStrokes),
      };
}
