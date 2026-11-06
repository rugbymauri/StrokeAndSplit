import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../l10n/l10n.dart';

/// Tells the rower that the session is paused because they stopped rowing
/// (Change auto-pause, Design D4); large, so it reads from the seat.
class PauseHint extends StatelessWidget {
  const PauseHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('pause-hint'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.s,
        AppSpacing.l,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: AppColors.zoneOutSurface,
        border: Border.all(color: AppColors.zoneOut),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.pause_circle,
            color: AppColors.zoneOutText,
            size: 36,
          ),
          const SizedBox(width: AppSpacing.m),
          Flexible(
            child: Text(
              context.l10n.livePaused,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: AppColors.zoneOutText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
