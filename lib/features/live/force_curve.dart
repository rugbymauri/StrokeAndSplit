import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../l10n/l10n.dart';
import 'formatters.dart';

/// Where the force curve sits in the live display (force-curve, Design D2 and the table in its context).
enum ForceCurveVariant {
  /// Its own card with title and legend, below the side values (portrait, free rowing).
  card,

  /// A narrow strip labelled "Kraft" below the tiles (portrait, template).
  strip,

  /// Below the pace, inside the pace card, without a frame of its own (landscape, free rowing).
  inline,

  /// Inside the coloured stroke rate card, drawn in `text` (landscape, template).
  tinted,
}

/// The force curves of the last and the previous stroke (force-curve, Design D2 and D3), with the
/// drive length of the last stroke (Design D4).
///
/// Before the first curve has arrived it shows a dashed baseline and "Warte auf ersten Schlag";
/// the layout leaves it out altogether for a source without force curves.
class ForceCurve extends StatelessWidget {
  const ForceCurve({
    super.key,
    required this.last,
    this.previous,
    this.driveLengthMeters,
    this.variant = ForceCurveVariant.card,
    this.foreground = AppColors.textMuted,
  });

  /// Forces over the drive of the last stroke, in Newton; null before the first curve.
  final List<double>? last;

  /// Forces over the drive of the stroke before, on the same scale; null without one.
  final List<double>? previous;

  /// The drive length of the last stroke in meters; null or 0 without one, and then not shown.
  final double? driveLengthMeters;

  final ForceCurveVariant variant;

  /// The colour of the title and notes in [ForceCurveVariant.tinted], e.g. that of the stroke rate card's label.
  final Color foreground;

  /// Whether [forces] can be drawn.
  static bool hasData(List<double>? forces) => forces != null && forces.length > 1 && forces.any((f) => f > 0);

  bool get _waiting => !hasData(last);

  @override
  Widget build(BuildContext context) {
    final curve = _curve();
    return switch (variant) {
      ForceCurveVariant.card => _framed(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cardHeader(context),
              const SizedBox(height: AppSpacing.s),
              Expanded(child: curve),
            ],
          ),
        ),
      ForceCurveVariant.strip => _framed(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.s),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Text(context.l10n.liveForceCurveShort, style: _small, maxLines: 1)),
              const SizedBox(width: AppSpacing.m),
              Expanded(child: _withNote(context, curve)),
            ],
          ),
        ),
      ForceCurveVariant.inline => KeyedSubtree(key: const Key('force-curve'), child: _withNote(context, curve)),
      ForceCurveVariant.tinted => Column(
          key: const Key('force-curve'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.liveForceCurve,
                    style: _small.copyWith(color: foreground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_note(context) case final note?)
                  Expanded(child: Align(alignment: Alignment.centerRight, child: note)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(child: curve),
          ],
        ),
    };
  }

  static const _small = TextStyle(fontFamily: AppFonts.text, fontSize: 12, color: AppColors.textMuted);

  Widget _framed({required EdgeInsets padding, required Widget child}) => DecoratedBox(
        key: const Key('force-curve'),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.card)),
        child: Padding(padding: padding, child: child),
      );

  Widget _curve() {
    final tinted = variant == ForceCurveVariant.tinted;
    return CustomPaint(
      size: Size.infinite,
      painter: _waiting
          ? const _BaselinePainter()
          : _CurvePainter(
              last: last!,
              previous: hasData(previous) ? previous : null,
              color: tinted ? AppColors.text : AppColors.zoneIn,
              fillOpacity: tinted ? 0.12 : 0.16,
              previousColor: tinted ? foreground.withValues(alpha: 0.45) : AppColors.previousCurve,
            ),
    );
  }

  /// Title on the left; on the right the waiting note or the legend.
  Widget _cardHeader(BuildContext context) {
    final l10n = context.l10n;
    final right = _waiting
        ? Text(l10n.liveForceCurveWaiting, key: const Key('force-curve-waiting'), style: AppTextStyles.caption)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_length(context) case final length?) ...[
                Text(length, key: const Key('force-curve-length'), style: AppTextStyles.caption),
                const SizedBox(width: AppSpacing.m),
              ],
              _LegendEntry(color: AppColors.zoneIn, text: l10n.liveForceCurveLast),
              if (hasData(previous)) ...[
                const SizedBox(width: AppSpacing.m),
                _LegendEntry(color: AppColors.previousCurve, text: l10n.liveForceCurvePrevious),
              ],
            ],
          );
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(
            child: Text(
              l10n.liveForceCurve,
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          // Shrinks on a narrow card rather than pushing the title out.
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.75),
            child: FittedBox(fit: BoxFit.scaleDown, child: right),
          ),
        ],
      ),
    );
  }

  /// A small note at the top right, above the curve.
  Widget _withNote(BuildContext context, Widget curve) {
    final note = _note(context);
    if (note == null) return curve;
    return Stack(
      fit: StackFit.expand,
      children: [curve, Align(alignment: Alignment.topRight, child: note)],
    );
  }

  /// The note beside the curve outside the card: the waiting hint, or the drive length of the last
  /// stroke, which in the coloured card is drawn in `text` like the curve.
  Widget? _note(BuildContext context) {
    final tinted = variant == ForceCurveVariant.tinted;
    if (_waiting) {
      return Text(
        context.l10n.liveForceCurveWaiting,
        key: const Key('force-curve-waiting'),
        style: _small.copyWith(color: tinted ? foreground : AppColors.textMuted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final length = _length(context);
    if (length == null) return null;
    return Text(
      length,
      key: const Key('force-curve-length'),
      style: _small.copyWith(color: tinted ? AppColors.text : AppColors.textMuted),
      maxLines: 1,
    );
  }

  String? _length(BuildContext context) => formatDriveLength(context.l10n, driveLengthMeters);
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 4,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 6),
          Text(text, style: AppTextStyles.caption),
        ],
      );
}

