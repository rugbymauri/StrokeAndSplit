import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../data/courses/course.dart';
import '../../data/courses/lap_tracker.dart';
import 'zone_hint.dart';

/// How long before a zone starts its bands are announced (ui-design, Design D3).
const upcomingLead = Duration(seconds: 10);

/// The zone that starts within [lead], so the rower can get ready for its bands; null when the next
/// segment is free, rows with the same bands, is further away or there is none.
///
/// On a distance course the time left comes from the current [pace]; without one nothing is announced.
CourseSegment? upcomingZone(
  LapProgress progress,
  CourseDefinition course,
  Duration? pace, {
  Duration lead = upcomingLead,
}) {
  final segments = course.segments;
  final CourseSegment next;
  if (progress.segmentIndex < segments.length - 1) {
    next = segments[progress.segmentIndex + 1];
  } else if (progress.plannedLaps == null || progress.lap < progress.plannedLaps!) {
    next = segments.first;
  } else {
    return null;
  }
  if (next.isFree || _sameBands(next, progress.segment)) return null;
  final double seconds;
  switch (course.axis) {
    case CourseAxis.time:
      seconds = progress.remaining;
    case CourseAxis.distance:
      if (pace == null || pace <= Duration.zero) return null;
      seconds = progress.remaining * pace.inMilliseconds / 500 / 1000;
  }
  return seconds > 0 && seconds <= lead.inMilliseconds / 1000 ? next : null;
}

bool _sameBands(CourseSegment a, CourseSegment b) =>
    a.paceFastCs == b.paceFastCs && a.paceSlowCs == b.paceSlowCs && a.spmMin == b.spmMin && a.spmMax == b.spmMax;

/// The band of the next zone as a blinking yellow pill, e.g. `» Gleich 2:05–2:10`, below the pace and on
/// the stroke rate card. It stays lit when the platform asks for less motion.
class UpcomingPill extends StatefulWidget {
  const UpcomingPill({
    super.key,
    required this.text,
    this.textKey,
    this.scaleDown = false,
    this.dense = false,
  });

  /// One blink: lit for most of it, then dimmed.
  static const period = Duration(milliseconds: 900);

  final String text;
  final Key? textKey;

  /// Shrinks the text to fit instead of cutting it off, like [ZonePill.scaleDown].
  final bool scaleDown;
  final bool dense;

  @override
  State<UpcomingPill> createState() => _UpcomingPillState();
}

class _UpcomingPillState extends State<UpcomingPill> with SingleTickerProviderStateMixin {
  late final _blink = AnimationController(vsync: this, duration: UpcomingPill.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _blink.stop();
    } else if (!_blink.isAnimating) {
      _blink.repeat();
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Text(
      widget.text,
      key: widget.textKey,
      style: AppTextStyles.button.copyWith(color: AppColors.bg, fontWeight: FontWeight.w600),
      maxLines: 1,
      overflow: widget.scaleDown ? null : TextOverflow.ellipsis,
    );
    final pill = DecoratedBox(
      decoration: BoxDecoration(color: AppColors.upcoming, borderRadius: BorderRadius.circular(ZonePill.radius)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.dense ? AppSpacing.s : AppSpacing.m),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.double_arrow, size: 18, color: AppColors.bg),
            SizedBox(width: widget.dense ? AppSpacing.xs : AppSpacing.s),
            Flexible(child: widget.scaleDown ? FittedBox(fit: BoxFit.scaleDown, child: text) : text),
          ],
        ),
      ),
    );
    return AnimatedBuilder(
      animation: _blink,
      // Dimmed rather than gone, so the band can be read at any moment.
      builder: (context, child) => Opacity(opacity: _blink.value < 0.65 ? 1 : 0.3, child: child),
      child: pill,
    );
  }
}
