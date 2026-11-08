import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/oar_stepper.dart';
import '../../data/sessions/resistance_providers.dart';
import '../../l10n/l10n.dart';
import 'live_text_styles.dart';

/// The resistance level below the stroke rate card in landscape, as wide as it, with oar blade
/// buttons left and right that lower and raise it by one level (live-zone-targets, Design D7).
///
/// Nothing at all while the rower reports no level, so the stroke rate card keeps the height.
class ResistanceCard extends ConsumerWidget {
  const ResistanceCard({super.key, required this.tick, this.fontSize = 40});

  final StatusTick? tick;

  /// At most, like the values of the tiles, so the pace stays the largest value; it shrinks to fit.
  final double fontSize;

  /// The height of the card, enough for the 56 × 60 buttons.
  static const height = 72.0;

  /// The space above the card, as between the other parts of the column.
  static const gap = 6.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final resistance = ref.watch(resistanceProvider);
    final level = resistance.level ?? tick?.resistanceLevel;
    if (level == null) return const SizedBox.shrink();
    final controller = ref.read(resistanceProvider.notifier);
    final button = OarStepperSize.large.button;
    final value = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.zoneResistanceLevel.toUpperCase(),
          style: LiveTextStyles.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              resistance.refused ? l10n.metricResistanceRefused : '$level',
              key: const Key('resistance-card-level'),
              style: resistance.refused
                  ? AppTextStyles.body.copyWith(color: AppColors.zoneOut)
                  : AppTextStyles.value.copyWith(
                      fontSize: fontSize,
                      height: 1,
                      color: AppColors.text,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
            ),
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(top: gap),
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          key: const Key('resistance-card'),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.cardLarge),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
            child: Row(
              children: [
                if (resistance.canSet)
                  OarBladeButton(
                    key: const Key('resistance-card-lower'),
                    up: false,
                    size: button,
                    label: l10n.resistanceLower,
                    onStep: resistance.canLower
                        ? () => controller.step(-1)
                        : null,
                  ),
                Expanded(child: value),
                if (resistance.canSet)
                  OarBladeButton(
                    key: const Key('resistance-card-raise'),
                    up: true,
                    size: button,
                    label: l10n.resistanceRaise,
                    onStep: resistance.canRaise
                        ? () => controller.step(1)
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
