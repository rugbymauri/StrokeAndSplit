import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../design_tokens.dart';
import 'ghost_symbol.dart';

/// The ghost symbol, the text and a switch in one row that reacts to a tap
/// anywhere on it, above "Starten" on the screens of a template and of a
/// course (template-screen, Design D5; course-rowing-free, Design D6).
class GhostSwitch extends StatelessWidget {
  const GhostSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.small),
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              const ExcludeSemantics(
                child: GhostSymbol(rimColor: AppColors.bg),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Text(
                  context.l10n.templateGhost,
                  style: AppTextStyles.body,
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
