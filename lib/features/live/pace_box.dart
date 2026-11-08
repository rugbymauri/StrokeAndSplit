import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/ghost_symbol.dart';
import '../../data/courses/course.dart';
import '../../data/courses/lap_tracker.dart';
import '../../data/courses/zone_intensity.dart';
import '../../data/ghost/ghost.dart';
import '../../l10n/l10n.dart';
import '../courses/course_format.dart';
import 'zone_hint.dart';
import 'formatters.dart';
import 'live_text_styles.dart';
import 'metric_tile.dart';
import 'progress_frame.dart';
import 'progress_frame_model.dart';
import 'upcoming_zone.dart';

/// The pace while rowing a workout, inside the progress frame, with the
/// zone status of the pace and a legend line for each track (ui-design,
/// Design D3), plus the gap to the ghost of the workout (Change ghost,
/// Design D1, D4). It needs a bounded size; the pace shrinks to fit.
class PaceBox extends StatelessWidget {
  const PaceBox({
    super.key,
    required this.progress,
    required this.course,
    required this.pace,
    this.averagePace,
    this.ghost,
    this.ghostGap,
    this.upcoming,
    this.rowed = Duration.zero,
    this.limit,
    this.courseName,
  });

  final LapProgress progress;
  final CourseDefinition course;

  /// Per 500 m; null while not rowing.
  final Duration? pace;

  /// Per 500 m over the whole session, as in free rowing; null before the first metre.
  final Duration? averagePace;
  final FrameGhost? ghost;

  /// The gap to the ghost of the whole workout; null without one, and then
  /// the box has no ghost line.
  final GhostGap? ghostGap;

  /// The zone that starts in a few seconds; its pace band blinks in place of the zone status.
  final CourseSegment? upcoming;

  /// The rowing time without pauses, measured against [limit].
  final Duration rowed;

  /// The rowing time after which the session ends; null without one (course-rowing-free, Design D4).
  final Duration? limit;

  /// The name of the course being rowed, put before the zone when a workout
  /// has several courses (workout-course-chain, Design D6).
  final String? courseName;

  /// Room for the zone status, kept free without one so the pace stays put.
  static const statusHeight = 32.0;

  /// The line with the targets of the part being rowed, below the zone status (live-zone-targets, Design D4).
  static const targetsHeight = 20.0;

  /// The height inside the frame below which the content shrinks as a whole.
  static const minContentHeight = 260.0 + targetsHeight;

  /// What the content takes besides the pace, generously: label, zone status, targets, divider and
  /// legend including the average pace and the ghost line, so [paceFontSizeFor] holds with or without a ghost.
  static const _aroundPace = 190.0 + targetsHeight;

