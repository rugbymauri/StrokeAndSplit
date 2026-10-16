import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// The dark theme of the app, built from the tokens of design D1.
///
/// The primary colour is blue ([AppColors.zoneIn]), also for the filled button.
ThemeData appTheme() {
  const colors = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.zoneIn,
    onPrimary: AppColors.bg,
    primaryContainer: AppColors.zoneInSurface,
    onPrimaryContainer: AppColors.zoneInText,
    secondary: AppColors.textMuted,
    onSecondary: AppColors.bg,
    secondaryContainer: AppColors.line,
    onSecondaryContainer: AppColors.text,
    tertiary: AppColors.textMuted,
    onTertiary: AppColors.bg,
    tertiaryContainer: AppColors.line,
    onTertiaryContainer: AppColors.text,
    error: AppColors.zoneOut,
    onError: AppColors.bg,
    errorContainer: AppColors.zoneOutSurface,
    onErrorContainer: AppColors.zoneOutText,
    surface: AppColors.bg,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textMuted,
    surfaceContainerLowest: AppColors.bg,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surface,
    surfaceContainerHighest: AppColors.line,
    outline: AppColors.line,
    outlineVariant: AppColors.line,
    inverseSurface: AppColors.text,
    onInverseSurface: AppColors.bg,
    inversePrimary: AppColors.zoneInSurface,
    surfaceTint: Colors.transparent,
    shadow: Colors.black,
    scrim: Colors.black,
  );
  final base = ThemeData(colorScheme: colors, fontFamily: AppFonts.text);
  const cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)));
  const smallShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadii.small)));
  const fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.small)),
    borderSide: BorderSide(color: AppColors.line),
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.bg,
    dividerColor: AppColors.line,
    textTheme: _textTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: AppTextStyles.screenTitle.copyWith(color: AppColors.text),
      // Icons in the app bar, e.g. the language choice (design D8).
      actionsIconTheme: const IconThemeData(color: AppColors.textMuted),
    ),
    cardTheme: const CardThemeData(color: AppColors.surface, elevation: 0, shape: cardShape),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadii.cardLarge))),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
    listTileTheme: const ListTileThemeData(iconColor: AppColors.textMuted),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.zoneIn,
        foregroundColor: AppColors.bg,
        shape: cardShape,
        textStyle: AppTextStyles.button.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.line),
        shape: cardShape,
        textStyle: AppTextStyles.button,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        side: const BorderSide(color: AppColors.line),
        shape: cardShape,
        textStyle: AppTextStyles.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.zoneIn, shape: smallShape),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.small)),
        borderSide: BorderSide(color: AppColors.text, width: 2),
      ),
    ),
    // Segmented tabs as in the canvas: the chosen tab on a lighter pill.
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.text,
      unselectedLabelColor: AppColors.textMuted,
      labelStyle: AppTextStyles.button.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      unselectedLabelStyle: AppTextStyles.button.copyWith(fontSize: 15),
      indicator: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(AppRadii.small - 3)),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerHeight: 0,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      splashBorderRadius: BorderRadius.circular(AppRadii.small - 3),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.text, linearTrackColor: AppColors.track),
  );
}

/// Barlow Condensed for the large styles that show values, IBM Plex Sans (from
/// the base) for the rest.
TextTheme _textTheme(TextTheme base) {
  TextStyle? display(TextStyle? style) =>
      style?.copyWith(fontFamily: AppFonts.display, fontWeight: FontWeight.w700);
  return base.copyWith(
    displayLarge: display(base.displayLarge),
    displayMedium: display(base.displayMedium),
    displaySmall: display(base.displaySmall),
    headlineLarge: display(base.headlineLarge),
    headlineMedium: display(base.headlineMedium),
    headlineSmall: display(base.headlineSmall),
  );
}
