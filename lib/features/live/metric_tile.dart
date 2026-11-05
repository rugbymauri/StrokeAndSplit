import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/oar_stepper.dart';
import 'live_text_styles.dart';

/// Values in tiles stay at most this share of the pace, so the pace is
/// always the largest value (ui-design, Design D2), but close to it.
const valueShareOfPace = 0.9;

/// The font size at which the pace fills [area], at most that of [AppTextStyles.pace].
/// Measured on a fixed text, so the size does not jump with the digits.
double paceFontSize(Size area) {
  final painter = TextPainter(
    text: const TextSpan(text: '0:00.0', style: AppTextStyles.pace),
    textDirection: TextDirection.ltr,
  )..layout();
  final width = painter.width;
  painter.dispose();
  final largest = AppTextStyles.pace.fontSize!;
  return math.max(0, math.min(largest, math.min(largest * area.width / width, area.height)));
}

/// The pace as the largest value, in [fontSize] from [paceFontSize].
class PaceText extends StatelessWidget {
  const PaceText({super.key, required this.text, required this.fontSize, this.textKey});

  final String text;
  final double fontSize;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          key: textKey,
          style: AppTextStyles.pace.copyWith(
            fontSize: fontSize,
            color: AppColors.text,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Oar blade buttons around the footnote of a [MetricTile], e.g. to change
/// the resistance level below the watts (Change resistance-control, D6).
class TileStepper {
  const TileStepper({
    required this.lowerLabel,
    required this.raiseLabel,
    this.onLower,
    this.onRaise,
    this.lowerKey,
    this.raiseKey,
  });

  final String lowerLabel;
  final String raiseLabel;

  /// Null at the limit, which disables the button.
  final VoidCallback? onLower;
  final VoidCallback? onRaise;

  final Key? lowerKey;
  final Key? raiseKey;
}

/// A tile with a name above a value, e.g. "Watt 172"; the value shrinks to fit.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.valueKey,
    required this.fontSize,
    this.unit,
    this.icon,
    this.footnote,
    this.footnoteKey,
    this.stepper,
    this.compact = false,
  });

  final String label;
  final String value;
  final Key valueKey;

  /// At most; the value shrinks if the tile is too small.
  final double fontSize;

  /// After the value, e.g. "spm".
  final String? unit;

  /// Before the label, e.g. the heart for the heart rate.
  final Widget? icon;

  /// Small text below the value, e.g. the last RR interval below the heart rate.
  final String? footnote;
  final Key? footnoteKey;

  /// Buttons beside the footnote; in a low tile they go left and right of
  /// the whole content instead.
  final TileStepper? stepper;

  /// Tiles at least this high take the buttons in the footnote line.
  static const stepperLineMinHeight = 120.0;

  /// Size of the oar blade buttons, at least 44 × 47 to hit while rowing.
  static const stepperButton = Size(44, 47);

  /// Small tiles in a row, as next to the pace box.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final stepper = this.stepper;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs)
        : const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(compact ? AppRadii.small : AppRadii.card),
      ),
      child: stepper == null
          ? Padding(padding: padding, child: _content(_footnote()))
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxHeight >= stepperLineMinHeight) {
                  // The buttons reach closer to the edge than the values, so
                  // the footnote keeps room between them in narrow tiles.
                  final inset = padding.left - AppSpacing.xs;
                  return Padding(
                    padding: padding.copyWith(left: AppSpacing.xs, right: AppSpacing.xs),
                    child: _content(
                      Row(
                        children: [
                          _button(stepper, up: false),
                          Expanded(
                            child: Center(
                              child: FittedBox(fit: BoxFit.scaleDown, child: _footnote()),
                            ),
                          ),
                          _button(stepper, up: true),
                        ],
                      ),
                      inset: inset,
                    ),
                  );
                }
                return Row(
                  children: [
                    _button(stepper, up: false),
                    Expanded(
                      child: Padding(
                        padding: padding.copyWith(left: AppSpacing.xs, right: AppSpacing.xs),
                        child: _content(_footnote()),
                      ),
                    ),
                    _button(stepper, up: true),
                  ],
                );
              },
            ),
    );
  }

  Widget _button(TileStepper stepper, {required bool up}) => OarBladeButton(
    key: up ? stepper.raiseKey : stepper.lowerKey,
    up: up,
    size: stepperButton,
    label: up ? stepper.raiseLabel : stepper.lowerLabel,
    onStep: up ? stepper.onRaise : stepper.onLower,
  );

  Widget? _footnote() {
    final footnote = this.footnote;
    if (footnote == null) return null;
    return Text(
      footnote,
      key: footnoteKey,
      style: AppTextStyles.caption.copyWith(
        fontSize: compact ? 11 : 12,
        height: 1.1,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Label and value above [footer]; [inset] moves them in from the sides.
  Widget _content(Widget? footer, {double inset = 0}) {
    final unit = this.unit;
    final icon = this.icon;
    final sides = EdgeInsets.symmetric(horizontal: inset);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: sides,
          child: Row(
            children: [
              if (icon != null) ...[icon, const SizedBox(width: AppSpacing.xs)],
              Flexible(
                child: Text(
                  label,
                  style: compact ? LiveTextStyles.captionCompact : LiveTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: Padding(
            padding: sides,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  text: value,
                  children: [
                    if (unit != null)
                      TextSpan(
                        text: ' $unit',
                        style: AppTextStyles.valueUnit.copyWith(fontSize: fontSize * 0.36),
                      ),
                  ],
                ),
                key: valueKey,
                style: AppTextStyles.value.copyWith(
                  fontSize: fontSize,
                  height: 1,
                  color: AppColors.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
        ?footer,
      ],
    );
  }
}

/// [children] in rows of [columns], filling the space evenly.
class TileGrid extends StatelessWidget {
  const TileGrid({super.key, required this.columns, required this.children, this.gap = AppSpacing.m});

  final int columns;
  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <List<Widget>>[
      for (var i = 0; i < children.length; i += columns) children.sublist(i, math.min(i + columns, children.length)),
    ];
    return Column(
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0) SizedBox(height: gap),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < columns; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  Expanded(child: i < row.length ? row[i] : const SizedBox.shrink()),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The heart in front of the heart rate.
class HeartIcon extends StatelessWidget {
  const HeartIcon({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) => Icon(Icons.favorite, size: size, color: AppColors.zoneOut);
}
