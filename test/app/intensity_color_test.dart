import 'package:strokesplit/app/design_tokens.dart';
import 'package:strokesplit/data/courses/zone_intensity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The colours of zones, shared by course bars and the live display (change
/// live-zone-targets, Design D1).
void main() {
  test('maps free and each intensity to its colour', () {
    expect(
      [
        intensityColor(null),
        for (final i in ZoneIntensity.values) intensityColor(i),
      ],
      [
        AppColors.line,
        AppColors.intensityEasy,
        AppColors.intensityMedium,
        AppColors.intensityHard,
      ],
    );
  });

  test('dims a colour by lowering only its opacity', () {
    final dim = intensityDim(AppColors.intensityHard);

    expect(dim.withValues(alpha: 1), AppColors.intensityHard);
    expect(dim.a, lessThan(AppColors.intensityHard.a));
  });

  test('picks text like ThemeData.estimateBrightnessForColor', () {
    for (final color in [
      AppColors.bg,
      AppColors.line,
      AppColors.intensityEasy,
      AppColors.intensityMedium,
      AppColors.intensityHard,
      AppColors.upcoming,
      AppColors.text,
    ]) {
      expect(
        textOn(color),
        ThemeData.estimateBrightnessForColor(color) == Brightness.light
            ? AppColors.bg
            : AppColors.text,
        reason: '$color',
      );
    }
  });
}
