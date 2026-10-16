import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../data/courses/course.dart';
import '../../l10n/l10n.dart';

/// A course as a bar (design D4 of `ui-design`): each segment as wide as it is
/// long, free gaps grey, placed zones blue, faster pace bands brighter.
class CourseStrip extends StatelessWidget {
  const CourseStrip({
    super.key,
    required this.definition,
    this.height = listHeight,
    this.showNames = false,
    this.selected,
    this.onSegmentTap,
  });

  /// The height in lists.
  static const listHeight = 8.0;

  /// The height with zone names, in the course editor.
  static const namedHeight = 28.0;

  /// The slowest and the fastest of several pace bands.
  static const slowestPace = Color(0xFF2F5577);
  static const fastestPace = AppColors.zoneInText;

  final CourseDefinition definition;
  final double height;

  /// Whether the zones carry their names.
  final bool showNames;

  /// The index of the segment outlined as selected.
  final int? selected;

  final ValueChanged<int>? onSegmentTap;

  @override
  Widget build(BuildContext context) {
    final colors = segmentColors(definition.segments);
    final label = Theme.of(context).textTheme.labelSmall;
    return ClipRRect(
      borderRadius: BorderRadius.circular(math.min(height / 2, 6)),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (final (i, s) in definition.segments.indexed)
              if (s.length > 0)
                Expanded(
                  flex: s.length,
                  child: GestureDetector(
                    onTap: onSegmentTap == null ? null : () => onSegmentTap!(i),
                    child: Container(
                      key: ValueKey('course-strip-segment-$i'),
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(color: colors[i]),
                      foregroundDecoration:
                          i == selected ? BoxDecoration(border: Border.all(color: AppColors.text, width: 2)) : null,
                      child: showNames && !s.isFree
                          ? Text(
                              s.zoneName ?? context.l10n.segmentZone,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: label?.copyWith(color: _textOn(colors[i])),
                            )
                          : null,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  static Color _textOn(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.light ? AppColors.bg : AppColors.text;

  /// The smallest step in shade between two distinct pace bands, as a share
  /// of the range from [fastestPace] to [slowestPace].
  static const minShadeStep = 0.15;

  /// The colour of each segment: free gaps [AppColors.line], zones
  /// [AppColors.zoneIn], or shaded from [fastestPace] to [slowestPace] in
  /// proportion to the pace when the zones have more than one distinct pace band.
  static List<Color> segmentColors(List<CourseSegment> segments) {
    final shades = _paceShades(segments);
    return [
      for (final s in segments)
        if (s.isFree)
          AppColors.line
        else if (!s.hasPaceBand || shades.length < 2)
          AppColors.zoneIn
        else
          Color.lerp(fastestPace, slowestPace, shades[_paceSum(s)]!)!,
    ];
  }

  /// Maps the middle of each distinct pace band to a shade from 0 (fastest) to
  /// 1 (slowest), proportional to the pace but at least [minShadeStep] apart.
  static Map<int, double> _paceShades(List<CourseSegment> segments) {
    final paces = {
      for (final s in segments)
        if (s.hasPaceBand) _paceSum(s),
    }.toList()
      ..sort();
    if (paces.length < 2) return {};
    final range = paces.last - paces.first;
    final step = math.min(minShadeStep, 1 / (paces.length - 1));
    final shades = <double>[0];
    for (final pace in paces.skip(1)) {
      shades.add(math.max((pace - paces.first) / range, shades.last + step));
    }
    return {for (final (i, pace) in paces.indexed) pace: shades[i] / shades.last};
  }

  static int _paceSum(CourseSegment s) => s.paceFastCs! + s.paceSlowCs!;
}