  /// At least the font size of the pace in a box of [size], so values next to the
  /// box can be kept smaller.
  static double paceFontSizeFor(Size size) {
    // The frame with all three tracks and the padding of [ProgressFrame].
    final inset = 2 * (ProgressFramePainter.frameWidth(3) + 12);
    final width = math.max(0.0, size.width - inset);
    final height = math.max(0.0, size.height - inset);
    final scale = height < minContentHeight ? height / minContentHeight : 1.0;
    return paceFontSize(
          Size(width, math.max(height, minContentHeight) - _aroundPace),
        ) *
        scale;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final model = ProgressFrameModel.of(
      progress,
      course,
      rowed: rowed,
      limit: limit,
    );
    final segment = progress.segment;
    final hint = ZoneHint.pace(l10n, progress.pace);
    // On a box tinted in the zone colour like the stroke rate card, the label and the pill follow it.
    final labelColor = switch (hint) {
      null => LiveTextStyles.label.color,
      ZoneHint(inZone: true) => AppColors.zoneInText,
      ZoneHint(inZone: false) => AppColors.zoneOutText,
    };
    return ProgressFrame(
      model: model,
      pace: progress.pace,
      ghost: ghost,
      // Below [minContentHeight] the content keeps its layout and shrinks as a whole,
      // so the pace stays the largest text.
      child: LayoutBuilder(
        builder: (context, constraints) => FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            // Wider by as much as it shrinks, so the shrunk content still fills the width.
            width:
                constraints.maxWidth *
                math.max(1, minContentHeight / constraints.maxHeight),
            height: constraints.maxHeight < minContentHeight
                ? minContentHeight
                : constraints.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.metricPace.toUpperCase(),
                  style: LiveTextStyles.label.copyWith(color: labelColor),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatPace(pace),
                        key: const Key('pace-box-pace'),
                        style: AppTextStyles.pace.copyWith(
                          color: AppColors.text,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: statusHeight,
                  child: upcoming != null && upcoming!.hasPaceBand
                      ? Center(
                          child: UpcomingPill(
                            key: const Key('pace-box-upcoming'),
                            text: l10n.hintUpcoming(_paceBand(upcoming!)!),
                            color: intensityColor(zoneIntensity(upcoming!)),
                            textKey: const Key('pace-box-upcoming-band'),
                          ),
                        )
                      : hint == null
                      ? null
                      : Center(
                          child: ZonePill(
                            key: Key(
                              'pace-box-zone-${hint.inZone ? 'in' : 'out'}',
                            ),
                            hint: hint,
                            textKey: const Key('pace-box-status'),
                            filled: true,
                          ),
                        ),
                ),
                // All targets of the part, whether in the zone or not; the band left the pill for it.
                SizedBox(
                  height: targetsHeight,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        zoneTargets(l10n, segment),
                        key: const Key('pace-box-targets'),
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.text,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
                  child: Divider(height: 1),
                ),
                // No track of its own, so no mark either.
                _LegendLine(
                  key: const Key('pace-box-average'),
                  marker: const SizedBox.shrink(),
                  label: l10n.metricAveragePace,
                  value: formatPace(averagePace),
                ),
                if (model.course != null)
                  _LegendLine(
                    key: const Key('pace-box-course'),
                    marker: const _Dot(AppColors.text),
                    label: l10n.paceBoxTotal,
                    value: switch (model.timeRemaining) {
                      // Rounded up like the rest of a lap, so it reads 0:00 only at the end.
                      final left? => l10n.courseRest(
                        _amount(left.inMilliseconds / 1000, CourseAxis.time),
                      ),
                      null => _done(model.courseDone!, model.courseLength!),
                    },
                  ),
                _LegendLine(
                  key: const Key('pace-box-lap'),
                  marker: const _Dot(AppColors.textMuted),
                  label: switch (progress.plannedLaps) {
                    null => l10n.courseLap(progress.lap),
                    final laps => l10n.paceBoxLapOf(progress.lap, laps),
                  },
                  value: l10n.courseRest(_amount(model.lapRemaining)),
                ),
                _LegendLine(
                  key: const Key('pace-box-segment'),
                  // The hardness of the zone as on the tracks, grey in a free part (Design D6).
                  marker: _Dot(switch (zoneIntensity(segment)) {
                    null => AppColors.textMuted,
                    final intensity => intensityColor(intensity),
                  }),
                  // The zone the rower is in, or a free gap (Change zones, Design D7).
                  label: switch ((
                    courseName,
                    segment.isFree
                        ? l10n.segmentFree
                        : segment.zoneName ?? l10n.segmentZone,
                  )) {
                    (final course?, final zone) => l10n.paceBoxCourseSegment(
                      course,
                      zone,
                    ),
                    (null, final zone) => zone,
                  },
                  value: l10n.courseRest(_amount(model.segmentRemaining)),
                ),
                if (ghostGap case final gap?) _ghostLine(l10n, gap),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The gap to the ghost: behind in orange, ahead in blue, and in words either way,
  /// e.g. `7.6 s vor dir` or `12 m hinter dir` (Change ghost, Design D4).
  static Widget _ghostLine(AppLocalizations l10n, GhostGap gap) {
    final (amount, level) = switch (gap.axis) {
      CourseAxis.distance => (
        _seconds(gap.amount),
        (gap.amount * 10).round() == 0,
      ),
      CourseAxis.time => (
        '${formatGrouped(gap.amount.round())} m',
        gap.amount.round() == 0,
      ),
    };
    final (value, color, kind) = level
        ? (l10n.paceBoxGhostLevel, AppColors.textMuted, 'level')
        : gap.ghostAhead
        ? (l10n.paceBoxGhostAhead(amount), AppColors.zoneOut, 'behind')
        : (l10n.paceBoxGhostBehind(amount), AppColors.zoneIn, 'ahead');
    return _LegendLine(
      key: Key('pace-box-ghost-$kind'),
      marker: const GhostSymbol(),
      label: l10n.paceBoxGhost,
      value: value,
      valueColor: color,
    );
  }

  /// Seconds with tenths like the pace, e.g. `7.6 s`; from a minute on like a lap time, e.g. `1:12.3`.
  static String _seconds(double seconds) {
    final tenths = (seconds * 10).round();
    return tenths < 600
        ? '${tenths ~/ 10}.${tenths % 10} s'
        : formatLapTime(Duration(milliseconds: tenths * 100));
  }

  /// The pace band of [segment], e.g. `2:05–2:10`; null without one.
  static String? _paceBand(CourseSegment segment) => segment.hasPaceBand
      ? '${formatPaceBound(segment.paceFastCs!)}–${formatPaceBound(segment.paceSlowCs!)}'
      : null;

  /// What is left, rounded up: metres with grouped thousands, e.g. `1 460 m`, or a time on a time course.
  String _amount(double left, [CourseAxis? axis]) =>
      (axis ?? course.axis) == CourseAxis.distance
      ? '${formatGrouped(left.ceil())} m'
      : formatElapsed(Duration(seconds: left.ceil()));

  /// Rowed of [total], rounded down, e.g. `1 460 / 3 000 m` or `24:20 / 50:00`.
  String _done(double done, int total) => course.axis == CourseAxis.distance
      ? '${formatGrouped(done.floor())} / ${formatGrouped(total)} m'
      : '${formatElapsed(Duration(seconds: done.floor()))} / ${formatElapsed(Duration(seconds: total))}';
}

/// The colour of a track in the legend.
class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: const SizedBox.square(dimension: _LegendLine.markerWidth),
  );
}

/// One line of the legend: the mark of its track, what it is and how far.
class _LegendLine extends StatelessWidget {
  const _LegendLine({
    super.key,
    required this.marker,
    required this.label,
    required this.value,
    this.valueColor = AppColors.textMuted,
  });

  /// The width of [marker]: a dot or the ghost symbol.
  static const markerWidth = 10.0;

  final Widget marker;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: LayoutBuilder(
        builder: (context, constraints) => _row(constraints.maxWidth),
      ),
    );
  }

  Widget _row(double width) {
    return Row(
      children: [
        SizedBox(
          width: markerWidth,
          child: Center(child: marker),
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(color: AppColors.text),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        // The value wins over the label, and shrinks only if it alone is too wide.
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width - markerWidth - AppSpacing.s * 2,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                color: valueColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
