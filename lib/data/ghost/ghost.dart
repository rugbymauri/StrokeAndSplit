import 'package:flutter/foundation.dart' show immutable, listEquals;

import '../courses/course.dart';

/// Where the ghost was at a moment of its ranking entry.
///
/// Both values count from the beginning of the entry: [wallMs] is wall-clock
/// time including pauses, [distanceDm] the distance rowed since then.
@immutable
class GhostPoint {
  const GhostPoint({required this.wallMs, required this.distanceDm});

  final int wallMs;
  final int distanceDm;

  @override
  bool operator ==(Object other) =>
      other is GhostPoint &&
      other.wallMs == wallMs &&
      other.distanceDm == distanceDm;

  @override
  int get hashCode => Object.hash(wallMs, distanceDm);

  @override
  String toString() => 'GhostPoint($wallMs ms, $distanceDm dm)';
}

/// The course of a ranking entry over time, rowed again as the ghost
/// (Change ghost, Design D2, D3).
///
/// Between two points the ghost moves linearly. Before the first point it
/// stands at the start, after the last one at the finish.
@immutable
class GhostTrack {
  /// [points] in the order of their wall-clock time, with distances that never
  /// go back; at least one.
  GhostTrack(List<GhostPoint> points) : points = List.unmodifiable(points) {
    if (points.isEmpty) {
      throw ArgumentError.value(
        points,
        'points',
        'A ghost track needs at least one point',
      );
    }
    for (var i = 1; i < points.length; i++) {
      if (points[i].wallMs < points[i - 1].wallMs ||
          points[i].distanceDm < points[i - 1].distanceDm) {
        throw ArgumentError.value(
          points,
          'points',
          'Wall-clock time and distance must not go back',
        );
      }
    }
  }

  final List<GhostPoint> points;

  /// Wall-clock time from the beginning to the end of the entry.
  int get durationMs => points.last.wallMs;

  /// Distance rowed from the beginning to the end of the entry.
  int get distanceDm => points.last.distanceDm;

  /// The distance in decimetres the ghost had rowed at [wallMs].
  double distanceDmAt(num wallMs) {
    if (wallMs <= points.first.wallMs) {
      return points.first.distanceDm.toDouble();
    }
    if (wallMs >= points.last.wallMs) return points.last.distanceDm.toDouble();
    final i = _firstIndexWhere((p) => p.wallMs >= wallMs);
    final a = points[i - 1];
    final b = points[i];
    return a.distanceDm +
        (b.distanceDm - a.distanceDm) *
            (wallMs - a.wallMs) /
            (b.wallMs - a.wallMs);
  }

  /// The wall-clock time in milliseconds at which the ghost first reached
  /// [distanceDm]; at or before the start that is the beginning, and null
  /// if the ghost never got that far.
  ///
  /// During a pause the distance stands, so the ghost reaches it when the
  /// pause begins.
  double? wallMsAt(num distanceDm) {
    if (distanceDm <= points.first.distanceDm) {
      return points.first.wallMs.toDouble();
    }
    if (distanceDm > points.last.distanceDm) return null;
    final i = _firstIndexWhere((p) => p.distanceDm >= distanceDm);
    final a = points[i - 1];
    final b = points[i];
    return a.wallMs +
        (b.wallMs - a.wallMs) *
            (distanceDm - a.distanceDm) /
            (b.distanceDm - a.distanceDm);
  }

  /// The position of the ghost on [axis] at [wallMs], in the unit of the
  /// course: metres on a distance axis, seconds on a time axis.
  double positionAt(CourseAxis axis, num wallMs) => switch (axis) {
    CourseAxis.distance => distanceDmAt(wallMs) / 10,
    CourseAxis.time =>
      wallMs.clamp(points.first.wallMs, points.last.wallMs) / 1000,
  };

  /// The wall-clock time in milliseconds at which the ghost reached
  /// [position] on [axis], in the unit of the course; null if it never got
  /// that far.
  double? wallMsAtPosition(CourseAxis axis, num position) => switch (axis) {
    CourseAxis.distance => wallMsAt(position * 10),
    CourseAxis.time =>
      position * 1000 > points.last.wallMs
          ? null
          : (position * 1000)
                .clamp(points.first.wallMs, points.last.wallMs)
                .toDouble(),
  };

  /// The first index whose point satisfies [test], by binary search; the
  /// first point never does.
  int _firstIndexWhere(bool Function(GhostPoint) test) {
    var low = 1;
    var high = points.length - 1;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (test(points[mid])) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    return low;
  }

  @override
  bool operator ==(Object other) =>
      other is GhostTrack && listEquals(other.points, points);

  @override
  int get hashCode => Object.hashAll(points);

  @override
  String toString() =>
      'GhostTrack(${points.length} points, $durationMs ms, $distanceDm dm)';
}

/// How far the rower is from the ghost of the template (Change ghost,
/// Design D4).
@immutable
class GhostGap {
  const GhostGap({
    required this.axis,
    required this.amount,
    required this.ghostAhead,
  }) : assert(amount >= 0, 'The amount of a gap is never negative');

  /// The axis of the course. It decides what [amount] measures.
  final CourseAxis axis;

  /// The size of the gap: seconds on a distance axis, metres on a time axis.
  final double amount;

  /// Whether the ghost is ahead, i.e. the rower is behind; false on a tie.
  final bool ghostAhead;

  @override
  bool operator ==(Object other) =>
      other is GhostGap &&
      other.axis == axis &&
      other.amount == amount &&
      other.ghostAhead == ghostAhead;

  @override
  int get hashCode => Object.hash(axis, amount, ghostAhead);

  @override
  String toString() =>
      'GhostGap($axis, $amount, ${ghostAhead ? 'ghost ahead' : 'rower ahead'})';
}
