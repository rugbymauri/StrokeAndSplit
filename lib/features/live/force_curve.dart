import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../l10n/l10n.dart';

/// The force curve of the last stroke (ui-design, Design D2). The live display
/// keeps room for it; without data it is left out. The change `force-curve`
/// delivers the forces.
class ForceCurve extends StatelessWidget {
  const ForceCurve({super.key, required this.forces});

  /// Forces over the drive of the last stroke, in any unit; null without data.
  final List<double>? forces;

  /// Whether [forces] can be drawn.
  static bool hasData(List<double>? forces) => forces != null && forces.length > 1 && forces.any((f) => f > 0);

  @override
  Widget build(BuildContext context) {
    final forces = this.forces;
    if (forces == null || !hasData(forces)) return const SizedBox.shrink();
    return DecoratedBox(
      key: const Key('force-curve'),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.card)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.liveForceCurve, style: AppTextStyles.caption, maxLines: 1),
            const SizedBox(height: AppSpacing.s),
            Expanded(child: CustomPaint(painter: _CurvePainter(forces))),
          ],
        ),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  _CurvePainter(this.forces);

  final List<double> forces;

  @override
  void paint(Canvas canvas, Size size) {
    final peak = forces.reduce(math.max);
    final line = Path();
    for (final (i, force) in forces.indexed) {
      final point = Offset(size.width * i / (forces.length - 1), size.height * (1 - force.clamp(0, peak) / peak));
      i == 0 ? line.moveTo(point.dx, point.dy) : line.lineTo(point.dx, point.dy);
    }
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = AppColors.zoneIn.withValues(alpha: 0.16));
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.zoneIn
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CurvePainter oldDelegate) => oldDelegate.forces != forces;
}
