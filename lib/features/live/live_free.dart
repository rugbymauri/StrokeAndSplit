import 'dart:math' as math;

import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../l10n/l10n.dart';
import 'force_curve.dart';
import 'formatters.dart';
import 'live_layout.dart';
import 'metric_tile.dart';

/// The live display without a template (ui-design, Design D2): the pace on
/// top or on the left, four tiles, a line with further values, the force
/// curve and [action], the button that starts or ends the session.
class FreeLiveView extends StatelessWidget {
  const FreeLiveView({
    super.key,
    required this.tick,
    required this.session,
    required this.action,
    this.rrIntervalMs,
    this.outdated = false,
    this.forces,
  });

  final StatusTick? tick;

  /// The last RR interval from the strap, shown after the heart rate; null without a recent one.
  final int? rrIntervalMs;

  /// Time and distance of the running session, shown instead of the rower's.
  final SessionProgress? session;
  final Widget action;

  /// Whether the values are out of date; they are dimmed then.
  final bool outdated;

  /// The force curve of the last stroke; left out while null.
  final List<double>? forces;

  /// Room the label above the pace takes at most.
  static const _labelHeight = 20.0;
  static const _gap = AppSpacing.m;

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
    const padding = EdgeInsets.symmetric(horizontal: AppSpacing.pagePortrait, vertical: AppSpacing.s);
    final inner = padding.deflateSize(size);
    final paceHeight = (inner.height * 0.22).clamp(72.0, 160.0);
    final pace = paceFontSize(Size(inner.width, paceHeight - _labelHeight));
    // The force curve goes first when space is short (Design, Risks).
    final curve = ForceCurve.hasData(forces) && inner.height >= 640;
    return Padding(
      key: const ValueKey(LiveLayout.portrait),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: paceHeight, child: _dim(_pace(context, pace))),
          const SizedBox(height: _gap),
          Expanded(child: _dim(_tiles(context, math.min(AppTextStyles.value.fontSize!, pace * valueShareOfPace)))),
          const SizedBox(height: _gap),
          SizedBox(height: 48, child: _dim(_SideValues(tick: tick, rrIntervalMs: rrIntervalMs, session: session, card: true))),
          if (curve) ...[
            const SizedBox(height: _gap),
            SizedBox(height: 120, child: ForceCurve(last: forces)),
          ],
          const SizedBox(height: _gap),
          SizedBox(height: 56, child: action),
        ],
      ),
    );
  }

  Widget _landscape(BuildContext context, Size size) {
    const padding = EdgeInsets.symmetric(horizontal: AppSpacing.pageLandscape, vertical: AppSpacing.m);
    const sideHeight = 40.0;
    const cardPadding = AppSpacing.l;
    final inner = padding.deflateSize(size);
    final leftWidth = (inner.width - AppSpacing.l) * 9 / 16;
    final cardHeight = inner.height - sideHeight - _gap;
    final curve = ForceCurve.hasData(forces) && inner.height >= 300;
    final curveHeight = math.min(88.0, cardHeight * 0.3);
    final pace = paceFontSize(Size(
      leftWidth - 2 * cardPadding,
      cardHeight - 2 * cardPadding - _labelHeight - (curve ? curveHeight + AppSpacing.s : 0),
    ));
    return Padding(
      key: const ValueKey(LiveLayout.landscape),
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: leftWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: cardHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.cardLarge),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _dim(_pace(context, pace))),
                          if (curve) ...[
                            const SizedBox(height: AppSpacing.s),
                            SizedBox(
                              height: curveHeight,
                              child: ForceCurve(last: forces, variant: ForceCurveVariant.inline),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: _gap),
                SizedBox(height: sideHeight, child: _dim(_SideValues(tick: tick, rrIntervalMs: rrIntervalMs, session: session, card: false))),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _dim(_tiles(context, math.min(52, pace * valueShareOfPace)))),
                const SizedBox(height: _gap),
                SizedBox(height: 52, child: action),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dim(Widget child) => Opacity(opacity: outdated ? 0.4 : 1, child: child);

  Widget _pace(BuildContext context, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.metricPace.toUpperCase(),
          style: AppTextStyles.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Expanded(
          child: PaceText(text: formatPace(tick?.pace), fontSize: fontSize, textKey: const Key('metric-pace')),
        ),
      ],
    );
  }

  Widget _tiles(BuildContext context, double fontSize) {
    final l10n = context.l10n;
    final tick = this.tick;
    return TileGrid(
      columns: 2,
      children: [
        MetricTile(
          label: l10n.metricStrokeRate,
          value: formatWhole(tick?.strokeRate),
          unit: 'spm',
          valueKey: const Key('metric-spm'),
          fontSize: fontSize,
        ),
        MetricTile(
          label: l10n.metricWatts,
          value: formatWhole(tick?.watts),
          valueKey: const Key('metric-watts'),
          fontSize: fontSize,
        ),
        MetricTile(
          label: l10n.metricTime,
          value: formatElapsed(session?.elapsed ?? tick?.elapsed ?? Duration.zero),
          valueKey: const Key('metric-elapsed'),
          fontSize: fontSize,
        ),
        MetricTile(
          label: l10n.metricDistance,
          value: formatGrouped((session?.distanceMeters ?? tick?.distanceMeters ?? 0).floor()),
          unit: 'm',
          valueKey: const Key('metric-distance'),
          fontSize: fontSize,
        ),
      ],
    );
  }
}

/// The line below the tiles: heart rate (only with a monitor), calories and the average pace.
class _SideValues extends StatelessWidget {
  const _SideValues({required this.tick, required this.rrIntervalMs, required this.session, required this.card});

  final StatusTick? tick;
  final int? rrIntervalMs;
  final SessionProgress? session;

  /// On a card as in portrait, or plain as in landscape.
  final bool card;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tick = this.tick;
    final heartRate = tick?.heartRate;
    final calories = tick?.calories;
    final items = [
      if (heartRate != null)
        _item(
          l10n.metricHeartRate,
          formatWhole(heartRate),
          const Key('metric-hr'),
          icon: const HeartIcon(),
          note: rrIntervalMs == null ? null : formatRrInterval(rrIntervalMs!),
          noteKey: const Key('metric-rr'),
        ),
      if (calories != null) _item(l10n.metricCalories, formatWhole(calories), const Key('metric-calories')),
      _item(l10n.metricAveragePace, formatPace(_averagePace()), const Key('metric-average-pace')),
    ];
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final (i, item) in items.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpacing.m),
          Flexible(child: item),
        ],
      ],
    );
    if (!card) return Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs), child: row);
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.card)),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l), child: row),
    );
  }

  /// Per 500 m since the start; null before the first metre.
  Duration? _averagePace() {
    final distance = session?.distanceMeters ?? tick?.distanceMeters ?? 0;
    final elapsed = session?.elapsed ?? tick?.elapsed ?? Duration.zero;
    if (distance < 1) return null;
    return Duration(milliseconds: (elapsed.inMilliseconds * 500 / distance).round());
  }

  Widget _item(String label, String value, Key key, {Widget? icon, String? note, Key? noteKey}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon, const SizedBox(width: 6)],
          Text.rich(
            TextSpan(
              text: '$label ',
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            key: key,
            style: AppTextStyles.caption.copyWith(fontSize: 14, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          if (note != null) ...[
            const SizedBox(width: 6),
            Text(
              note,
              key: noteKey,
              style: AppTextStyles.caption.copyWith(fontSize: 12, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ],
      ),
    );
  }
}
