import 'package:flutter/widgets.dart';

import '../../l10n/l10n.dart';
import '../design_tokens.dart';

/// The ghost as a small rhombus, the same shape as the ghost's boat in the
/// progress frame, for the legend of the pace box and the template choice
/// (Change ghost, Design D1).
class GhostSymbol extends StatelessWidget {
  const GhostSymbol({super.key, this.rimColor = AppColors.surface});

  /// Width of the symbol.
  static const width = 10.0;

  /// Height of the symbol.
  static const height = 4.0;

  /// Width of the rim.
  static const rim = 1.0;

  /// The colour of the surface the symbol lies on.
  final Color rimColor;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.ghostSymbolLabel,
    image: true,
    child: CustomPaint(
      size: const Size(width, height),
      painter: _GhostSymbolPainter(rimColor),
    ),
  );
}

class _GhostSymbolPainter extends CustomPainter {
  const _GhostSymbolPainter(this.rimColor);

  final Color rimColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rhombus = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas
      ..drawPath(rhombus, Paint()..color = AppColors.ghost)
      ..drawPath(
        rhombus,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = GhostSymbol.rim
          ..strokeJoin = StrokeJoin.miter
          ..color = rimColor,
      );
  }

  @override
  bool shouldRepaint(_GhostSymbolPainter oldDelegate) =>
      oldDelegate.rimColor != rimColor;
}
