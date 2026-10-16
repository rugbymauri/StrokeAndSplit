import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../data/courses/lap_tracker.dart';
import 'progress_frame_model.dart';

/// Where the ghost is on each track, as shares from 0 to 1; a track
/// without a share shows no ghost (ui-design, Design D3).
@immutable
class FrameGhost {
  const FrameGhost({this.course, this.lap, this.segment});

  final double? course;
  final double? lap;
  final double? segment;
}

/// The box around the pace whose border shows the progress as up to three
/// tracks (ui-design, Design D3). [child] sits inside the tracks.
class ProgressFrame extends StatelessWidget {
  const ProgressFrame({super.key, required this.model, this.pace, this.ghost, this.child});

  final ProgressFrameModel model;

  /// The zone status of the pace, which colours the segment track.
  final BandStatus? pace;
  final FrameGhost? ghost;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tracks = model.course == null ? 2 : 3;
    return CustomPaint(
      painter: ProgressFramePainter(model: model, pace: pace, ghost: ghost),
      child: Padding(
        padding: EdgeInsets.all(ProgressFramePainter.frameWidth(tracks) + 12),
        child: child,
      ),
    );
  }
}

/// Paints the box and its tracks. Each track starts at the top centre and
/// runs clockwise; positions are arc lengths, so equal shares are equally long.
class ProgressFramePainter extends CustomPainter {
  ProgressFramePainter({required this.model, this.pace, this.ghost});

  final ProgressFrameModel model;
  final BandStatus? pace;
  final FrameGhost? ghost;

  static const radius = 28.0;
  static const trackWidth = 10.0;
  static const trackGap = 4.0;

  /// From the outer edge to the inner edge of the innermost track.
  static double frameWidth(int tracks) => tracks * trackWidth + (tracks - 1) * trackGap;

  /// The colour of the segment track for the zone status of the pace.
  static Color segmentColor(BandStatus? pace) => switch (pace) {
        null || BandStatus.none => AppColors.textMuted,
        BandStatus.inBand => AppColors.zoneIn,
        BandStatus.above || BandStatus.below || BandStatus.missing => AppColors.zoneOut,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(radius)), Paint()..color = AppColors.surface);

    final ghost = this.ghost;
    final tracks = [
      if (model.course case final course?) (course, AppColors.track, AppColors.text, ghost?.course),
      (model.lap, AppColors.track, AppColors.textMuted, ghost?.lap),
      (model.segment, AppColors.trackInner, segmentColor(pace), ghost?.segment),
    ];
    final metrics = [
      for (var i = 0; i < tracks.length; i++) _outline(box, trackWidth / 2 + i * (trackWidth + trackGap)),
    ];
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth;

    for (var i = 0; i < tracks.length; i++) {
      final (track, empty, filled, _) = tracks[i];
      final metric = metrics[i];
      canvas.drawPath(metric.extractPath(0, metric.length), stroke..color = empty);
      if (track.share > 0) canvas.drawPath(metric.extractPath(0, track.share * metric.length), stroke..color = filled);
    }
    for (var i = 0; i < tracks.length; i++) {
      // Course and lap track mark their start; the segment track is the last one.
      if (i < tracks.length - 1) _notch(canvas, metrics[i], 0);
      for (final boundary in tracks[i].$1.boundaries) {
        _notch(canvas, metrics[i], boundary);
      }
    }
    for (var i = 0; i < tracks.length; i++) {
      final (track, _, filled, _) = tracks[i];
      _boat(canvas, metrics[i], track.share, filled, length: 22, width: 14, rim: 2);
    }
    // The ghost lies above the rower's own boat.
    for (var i = 0; i < tracks.length; i++) {
      if (tracks[i].$4 case final share?) {
        _boat(canvas, metrics[i], share, AppColors.ghost, length: 18, width: 7, rim: 1.5);
      }
    }
  }

  /// The centre line of a track [inset] from the edge of [box], from the top centre clockwise.
  static PathMetric _outline(Rect box, double inset) {
    final rect = box.deflate(inset);
    final r = (radius - inset).clamp(0, rect.shortestSide / 2).toDouble();
    final corner = Radius.circular(r);
    final path = Path()
      ..moveTo(rect.center.dx, rect.top)
      ..lineTo(rect.right - r, rect.top)
      ..arcToPoint(Offset(rect.right, rect.top + r), radius: corner)
      ..lineTo(rect.right, rect.bottom - r)
      ..arcToPoint(Offset(rect.right - r, rect.bottom), radius: corner)
      ..lineTo(rect.left + r, rect.bottom)
      ..arcToPoint(Offset(rect.left, rect.bottom - r), radius: corner)
      ..lineTo(rect.left, rect.top + r)
      ..arcToPoint(Offset(rect.left + r, rect.top), radius: corner)
      ..close();
    return path.computeMetrics().first;
  }

  /// A cut across the track in the colour of the box.
  static void _notch(Canvas canvas, PathMetric metric, double share) {
    final tangent = metric.getTangentForOffset(share * metric.length);
    if (tangent == null) return;
    final across = Offset(-tangent.vector.dy, tangent.vector.dx) * (trackWidth / 2 + 1);
    canvas.drawLine(
      tangent.position - across,
      tangent.position + across,
      Paint()
        ..strokeWidth = 3
        ..color = AppColors.surface,
    );
  }

  /// A rhombus at [share] of the track, pointing along it, with a dark rim.
  static void _boat(
    Canvas canvas,
    PathMetric metric,
    double share,
    Color color, {
    required double length,
    required double width,
    required double rim,
  }) {
    final tangent = metric.getTangentForOffset(share.clamp(0, 1) * metric.length);
    if (tangent == null) return;
    final boat = Path()
      ..moveTo(-length / 2, 0)
      ..lineTo(0, -width / 2)
      ..lineTo(length / 2, 0)
      ..lineTo(0, width / 2)
      ..close();
    canvas
      ..save()
      ..translate(tangent.position.dx, tangent.position.dy)
      ..rotate(-tangent.angle)
      ..drawPath(boat, Paint()..color = color)
      ..drawPath(
        boat,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rim
          ..strokeJoin = StrokeJoin.miter
          ..color = AppColors.surface,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(ProgressFramePainter oldDelegate) =>
      oldDelegate.model != model || oldDelegate.pace != pace || oldDelegate.ghost != ghost;
}
