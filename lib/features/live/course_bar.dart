import 'package:flutter/material.dart';

import '../../data/courses/course.dart';
import '../../data/courses/lap_tracker.dart';
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
              lap.plannedLaps == null ? 'Runde ${lap.lap}' : 'Runde ${lap.lap} von ${lap.plannedLaps}',
              key: const Key('course-lap'),
              style: strong,
            ),
            // The zone the rower is in, or a free gap (Change zones, Design D7).
            Text(
              lap.segment.isFree ? 'frei' : lap.segment.zoneName ?? 'Zone',
              key: const Key('course-segment'),
              style: strong,
            ),
            Text(_range(), key: const Key('course-range')),
            Text('noch ${_remaining()}', key: const Key('course-rest'), style: strong),
            if (!lap.segment.isFree) Text(formatSegmentBands(lap.segment), key: const Key('course-bands')),
            if (share != null) Text('Zone ${(share * 100).round()} %', key: const Key('course-zone')),
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
  static ZoneHint? pace(BandStatus? status) => switch (status) {
        null || BandStatus.none => null,
        BandStatus.inBand => const ZoneHint(inZone: true, icon: Icons.check_circle, text: 'in der Zone'),
        BandStatus.above => const ZoneHint(inZone: false, icon: Icons.arrow_upward, text: 'schneller'),
        BandStatus.below => const ZoneHint(inZone: false, icon: Icons.arrow_downward, text: 'langsamer'),
        BandStatus.missing => const ZoneHint(inZone: false, icon: Icons.pause, text: 'keine Pace'),
      };

  /// For the stroke rate; null without a stroke rate band.
  static ZoneHint? strokeRate(BandStatus? status) => switch (status) {
        null || BandStatus.none => null,
        BandStatus.inBand => const ZoneHint(inZone: true, icon: Icons.check_circle, text: 'in der Zone'),
        BandStatus.below => const ZoneHint(inZone: false, icon: Icons.arrow_upward, text: 'mehr Schläge'),
        BandStatus.above => const ZoneHint(inZone: false, icon: Icons.arrow_downward, text: 'weniger Schläge'),
        BandStatus.missing => const ZoneHint(inZone: false, icon: Icons.pause, text: 'keine Schläge'),
      };
}
