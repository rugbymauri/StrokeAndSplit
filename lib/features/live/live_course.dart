import 'dart:math' as math;

import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../data/courses/course.dart';
import '../../data/courses/lap_tracker.dart';
import '../../data/ghost/ghost.dart';
import '../../l10n/l10n.dart';
import 'force_curve.dart';
import 'formatters.dart';
import 'live_layout.dart';
import 'live_status.dart';
import 'metric_tile.dart';
import 'pace_box.dart';
import 'progress_frame.dart';
import 'stroke_rate_card.dart';

/// The live display while rowing a template (ui-design, Design D2): the pace
/// box with the progress frame, the stroke rate card, four small tiles, the
/// force curve and the button that ends the session, with [status] beside it. The ghosts run in the
/// progress frame and the gap to the ghost of the template is in the pace
/// box (Change ghost, Design D1, D4).
class CourseLiveView extends StatelessWidget {
  const CourseLiveView({
    super.key,
    required this.tick,
    required this.lap,
    this.rrIntervalMs,
    required this.course,
    required this.action,
    required this.shortAction,
    this.outdated = false,
    this.forceCurves,
    this.ghost,
    this.ghostGap,
    this.status,
  });

  final StatusTick? tick;

  /// The last RR interval from the strap, shown below the heart rate; null without a recent one.
  final int? rrIntervalMs;
  final LapProgress lap;
  final CourseDefinition course;

  /// Ends the session; [shortAction] does the same in the narrow landscape column.
  final Widget action;
  final Widget shortAction;

  /// Whether the values are out of date; they are dimmed then.
  final bool outdated;

  /// The force curves of the last strokes; null for a source without them, which leaves the card out.
  final ForceCurves? forceCurves;

  /// Where the ghosts are on the tracks; null without any.
  final FrameGhost? ghost;

  /// The gap to the ghost of the whole template; null without one.
  final GhostGap? ghostGap;

  /// Connection and disconnect button beside the button; null leaves the button alone.
  final Widget? status;

  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      return switch (LiveLayout.of(size)) {
        LiveLayout.portrait => _portrait(context, size),
        LiveLayout.landscape => _landscape(context, size),
      };
    });
  }

  Widget _portrait(BuildContext context, Size size) {
    // A ghost moved out of the outer track sticks out of the box by up to
    // [ProgressFramePainter.overhang]; the top padding keeps it on the screen.
    final padding = EdgeInsets.fromLTRB(
      AppSpacing.pagePortrait,
      math.max(AppSpacing.s, ProgressFramePainter.overhang.ceilToDouble()),
      AppSpacing.pagePortrait,
      AppSpacing.s,
    );
    const strokeHeight = 88.0;
    const tilesHeight = 76.0;
    const curveHeight = 72.0;
    const buttonHeight = 52.0;
    final inner = padding.deflateSize(size);
    // The force curve goes first when space is short (Design, Risks).
    final curve = forceCurves != null && inner.height >= 720;
    final boxHeight =
        inner.height - strokeHeight - tilesHeight - buttonHeight - 3 * _gap - (curve ? curveHeight + _gap : 0);
    final cap = PaceBox.paceFontSizeFor(Size(inner.width, boxHeight)) * valueShareOfPace;
    return Padding(
      key: const ValueKey(LiveLayout.portrait),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: boxHeight, child: _dim(_paceBox())),
          const SizedBox(height: _gap),
          SizedBox(height: strokeHeight, child: _dim(_strokeRate(math.min(80, cap)))),
          const SizedBox(height: _gap),
          SizedBox(
            height: tilesHeight,
            child: _dim(Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, tile) in _tiles(context, math.min(48, cap)).indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.s),
                  Expanded(child: tile),
                ],
              ],
            )),
          ),
          if (curve) ...[
            const SizedBox(height: _gap),
            SizedBox(height: curveHeight, child: forceCurves!.widget(variant: ForceCurveVariant.strip)),
          ],
          const Spacer(),
          SizedBox(height: buttonHeight, child: LiveActionRow(action: action, status: status)),
        ],
      ),
    );
  }

  Widget _landscape(BuildContext context, Size size) {
    const padding = EdgeInsets.symmetric(horizontal: AppSpacing.pageLandscape, vertical: AppSpacing.m);
    const sideWidth = 128.0;
    const buttonHeight = 44.0;
    final inner = padding.deflateSize(size);
    // Nearly square as in the canvas, but leaving room for the stroke rate.
    final boxWidth = math.min(inner.height, (inner.width - sideWidth - 2 * AppSpacing.m) * 0.65);
    final cap = PaceBox.paceFontSizeFor(Size(boxWidth, inner.height)) * valueShareOfPace;
    final curve = forceCurves != null && inner.height >= 260;
    final tiles = _tiles(context, math.min(48, cap));
    return Padding(
      key: const ValueKey(LiveLayout.landscape),
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: boxWidth, child: _dim(_paceBox())),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _dim(_strokeRate(
                    math.min(AppTextStyles.value.fontSize!, cap),
                    landscape: true,
                    footer: curve
                        ? (foreground) => forceCurves!.widget(variant: ForceCurveVariant.tinted, foreground: foreground)
                        : null,
                  )),
                ),
                // The side column is too narrow for it, so it sits left of the button, in the same row.
                if (status case final status?) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    height: buttonHeight,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(fit: BoxFit.scaleDown, child: status),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          SizedBox(
            width: sideWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final tile in tiles) ...[
                  Expanded(child: _dim(tile)),
                  const SizedBox(height: 6),
                ],
                SizedBox(height: buttonHeight, child: shortAction),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dim(Widget child) => Opacity(opacity: outdated ? 0.4 : 1, child: child);

  Widget _paceBox() =>
      PaceBox(progress: lap, course: course, pace: tick?.pace, ghost: ghost, ghostGap: ghostGap);

  Widget _strokeRate(double fontSize, {bool landscape = false, Widget Function(Color foreground)? footer}) =>
      StrokeRateCard(
          strokeRate: tick?.strokeRate,
          status: lap.strokeRate,
          segment: lap.segment,
          fontSize: fontSize,
          landscape: landscape,
          footer: footer,
        );

  /// Lap time, watts and heart rate (only with a monitor).
  List<Widget> _tiles(BuildContext context, double fontSize) {
    final l10n = context.l10n;
    final heartRate = tick?.heartRate;
    return [
      MetricTile(
        label: l10n.metricLapTime,
        value: formatElapsed(lap.lapTime),
        valueKey: const Key('metric-lap-time'),
        fontSize: fontSize,
        compact: true,
      ),
      MetricTile(
        label: l10n.metricWatts,
        value: formatWhole(tick?.watts),
        valueKey: const Key('metric-watts'),
        fontSize: fontSize,
        compact: true,
      ),
      if (heartRate != null)
        MetricTile(
          label: l10n.metricHeartRate,
          value: formatWhole(heartRate),
          valueKey: const Key('metric-hr'),
          fontSize: fontSize,
          icon: const HeartIcon(size: 12),
          footnote: rrIntervalMs == null ? null : formatRrInterval(rrIntervalMs!),
          footnoteKey: const Key('metric-rr'),
          compact: true,
        ),
    ];
  }
}
