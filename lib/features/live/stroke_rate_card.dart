import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../data/courses/course.dart';
import '../../data/courses/lap_tracker.dart';
import '../../l10n/l10n.dart';
import 'formatters.dart';
import 'live_text_styles.dart';
import 'upcoming_zone.dart';
import 'zone_hint.dart';

/// The stroke rate while rowing a template, coloured by its zone status and
/// with the band of the segment (ui-design, Design D2 and D3).
class StrokeRateCard extends StatelessWidget {
  const StrokeRateCard({
    super.key,
    required this.strokeRate,
    required this.status,
    required this.segment,
    required this.fontSize,
    this.landscape = false,
    this.footer,
    this.upcoming,
  });

  final int? strokeRate;
  final BandStatus status;
  final CourseSegment segment;

  /// Of the value at most; it shrinks if the card is too small.
  final double fontSize;

  /// Value below the label as in the landscape canvas, else beside it.
  final bool landscape;

  /// Builds what goes below the value in landscape, e.g. the force curve, in the colour of the label.
  final Widget Function(Color foreground)? footer;

  /// The zone that starts in a few seconds; its stroke rate band blinks in place of the zone status.
  final CourseSegment? upcoming;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hint = ZoneHint.strokeRate(l10n, this.status);
    final (background, border, foreground) = switch (hint) {
      // A quiet frame without a band, so the card stands out against the background like the pace box.
      null => (AppColors.surface, AppColors.trackZone, AppColors.textMuted),
      ZoneHint(inZone: true) => (
        AppColors.zoneInSurface,
        AppColors.zoneIn,
        AppColors.zoneInText,
      ),
      ZoneHint(inZone: false) => (
        AppColors.zoneOutSurface,
        AppColors.zoneOut,
        AppColors.zoneOutText,
      ),
    };
    final band = segment.hasSpmBand
        ? '${segment.spmMin}–${segment.spmMax} spm'
        : null;
    final label = Text(
      l10n.metricStrokeRate.toUpperCase(),
      style: LiveTextStyles.label.copyWith(color: foreground),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    // In the zone a quiet line; out of it an instruction as a pill like in the pace box, which stands out
    // and keeps its words, on a line of its own below the label (Design D3).
    final upcoming = this.upcoming;
    final Widget? status = switch (hint) {
      _ when upcoming != null && upcoming.hasSpmBand => UpcomingPill(
        key: const Key('stroke-card-upcoming'),
        text: l10n.hintUpcoming('${upcoming.spmMin}–${upcoming.spmMax} spm'),
        textKey: const Key('stroke-card-upcoming-band'),
        // Band and unit belong together, so it shrinks rather than wrapping in a narrow card.
        scaleDown: true,
        dense: true,
      ),
      null => null,
      ZoneHint(inZone: true) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hint.icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              band == null || landscape ? hint.text : '${hint.text} · $band',
              key: const Key('stroke-card-status'),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      ZoneHint(inZone: false) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZonePill(
            key: const Key('stroke-card-pill'),
            hint: hint,
            textKey: const Key('stroke-card-status'),
            filled: true,
            // Below the label there is no room for a second line in portrait, while the landscape
            // card can be too narrow for one.
            scaleDown: !landscape,
            maxLines: landscape ? 2 : 1,
            dense: true,
          ),
          // The pill is too narrow for the band beside the word; in landscape it is beside the value.
          if (band != null && !landscape) ...[
            const SizedBox(height: 2),
            Text(
              band,
              key: const Key('stroke-card-band'),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    };
    final value = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(
          text: formatWhole(strokeRate),
          children: [
            TextSpan(
              text: landscape && band != null ? ' $band' : ' spm',
              // In proportion to the value; the band in landscape is longer, so a little smaller.
              style: AppTextStyles.caption.copyWith(
                fontSize: fontSize * (landscape ? 0.3 : 0.36),
                color: foreground,
              ),
            ),
          ],
        ),
        key: const Key('metric-spm'),
        style: AppTextStyles.value.copyWith(
          fontSize: fontSize,
          color: AppColors.text,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
    final footer = this.footer;
    return DecoratedBox(
      key: hint == null
          ? null
          : Key('stroke-card-zone-${hint.inZone ? 'in' : 'out'}'),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          landscape ? AppRadii.cardLarge : AppRadii.card,
        ),
        border: Border.all(color: border, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: AppSpacing.s,
        ),
        child: landscape
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The upcoming band gets a line of its own like an instruction, so it keeps its words.
                  if ((hint == null || hint.inZone) && status is! UpcomingPill)
                    Row(
                      children: [
                        Expanded(child: label),
                        if (status != null) Flexible(child: status),
                      ],
                    )
                  else ...[
                    label,
                    const SizedBox(height: 6),
                    status!,
                  ],
                  Flexible(flex: 2, child: Center(child: value)),
                  if (footer != null)
                    Expanded(flex: 3, child: footer(foreground)),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label,
                        if (status != null) ...[
                          SizedBox(
                            height:
                                hint != null &&
                                    hint.inZone &&
                                    status is! UpcomingPill
                                ? 2
                                : AppSpacing.xs,
                          ),
                          status,
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  value,
                ],
              ),
      ),
    );
  }
}
