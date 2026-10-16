import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';

/// A card to tap with icon, title and a line below, as in the canvas "Start".
///
/// With [selected] it is one of several options and shows a radio mark,
/// otherwise a chevron. [detail] adds a line below the subtitle.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selected,
    this.detail,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool? selected;
  final Widget? detail;

  @override
  Widget build(BuildContext context) {
    final selected = this.selected;
    final highlighted = selected ?? false;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: selected != null,
      button: true,
      child: Material(
        color: highlighted ? AppColors.zoneInSurface : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: highlighted ? AppColors.zoneIn : AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Row(
                children: [
                  Icon(icon, size: 28, color: highlighted ? AppColors.zoneIn : AppColors.textMuted),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: AppTextStyles.cardTitle),
                        const SizedBox(height: 2),
                        Text(subtitle, style: AppTextStyles.subtitle),
                        if (detail case final detail?) ...[const SizedBox(height: AppSpacing.xs), detail],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  switch (selected) {
                    true => const Icon(Icons.radio_button_checked, color: AppColors.zoneIn),
                    false => const Icon(Icons.radio_button_unchecked, color: AppColors.textMuted),
                    null => const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The label above a section, in capitals (design D1).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Row(
        children: [
          Expanded(child: Text(text.toUpperCase(), style: AppTextStyles.label)),
          ?trailing,
        ],
      ),
    );
  }
}
