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
import 'watts_tile.dart';
import 'pace_box.dart';
import 'progress_frame.dart';
import 'resistance_card.dart';
import 'stroke_rate_card.dart';
import 'upcoming_zone.dart';

/// The live display while rowing a workout (ui-design, Design D2): the pace
/// box with the progress frame, the stroke rate card, the small tiles of the session and the lap, the
/// force curve and the button that ends the session, with [status] beside it. The ghosts run in the
/// progress frame and the gap to the ghost of the workout is in the pace
/// box (Change ghost, Design D1, D4).
class CourseLiveView extends StatelessWidget {
  const CourseLiveView({
    super.key,
    required this.tick,
    this.session,
    required this.lap,
    required this.course,
    required this.action,
    required this.shortAction,
    this.outdated = false,
    this.forceCurves,
    this.ghost,
    this.ghostGap,
    this.status,
    this.limit,
    this.courseName,
  });

  final StatusTick? tick;

  /// Time and distance of the running session; its time is shown instead of the rower's.
  final SessionProgress? session;

  final LapProgress lap;
  final CourseDefinition course;

  /// The name of the course being rowed when a workout has several; null
  /// otherwise (workout-course-chain, Design D6).
  final String? courseName;

  /// Ends the session; [shortAction] does the same in the narrow landscape column.
  final Widget action;
  final Widget shortAction;

  /// Whether the values are out of date; they are dimmed then.
  final bool outdated;

  /// The force curves of the last strokes; null for a source without them, which leaves the card out.
  final ForceCurves? forceCurves;

  /// Where the ghosts are on the tracks; null without any.
  final FrameGhost? ghost;

  /// The gap to the ghost of the whole workout; null without one.
  final GhostGap? ghostGap;

  /// Connection and disconnect button beside the button; null leaves the button alone.
  final Widget? status;

  /// The rowing time after which the session ends; null without one (course-rowing-free, Design D4).
  final Duration? limit;

  static const _gap = 10.0;

