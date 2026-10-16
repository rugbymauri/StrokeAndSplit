import 'package:flutter/painting.dart';

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

  /// Text, numbers and the primary button.
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

  /// The ghost.
  static const ghost = Color(0xFFC9B6FF);
}
