import 'package:flutter/painting.dart';

import '../data/courses/zone_intensity.dart';

/// The colours of the app's dark design (design D1 of the change `ui-design`).
abstract final class AppColors {
  /// Background of the screens.
  static const bg = Color(0xFF0E1114);

  /// Cards and tiles.
  static const surface = Color(0xFF161B20);

  /// Borders, dividers and free segments.
  static const line = Color(0xFF2A3138);

  /// Empty progress track.
  static const track = Color(0xFF242B32);

  /// Empty inner progress track (segment), tinted blue.
  static const trackInner = Color(0xFF1B3550);

  /// Empty part of a zone on the lap track, brighter than [track].
  static const trackZone = Color(0xFF3E4A56);

  /// Text and numbers.
  static const text = Color(0xFFE8ECEF);

  /// Labels.
  static const textMuted = Color(0xFF9AA4AD);

  /// In the zone, and segments with a band.
  static const zoneIn = Color(0xFF5AB0FF);

  /// Card in the zone.
  static const zoneInSurface = Color(0xFF0F2438);

  /// Text in the zone.
  static const zoneInText = Color(0xFFA9D3FF);

  /// Out of the zone, errors and deleting.
  static const zoneOut = Color(0xFFFF9A3D);

  /// Card out of the zone.
  static const zoneOutSurface = Color(0xFF33200F);

  /// Text out of the zone.
  static const zoneOutText = Color(0xFFFFC58F);

  /// An easy zone in course bars and the zone list, muted so it does not
  /// read as [connected].
  static const intensityEasy = Color(0xFF2F8F5B);

  /// A medium zone, darker than [zoneOut] so it does not read as a warning.
  static const intensityMedium = Color(0xFFB97A2E);

  /// A hard zone.
  static const intensityHard = Color(0xFFB8443F);

  /// The force curve of the previous stroke, behind the last one.
  static const previousCurve = Color(0xFF5A646E);

  /// The ghost.
  static const ghost = Color(0xFFC9B6FF);

  /// The dot of a connected erg in the live display's app bar.
  static const connected = Color(0xFF4CD07D);
}

/// The colour of a zone of [intensity] wherever zones are shown, in course
/// bars and live (change `live-zone-targets`, Design D1); a free segment is
/// [AppColors.line].
Color intensityColor(ZoneIntensity? intensity) => switch (intensity) {
  null => AppColors.line,
  ZoneIntensity.easy => AppColors.intensityEasy,
  ZoneIntensity.medium => AppColors.intensityMedium,
  ZoneIntensity.hard => AppColors.intensityHard,
};

/// How strongly the not yet rowed part of a zone shows its colour.
const intensityDimAlpha = 0.45;

/// [color] muted for the part of a zone not rowed yet.
Color intensityDim(Color color) => color.withValues(alpha: intensityDimAlpha);

/// Dark or light text, whichever reads better on [background] (as
/// `ThemeData.estimateBrightnessForColor`).
Color textOn(Color background) {
  final luminance = background.computeLuminance();
  return (luminance + 0.05) * (luminance + 0.05) > 0.15
      ? AppColors.bg
      : AppColors.text;
}

/// The bundled font families (design D1).
abstract final class AppFonts {
  /// Barlow Condensed in weight 700: the values outside the live display and the titles.
  static const display = 'Barlow Condensed';

  /// Barlow in weight 700, wider and so lower than [display] at the same width: the values of the
  /// live display, which leaves more room for the cards around them.
  static const liveValue = 'Barlow';

  /// IBM Plex Sans in weights 400, 500 and 600: all other text.
  static const text = 'IBM Plex Sans';
}

/// Text styles of the canvas screens (design D1). Without a colour they take it
/// from the surrounding text.
abstract final class AppTextStyles {
  /// The pace, always the largest value.
  static const pace = TextStyle(
    fontFamily: AppFonts.liveValue,
    fontSize: 128,
    fontWeight: FontWeight.w700,
    height: 1,
  );

  /// A value in a tile, e.g. stroke rate or watts, at most; it shrinks to fit its tile.
  static const value = TextStyle(
    fontFamily: AppFonts.liveValue,
    fontSize: 112,
    fontWeight: FontWeight.w700,
    height: 1,
  );

  /// The unit after a [value], e.g. "spm".
  static const valueUnit = TextStyle(
    fontFamily: AppFonts.liveValue,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  /// The app's name on the start screen.
  static const appTitle = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: 40 * 0.02,
  );

  /// The title of a screen.
  static const screenTitle = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 30,
    fontWeight: FontWeight.w700,
  );

  /// A label above values or a section; the text itself is written in capitals.
  static const label = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 13 * 0.08,
    color: AppColors.textMuted,
  );

  /// The name of a tile above its value, and small notes.
  static const caption = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 13,
    color: AppColors.textMuted,
  );

  /// The title of a card or list entry.
  static const cardTitle = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  static const body = TextStyle(fontFamily: AppFonts.text, fontSize: 15);

  /// The line below a [cardTitle].
  static const subtitle = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 14,
    color: AppColors.textMuted,
  );

  /// A secondary button, e.g. "Frei rudern".
  static const button = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  /// The primary button, e.g. "Session beenden".
  static const primaryButton = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
}

/// Corner radii (design D1).
abstract final class AppRadii {
  /// Cards, tiles and buttons.
  static const card = 14.0;

  /// Workout cards and the primary button at the bottom of a screen.
  static const cardLarge = 16.0;

  /// The pace box with the progress frame.
  static const paceBox = 28.0;

  /// Small buttons, input fields and the tab bar.
  static const small = 12.0;
}

/// Spacing in steps of 4 px (design D1).
abstract final class AppSpacing {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;

  /// Side margin in portrait, clear of the camera notch.
  static const pagePortrait = 20.0;

  /// Side margin in landscape, clear of the notch and the gesture bar.
  static const pageLandscape = 48.0;
}
