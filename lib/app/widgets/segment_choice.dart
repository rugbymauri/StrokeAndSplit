import 'package:flutter/material.dart';

import '../design_tokens.dart';

/// One of a few [options] side by side, the chosen one [value] filled, as in
/// the workout editor (laps) and on the start screen of a course.
class SegmentChoice<T> extends StatelessWidget {
  const SegmentChoice({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  /// Each value with its text, in order.
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(T option, String text) {
      final selected = option == value;
      return Expanded(
        child: Semantics(
          inMutuallyExclusiveGroup: true,
          checked: selected,
          child: Material(
            color: selected ? AppColors.line : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => onChanged(option),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Center(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? AppColors.text : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (final (i, (value, text)) in options.indexed) ...[
              if (i > 0) const SizedBox(width: 4),
              option(value, text),
            ],
          ],
        ),
      ),
    );
  }
}
