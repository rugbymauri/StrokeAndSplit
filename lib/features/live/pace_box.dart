import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../data/courses/course.dart';
import '../../data/courses/lap_tracker.dart';
import '../../l10n/l10n.dart';
import '../courses/course_format.dart';
import 'zone_hint.dart';
import 'formatters.dart';
import 'metric_tile.dart';
import 'progress_frame.dart';
import 'progress_frame_model.dart';

/// The pace while rowing a template, inside the progress frame, with the
/// zone status of the pace and a legend line for each track (ui-design,
/// Design D3). It needs a bounded size; the pace shrinks to fit.
class PaceBox extends StatelessWidget {
  const PaceBox({super.key, required this.progress, required this.course, required this.pace, this.ghost});

  final LapProgress progress;
  final CourseDefinition course;

  /// Per 500 m; null while not rowing.
  final Duration? pace;
  final FrameGhost? ghost;

  /// Room for the zone status, kept free without one so the pace stays put.
  static const statusHeight = 32.0;

  /// The height inside the frame below which the content shrinks as a whole.
  static const minContentHeight = 260.0;

  /// What the content takes besides the pace, generously: label, zone status, divider and legend.
  static const _aroundPace = 160.0;

  /// At least the font size of the pace in a box of [size], so values next to the
  /// box can be kept smaller.
  static double paceFontSizeFor(Size size) {
    // The frame with all three tracks and the padding of [ProgressFrame].
    final inset = 2 * (ProgressFramePainter.frameWidth(3) + 12);
    final width = math.max(0.0, size.width - inset);
    final height = math.max(0.0, size.height - inset);
    final scale = height < minContentHeight ? height / minContentHeight : 1.0;
    return paceFontSize(Size(width, math.max(height, minContentHeight) - _aroundPace)) * scale;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final model = ProgressFrameModel.of(progress, course);
    final segment = progress.segment;
    final hint = ZoneHint.pace(l10n, progress.pace);
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
            width: constraints.maxWidth,
            height: constraints.maxHeight < minContentHeight ? minContentHeight : constraints.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.metricPace.toUpperCase(),
                  style: AppTextStyles.label,
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
                  child: hint == null ? null : Center(child: _Status(hint: hint, band: _paceBand(segment))),
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.s), child: Divider(height: 1)),
                if (model.course != null)
                  _LegendLine(
                    key: const Key('pace-box-course'),
                    color: AppColors.text,
                    label: l10n.paceBoxTotal,
                    value: _done(model.courseDone!, model.courseLength!),
                  ),
                _LegendLine(
                  key: const Key('pace-box-lap'),
                  color: AppColors.textMuted,
                  label: switch (progress.plannedLaps) {
                    null => l10n.courseLap(progress.lap),
                    final laps => l10n.paceBoxLapOf(progress.lap, laps),
                  },
                  value: l10n.courseRest(_amount(model.lapRemaining)),
                ),
                _LegendLine(
                  key: const Key('pace-box-segment'),
                  color: ProgressFramePainter.segmentColor(progress.pace),
                  // The zone the rower is in, or a free gap (Change zones, Design D7).
                  label: segment.isFree ? l10n.segmentFree : segment.zoneName ?? l10n.segmentZone,
                  value: l10n.courseRest(_amount(model.segmentRemaining)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The pace band of [segment], e.g. `2:05–2:10`; null without one.
  static String? _paceBand(CourseSegment segment) => segment.hasPaceBand
      ? '${formatPaceBound(segment.paceFastCs!)}–${formatPaceBound(segment.paceSlowCs!)}'
      : null;

  /// What is left, rounded up: metres with grouped thousands, e.g. `1 460 m`, or a time on a time course.
  String _amount(double left) => course.axis == CourseAxis.distance
      ? '${formatGrouped(left.ceil())} m'
      : formatElapsed(Duration(seconds: left.ceil()));

  /// Rowed of [total], rounded down, e.g. `1 460 / 3 000 m` or `24:20 / 50:00`.
  String _done(double done, int total) => course.axis == CourseAxis.distance
      ? '${formatGrouped(done.floor())} / ${formatGrouped(total)} m'
      : '${formatElapsed(Duration(seconds: done.floor()))} / ${formatElapsed(Duration(seconds: total))}';
}

/// The zone status of the pace as symbol and word, not only as colour, with the band.
class _Status extends StatelessWidget {
  const _Status({required this.hint, required this.band});

  final ZoneHint hint;
  final String? band;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = hint.inZone
        ? (AppColors.zoneInSurface, AppColors.zoneInText)
        : (AppColors.zoneOutSurface, AppColors.zoneOutText);
    final band = this.band;
    return DecoratedBox(
      key: Key('pace-box-zone-${hint.inZone ? 'in' : 'out'}'),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(PaceBox.statusHeight / 2)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(hint.icon, size: 18, color: foreground),
            const SizedBox(width: AppSpacing.s),
            Flexible(
              child: Text(
                band == null ? hint.text : '${hint.text} · $band',
                key: const Key('pace-box-status'),
                style: AppTextStyles.button.copyWith(color: foreground),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One line of the legend: the colour of its track, what it is and what is left.
class _LegendLine extends StatelessWidget {
  const _LegendLine({super.key, required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final String value;

  static const _dot = 10.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: LayoutBuilder(builder: (context, constraints) => _row(constraints.maxWidth)),
    );
  }

  Widget _row(double width) {
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox.square(dimension: _dot),
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
          constraints: BoxConstraints(maxWidth: width - _dot - AppSpacing.s * 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
