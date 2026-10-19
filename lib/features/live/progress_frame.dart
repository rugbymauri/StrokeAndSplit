import 'dart:math' as math;
import 'dart:ui' show PathMetric, Tangent;

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
/// A ghost moved out of the outer track sticks out of the box by up to [overhang];
/// the layout around the box keeps that free.
class ProgressFramePainter extends CustomPainter {
  ProgressFramePainter({required this.model, this.pace, this.ghost});

  final ProgressFrameModel model;
  final BandStatus? pace;
  final FrameGhost? ghost;

  static const radius = 28.0;
  static const trackWidth = 10.0;
  static const trackGap = 4.0;

  static const _boatLength = 22.0;
  static const _boatWidth = 14.0;
  static const _boatRim = 2.0;
  static const _ghostLength = 18.0;
  static const _ghostWidth = 7.0;
  static const _ghostRim = 1.5;

  /// How far the ghost moves out across its track to clear a boat beside it:
  /// its rim lies on the boat's rim, so both stay whole (ghost, Design D5).
  static const ghostShift = _boatWidth / 2 - _boatRim / 2 + _ghostWidth / 2 + _ghostRim / 2;

  /// How far a ghost moved out of the outer track sticks out of the box, rim included.
  static const overhang = ghostShift + (_ghostWidth + _ghostRim) / 2 - trackWidth / 2;

  /// From the outer edge to the inner edge of the innermost track.
  static double frameWidth(int tracks) => tracks * trackWidth + (tracks - 1) * trackGap;

  /// The colour of the segment track for the zone status of the pace.
  static Color segmentColor(BandStatus? pace) => switch (pace) {
        null || BandStatus.none => AppColors.textMuted,
        BandStatus.inBand => AppColors.zoneIn,
        BandStatus.above || BandStatus.below || BandStatus.missing => AppColors.zoneOut,
      };

