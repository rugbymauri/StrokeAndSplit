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

  /// The colour of each segment: free gaps [AppColors.line], zones
  /// [AppColors.zoneIn], or shaded from [slowestPace] to [fastestPace] when
  /// the zones have more than one distinct pace band.
  static List<Color> segmentColors(List<CourseSegment> segments) {
    // A band is ranked by its middle; equal bands get the same shade.
    final paces = {
      for (final s in segments)
        if (s.hasPaceBand) _paceSum(s),
    }.toList()
      ..sort();
    return [
      for (final s in segments)
        if (s.isFree)
          AppColors.line
        else if (!s.hasPaceBand || paces.length < 2)
          AppColors.zoneIn
        else
          // Paces are times, so the smallest is the fastest and brightest.
          Color.lerp(fastestPace, slowestPace, paces.indexOf(_paceSum(s)) / (paces.length - 1))!,
    ];
  }

  static int _paceSum(CourseSegment s) => s.paceFastCs! + s.paceSlowCs!;
}
