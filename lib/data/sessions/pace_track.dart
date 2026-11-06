import 'dart:math' as math;

/// The pace over a session in steps of equal time, each from the distance rowed in it, so pauses and
/// the swings of single strokes do not count and the steps agree with the average pace (ui-design, Task 5.10).
class PaceTrack {
  const PaceTrack(this.steps);

  /// Steps of [stepMsFor] at least; the curve stays readable on a long session.
  static const targetSteps = 60;

  /// The shortest step, long enough to even out a few strokes.
  static const minStepMs = 10000;

  /// (end of the step in rowed milliseconds, pace in centiseconds per 500 m), oldest first.
  final List<(int, int)> steps;

  static const empty = PaceTrack([]);

  /// The fastest pace of a step; null without steps.
  int? get fastestCs =>
      steps.isEmpty ? null : steps.map((s) => s.$2).reduce(math.min);

  /// The slowest pace of a step; null without steps.
  int? get slowestCs =>
      steps.isEmpty ? null : steps.map((s) => s.$2).reduce(math.max);

  /// How long a step of a session of [durationMs] is.
  static int stepMsFor(int durationMs) =>
      math.max(minStepMs, (durationMs / targetSteps).ceil());

  /// The steps of [points], (rowed milliseconds, distance in decimetres) ordered by time. A step without
  /// distance has no pace and is left out, as is a last step shorter than half a step.
  static PaceTrack of(List<(int, int)> points) {
    if (points.length < 2) return empty;
    final (startMs, _) = points.first;
    final step = stepMsFor(points.last.$1 - startMs);
    final steps = <(int, int)>[];
    var (fromMs, fromDm) = points.first;
    var boundary = startMs + step;
    for (final (i, (tMs, distanceDm)) in points.indexed.skip(1)) {
      final last = i == points.length - 1;
      // A step ends at the first point on or after its boundary, or at the end of the session.
      if (!last && tMs < boundary) continue;
      final ms = tMs - fromMs;
      final dm = distanceDm - fromDm;
      if (dm > 0 && ms > 0 && (tMs >= boundary || ms * 2 >= step)) {
        steps.add((tMs - startMs, (ms * 500 / dm).round()));
      }
      (fromMs, fromDm) = (tMs, distanceDm);
      boundary = startMs + ((tMs - startMs) ~/ step + 1) * step;
    }
    return PaceTrack(steps);
  }
}
