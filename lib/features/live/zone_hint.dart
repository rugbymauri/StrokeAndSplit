import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../data/courses/lap_tracker.dart';
import '../../l10n/l10n.dart';

/// How a zone is shown on a value: colour, symbol and a word, so it does
/// not depend on colour alone.
class ZoneHint {
  const ZoneHint({required this.inZone, required this.icon, required this.text});

  final bool inZone;
  final IconData icon;
  final String text;

  /// For the pace; null without a pace band.
  static ZoneHint? pace(AppLocalizations l10n, BandStatus? status) => switch (status) {
        null || BandStatus.none => null,
        BandStatus.inBand => ZoneHint(inZone: true, icon: Icons.check_circle, text: l10n.hintInZone),
        BandStatus.above => ZoneHint(inZone: false, icon: Icons.arrow_upward, text: l10n.hintFaster),
        BandStatus.below => ZoneHint(inZone: false, icon: Icons.arrow_downward, text: l10n.hintSlower),
        BandStatus.missing => ZoneHint(inZone: false, icon: Icons.pause, text: l10n.hintNoPace),
      };

  /// For the stroke rate; null without a stroke rate band.
  static ZoneHint? strokeRate(AppLocalizations l10n, BandStatus? status) => switch (status) {
        null || BandStatus.none => null,
        BandStatus.inBand => ZoneHint(inZone: true, icon: Icons.check_circle, text: l10n.hintInZone),
        BandStatus.below => ZoneHint(inZone: false, icon: Icons.arrow_upward, text: l10n.hintMoreStrokes),
        BandStatus.above => ZoneHint(inZone: false, icon: Icons.arrow_downward, text: l10n.hintFewerStrokes),
        BandStatus.missing => ZoneHint(inZone: false, icon: Icons.pause, text: l10n.hintNoStrokes),
      };
}

/// A [ZoneHint] as a pill: symbol and word, with the band if there is one, e.g. `↑ Schneller · 2:05–2:10`
/// in the pace box or `↑ Mehr Schläge` on the stroke rate card (ui-design, Design D3).
class ZonePill extends StatelessWidget {
  const ZonePill({
    super.key,
    required this.hint,
    this.band,
    this.textKey,
    this.filled = false,
    this.scaleDown = false,
    this.dense = false,
    this.maxLines = 1,
  });

  /// Round at the ends of a pill of up to twice this height.
  static const radius = 16.0;

  final ZoneHint hint;
  final String? band;
  final Key? textKey;

  /// In the full zone colour with dark text, so it stands out on a card already tinted in the zone colour.
  final bool filled;

  /// Shrinks the text to fit instead of cutting it off, so an instruction stays complete.
  final bool scaleDown;

  /// With less room around symbol and word, for a narrow card.
  final bool dense;

  /// Lines the word may wrap to when it is too wide.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch ((hint.inZone, filled)) {
      (true, false) => (AppColors.zoneInSurface, AppColors.zoneInText),
      (false, false) => (AppColors.zoneOutSurface, AppColors.zoneOutText),
      (true, true) => (AppColors.zoneIn, AppColors.bg),
      (false, true) => (AppColors.zoneOut, AppColors.bg),
    };
    final band = this.band;
    final text = Text(
      band == null ? hint.text : '${hint.text} · $band',
      key: textKey,
      style: AppTextStyles.button.copyWith(color: foreground, fontWeight: filled ? FontWeight.w600 : null),
      maxLines: maxLines,
      overflow: scaleDown ? null : TextOverflow.ellipsis,
    );
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dense ? AppSpacing.s : AppSpacing.m),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(hint.icon, size: 18, color: foreground),
            SizedBox(width: dense ? AppSpacing.xs : AppSpacing.s),
            Flexible(child: scaleDown ? FittedBox(fit: BoxFit.scaleDown, child: text) : text),
          ],
        ),
      ),
    );
  }
}
