import 'package:flutter/painting.dart';

import '../../app/design_tokens.dart';

/// The small names above the values of the live display: subdued, so the values get the room.
abstract final class LiveTextStyles {
  /// A heading in capitals, e.g. "PACE /500 M" or "SCHLAGZAHL".
  static const label = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 11 * 0.08,
    color: AppColors.textMuted,
  );

  /// The name of a tile above its value, e.g. "Watt", or the title of the force curve.
  static const caption = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 11,
    color: AppColors.textMuted,
  );

  /// The name of a small tile in a row of four.
  static const captionCompact = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 10,
    color: AppColors.textMuted,
  );
}