  /// The colour of the box for the zone status of the pace: tinted like the stroke rate card in a band,
  /// plain in a free gap.
  static Color boxColor(BandStatus? pace) => switch (pace) {
        null || BandStatus.none => AppColors.surface,
        BandStatus.inBand => AppColors.zoneInSurface,
        BandStatus.above || BandStatus.below || BandStatus.missing => AppColors.zoneOutSurface,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final background = boxColor(pace);
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(radius)), Paint()..color = background);

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
      // Zones stand out brighter than the free parts, empty and filled.
      for (final (start, end) in track.zones) {
        canvas.drawPath(metric.extractPath(start * metric.length, end * metric.length), stroke..color = AppColors.trackZone);
        final filledEnd = end < track.share ? end : track.share;
        if (filledEnd > start) {
          canvas.drawPath(
            metric.extractPath(start * metric.length, filledEnd * metric.length),
            stroke..color = AppColors.text,
          );
        }
      }
    }
    for (var i = 0; i < tracks.length; i++) {
      // Course and lap track mark their start; the segment track is the last one.
      if (i < tracks.length - 1) _notch(canvas, metrics[i], 0, background);
      for (final boundary in tracks[i].$1.boundaries) {
        _notch(canvas, metrics[i], boundary, background);
      }
    }
    // The end of a lap stands out as a bright line: at the top of the lap track,
    // and at the end of every lap on the course track.
    final lapTrack = tracks.length - 2;
    _lapEnd(canvas, metrics[lapTrack], 0, background);
    if (model.course case final course?) {
      _lapEnd(canvas, metrics[0], 0, background);
      for (final boundary in course.boundaries) {
        _lapEnd(canvas, metrics[0], boundary, background);
      }
    }
    final boats = <List<Offset>>[];
    for (var i = 0; i < tracks.length; i++) {
      final (track, _, filled, _) = tracks[i];
      if (_tangent(metrics[i], track.share) case final tangent?) {
        _boat(canvas, tangent.position, tangent, filled, background, length: _boatLength, width: _boatWidth, rim: _boatRim);
        // What shows of the boat; the rim of a ghost may lie on its rim.
        boats.add(_rhombus(tangent.position, tangent, _boatLength - _boatRim, _boatWidth - _boatRim));
      }
    }
    // A ghost moves out of the way instead of covering a boat (ghost, Design D5).
    for (var i = 0; i < tracks.length; i++) {
      if (tracks[i].$4 case final share?) {
        if (_tangent(metrics[i], share) case final tangent?) {
          // Out to [overhang] beyond the box at most.
          final inset = trackWidth / 2 + i * (trackWidth + trackGap);
          final position = _ghostPosition(tangent, boats, maxShift: inset + overhang - (_ghostWidth + _ghostRim) / 2);
          // Ghosts further in keep clear of this one as well.
          boats.add(_rhombus(position, tangent, _ghostLength - _ghostRim, _ghostWidth - _ghostRim));
          _boat(canvas, position, tangent, AppColors.ghost, background, length: _ghostLength, width: _ghostWidth, rim: _ghostRim);
        }
      }
    }
  }

  /// Where the ghost at [tangent] clears all [boats], including ghosts already placed:
  /// on the centre line of its track, or moved out across it by at least [ghostShift],
  /// but at most [maxShift].
  static Offset _ghostPosition(Tangent tangent, List<List<Offset>> boats, {required double maxShift}) {
    final out = Offset(tangent.vector.dy, -tangent.vector.dx);
    bool clear(double shift) {
      final ghost = _rhombus(
        tangent.position + out * shift,
        tangent,
        _ghostLength + _ghostRim,
        _ghostWidth + _ghostRim,
      );
      return boats.every((boat) => !_overlap(ghost, boat));
    }

    if (clear(0)) return tangent.position;
    var shift = math.min(ghostShift, maxShift);
    while (shift < maxShift && !clear(shift)) {
      shift = math.min(shift + 1, maxShift);
    }
    return tangent.position + out * shift;
  }

  static Tangent? _tangent(PathMetric metric, double share) =>
      metric.getTangentForOffset(share.clamp(0, 1) * metric.length);

  /// The corners of a rhombus around [centre], pointing along [tangent].
  static List<Offset> _rhombus(Offset centre, Tangent tangent, double length, double width) {
    final along = tangent.vector * (length / 2);
    final across = Offset(-tangent.vector.dy, tangent.vector.dx) * (width / 2);
    return [centre - along, centre - across, centre + along, centre + across];
  }

  /// Whether two convex polygons overlap by more than touching (separating axis test).
  static bool _overlap(List<Offset> a, List<Offset> b) {
    for (final polygon in [a, b]) {
      for (var i = 0; i < polygon.length; i++) {
        final edge = polygon[(i + 1) % polygon.length] - polygon[i];
        final axis = Offset(-edge.dy, edge.dx);
        double project(Offset p) => p.dx * axis.dx + p.dy * axis.dy;
        final pa = a.map(project);
        final pb = b.map(project);
        const touching = 1e-6;
        if (pa.reduce(math.max) <= pb.reduce(math.min) + touching ||
            pb.reduce(math.max) <= pa.reduce(math.min) + touching) {
          return false;
        }
      }
    }
    return true;
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

  /// A bright line across the track where a lap ends, in a cut of the colour of the box.
  static void _lapEnd(Canvas canvas, PathMetric metric, double share, Color background) {
    final tangent = metric.getTangentForOffset(share * metric.length);
    if (tangent == null) return;
    final across = Offset(-tangent.vector.dy, tangent.vector.dx) * (trackWidth / 2 + 2);
    canvas
      ..drawLine(
        tangent.position - across,
        tangent.position + across,
        Paint()
          ..strokeWidth = 7
          ..color = background,
      )
      ..drawLine(
        tangent.position - across,
        tangent.position + across,
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = AppColors.text,
      );
  }

  /// A cut across the track in the colour of the box.
  static void _notch(Canvas canvas, PathMetric metric, double share, Color background) {
    final tangent = metric.getTangentForOffset(share * metric.length);
    if (tangent == null) return;
    final across = Offset(-tangent.vector.dy, tangent.vector.dx) * (trackWidth / 2 + 1);
    canvas.drawLine(
      tangent.position - across,
      tangent.position + across,
      Paint()
        ..strokeWidth = 3
        ..color = background,
    );
  }

  /// A rhombus at [position], pointing along [tangent], with a rim in the colour of the box.
  static void _boat(
    Canvas canvas,
    Offset position,
    Tangent tangent,
    Color color,
    Color background, {
    required double length,
    required double width,
    required double rim,
  }) {
    final boat = Path()
      ..moveTo(-length / 2, 0)
      ..lineTo(0, -width / 2)
      ..lineTo(length / 2, 0)
      ..lineTo(0, width / 2)
      ..close();
    canvas
      ..save()
      ..translate(position.dx, position.dy)
      ..rotate(-tangent.angle)
      ..drawPath(boat, Paint()..color = color)
      ..drawPath(
        boat,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rim
          ..strokeJoin = StrokeJoin.miter
          ..color = background,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(ProgressFramePainter oldDelegate) =>
      oldDelegate.model != model || oldDelegate.pace != pace || oldDelegate.ghost != ghost;
}