/// The last stroke as a line with an area, the previous one as a thinner line behind it, both
/// stretched to the width and on the scale of the higher of the two (Design D2).
class _CurvePainter extends CustomPainter {
  _CurvePainter({
    required this.last,
    required this.previous,
    required this.color,
    required this.fillOpacity,
    required this.previousColor,
  });

  final List<double> last;
  final List<double>? previous;
  final Color color;
  final double fillOpacity;
  final Color previousColor;

  static const _lastWidth = 3.0;
  static const _previousWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final previous = this.previous;
    final peak = [...last, ...?previous].reduce(math.max);
    // Room for half the line at the top, so the peak is not cut off.
    final area = Rect.fromLTRB(0, _lastWidth / 2, size.width, size.height);
    if (previous != null) {
      canvas.drawPath(_line(previous, peak, area), _stroke(previousColor, _previousWidth));
    }
    final line = _line(last, peak, area);
    final fill = Path.from(line)
      ..lineTo(area.right, area.bottom)
      ..lineTo(area.left, area.bottom)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: fillOpacity));
    canvas.drawPath(line, _stroke(color, _lastWidth));
  }

  /// A smooth line through [forces], stretched to the width of [area].
  static Path _line(List<double> forces, double peak, Rect area) {
    final points = [
      for (final (index, force) in _runs(forces))
        Offset(
          area.left + area.width * index / (forces.length - 1),
          area.bottom - area.height * force.clamp(0, peak) / peak,
        ),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length - 1; i++) {
      final middle = (points[i] + points[i + 1]) / 2;
      path.quadraticBezierTo(points[i].dx, points[i].dy, middle.dx, middle.dy);
    }
    return path..lineTo(points.last.dx, points.last.dy);
  }

  /// One point per run of equal values, in the middle of the run; the PM5 often repeats a value,
  /// which would show as steps. The first and the last value keep their place at the edges.
  static List<(double, double)> _runs(List<double> forces) {
    final runs = <(double, double)>[];
    var start = 0;
    for (var i = 1; i <= forces.length; i++) {
      if (i < forces.length && forces[i] == forces[start]) continue;
      final end = i - 1;
      final index = start == 0
          ? 0.0
          : end == forces.length - 1
              ? end.toDouble()
              : (start + end) / 2;
      runs.add((index, forces[start]));
      start = i;
    }
    // A curve of a single run still needs two points for a line.
    if (runs.length == 1) runs.add(((forces.length - 1).toDouble(), forces.last));
    return runs;
  }

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  @override
  bool shouldRepaint(_CurvePainter oldDelegate) =>
      oldDelegate.last != last ||
      oldDelegate.previous != previous ||
      oldDelegate.color != color ||
      oldDelegate.fillOpacity != fillOpacity ||
      oldDelegate.previousColor != previousColor;
}

/// A dashed baseline while waiting for the first curve (Design D3).
class _BaselinePainter extends CustomPainter {
  const _BaselinePainter();

  static const _width = 2.0;
  static const _dash = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.line
      ..strokeWidth = _width;
    final y = size.height - _width / 2;
    for (var x = 0.0; x < size.width; x += 2 * _dash) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + _dash, size.width), y), paint);
    }
  }

  @override
  bool shouldRepaint(_BaselinePainter oldDelegate) => false;
}