  /// The height of the pace box in portrait below which the force curve gives way.
  static const _minBoxHeightWithCurve = 336.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return switch (LiveLayout.of(size)) {
          LiveLayout.portrait => _portrait(context, size),
          LiveLayout.landscape => _landscape(context, size),
        };
      },
    );
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
    const strokeHeight = 80.0;
    const tilesHeight = 64.0;
    const curveHeight = 72.0;
    const buttonHeight = 52.0;
    final inner = padding.deflateSize(size);
    // Two rows of tiles, the session above the lap, as five side by side would be too narrow on a phone.
    final rest =
        inner.height - strokeHeight - 2 * tilesHeight - buttonHeight - 4 * _gap;
    // The force curve goes first when space is short (Design, Risks): only while the pace box keeps
    // [_minBoxHeightWithCurve], so on a phone of 360 × 740 as well.
    final curve =
        forceCurves != null &&
        rest - curveHeight - _gap >= _minBoxHeightWithCurve;
    final boxHeight = rest - (curve ? curveHeight + _gap : 0);
    final cap =
        PaceBox.paceFontSizeFor(Size(inner.width, boxHeight)) *
        valueShareOfPace;
    // Lower than with Barlow Condensed, as the wider [AppFonts.liveValue] fills a tile at a smaller size.
    final valueSize = math.min(42.0, cap);
    return Padding(
      key: const ValueKey(LiveLayout.portrait),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: boxHeight, child: _dim(_paceBox())),
          const SizedBox(height: _gap),
          SizedBox(
            height: strokeHeight,
            child: _dim(_strokeRate(math.min(64, cap))),
          ),
          const SizedBox(height: _gap),
          SizedBox(
            height: tilesHeight,
            child: _dim(_tileRow(_sessionTiles(context, valueSize))),
          ),
          const SizedBox(height: _gap),
          SizedBox(
            height: tilesHeight,
            child: _dim(_tileRow(_lapTiles(context, valueSize))),
          ),
          if (curve) ...[
            const SizedBox(height: _gap),
            SizedBox(
              height: curveHeight,
              child: forceCurves!.widget(variant: ForceCurveVariant.strip),
            ),
          ],
          const Spacer(),
          SizedBox(
            height: buttonHeight,
            child: LiveActionRow(action: action, status: status),
          ),
        ],
      ),
    );
  }

  Widget _landscape(BuildContext context, Size size) {
    const padding = EdgeInsets.symmetric(
      horizontal: AppSpacing.pageLandscape,
      vertical: AppSpacing.m,
    );
    const sideWidth = 128.0;
    const buttonHeight = 44.0;
    const sessionHeight = 64.0;
    final inner = padding.deflateSize(size);
    // Nearly square as in the canvas, but leaving room for the stroke rate.
    final boxWidth = math.min(
      inner.height,
      (inner.width - sideWidth - 2 * AppSpacing.m) * 0.65,
    );
    final cap =
        PaceBox.paceFontSizeFor(Size(boxWidth, inner.height)) *
        valueShareOfPace;
    final curve = forceCurves != null && inner.height >= 260;
    final valueSize = math.min(48.0, cap);
    final tiles = _lapTiles(context, valueSize, showResistance: false);
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
                  child: _dim(
                    _strokeRate(
                      math.min(AppTextStyles.value.fontSize!, cap),
                      landscape: true,
                      footer: curve
                          ? (foreground) => forceCurves!.widget(
                              variant: ForceCurveVariant.tinted,
                              foreground: foreground,
                            )
                          : null,
                    ),
                  ),
                ),
                // The level with its oar blades right below the stroke rate, as wide as it (Design D7).
                ResistanceCard(tick: tick, fontSize: valueSize),
                // Below the stroke rate, as five tiles do not fit into the side column on a phone.
                const SizedBox(height: 6),
                SizedBox(
                  height: sessionHeight,
                  child: _dim(_tileRow(_sessionTiles(context, valueSize))),
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

  Widget _dim(Widget child) =>
      Opacity(opacity: outdated ? 0.4 : 1, child: child);

  Widget _paceBox() => PaceBox(
    progress: lap,
    course: course,
    pace: tick?.pace,
    averagePace: averagePace(
      session?.distanceMeters ?? tick?.distanceMeters ?? 0,
      session?.elapsed ?? tick?.elapsed ?? Duration.zero,
    ),
    ghost: ghost,
    ghostGap: ghostGap,
    upcoming: _upcoming,
    rowed: session?.elapsed ?? Duration.zero,
    limit: limit,
    courseName: courseName,
  );

  Widget _strokeRate(
    double fontSize, {
    bool landscape = false,
    Widget Function(Color foreground)? footer,
  }) => StrokeRateCard(
    strokeRate: tick?.strokeRate,
    status: lap.strokeRate,
    segment: lap.segment,
    fontSize: fontSize,
    landscape: landscape,
    footer: footer,
    upcoming: _upcoming,
  );

  CourseSegment? get _upcoming => upcomingZone(lap, course, tick?.pace);

  Widget _tileRow(List<Widget> tiles) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, tile) in tiles.indexed) ...[
        if (i > 0) const SizedBox(width: AppSpacing.s),
        Expanded(child: tile),
      ],
    ],
  );

  /// Time and distance of the whole session, as in free rowing, and the calories when the rower sends them.
  List<Widget> _sessionTiles(BuildContext context, double fontSize) {
    final l10n = context.l10n;
    final calories = tick?.calories;
    final elapsed = session?.elapsed ?? tick?.elapsed ?? Duration.zero;
    final distance = session?.distanceMeters ?? tick?.distanceMeters ?? 0;
    return [
      MetricTile(
        label: l10n.metricTime,
        value: formatElapsed(elapsed),
        valueKey: const Key('metric-elapsed'),
        fontSize: fontSize,
        compact: true,
      ),
      MetricTile(
        label: l10n.metricDistance,
        value: formatGrouped(distance.floor()),
        unit: 'm',
        valueKey: const Key('metric-distance'),
        fontSize: fontSize,
        compact: true,
      ),
      if (calories != null)
        MetricTile(
          label: l10n.metricCalories,
          value: formatWhole(calories),
          valueKey: const Key('metric-calories'),
          fontSize: fontSize,
          compact: true,
        ),
    ];
  }

  /// Lap time, watts and heart rate (only with a monitor).
  List<Widget> _lapTiles(
    BuildContext context,
    double fontSize, {
    bool showResistance = true,
  }) {
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
      WattsTile(
        tick: tick,
        fontSize: fontSize,
        compact: true,
        showResistance: showResistance,
      ),
      if (heartRate != null)
        MetricTile(
          label: l10n.metricHeartRate,
          value: formatWhole(heartRate),
          valueKey: const Key('metric-hr'),
          fontSize: fontSize,
          icon: const HeartIcon(size: 12),
          compact: true,
        ),
    ];
  }
}
