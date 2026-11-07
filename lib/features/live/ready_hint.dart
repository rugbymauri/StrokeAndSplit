import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../l10n/l10n.dart';

/// Tells the rower that a workout session waits for the first stroke
/// (start-on-first-stroke, Design D5); readable from the seat.
class ReadyHint extends StatelessWidget {
  const ReadyHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('ready-hint'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.s,
        AppSpacing.l,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.m,
      ),
      decoration: BoxDecoration(
        color: AppColors.zoneInSurface,
        border: Border.all(color: AppColors.zoneIn),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: [
          const Icon(Icons.rowing, color: AppColors.zoneInText),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Text(
              context.l10n.liveReadyForFirstStroke,
              style: AppTextStyles.primaryButton.copyWith(
                color: AppColors.zoneInText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
