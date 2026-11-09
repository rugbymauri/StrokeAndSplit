import 'workout.dart';

/// Everything a data source reports after decoding, independent of whether
/// it came from a PM5, the simulator or a replay.
sealed class RowingEvent {
  const RowingEvent({required this.elapsed});

  /// Elapsed workout time as shown on the PM5.
  final Duration elapsed;
}

/// Current rowing metrics, emitted at the PM5 sample rate.
final class StatusTick extends RowingEvent {
  const StatusTick({
    required super.elapsed,
    required this.distanceMeters,
    required this.workoutType,
    required this.workoutState,
    required this.isRowing,
    this.pace,
    this.watts,
    this.strokeRate,
    this.heartRate,
    this.calories,
    this.resistanceLevel,
  });

  final double distanceMeters;
  final WorkoutType workoutType;
  final WorkoutState workoutState;

  /// False while the rower sits still; the PM5 clock stops in that case.
  final bool isRowing;

  /// Current pace per 500 m; null while not rowing.
  final Duration? pace;

  /// Power derived from [pace], as the PM5 display shows it.
  final int? watts;

  /// Strokes per minute.
  final int? strokeRate;

  /// Beats per minute, from the directly connected chest strap or else from
  /// the rower; null when neither reports one.
  final int? heartRate;
  final int? calories;

  /// The resistance level the rower reports, e.g. 7 of 15; null when it reports none, as the PM5.
  final int? resistanceLevel;

  static const _keep = Object();

  /// A copy with another [heartRate]; pass null to mark it as missing.
  StatusTick copyWith({Object? heartRate = _keep}) => StatusTick(
    elapsed: elapsed,
    distanceMeters: distanceMeters,
    workoutType: workoutType,
    workoutState: workoutState,
    isRowing: isRowing,
    pace: pace,
    watts: watts,
    strokeRate: strokeRate,
    heartRate: identical(heartRate, _keep) ? this.heartRate : heartRate as int?,
    calories: calories,
    resistanceLevel: resistanceLevel,
  );

  @override
  String toString() =>
      'StatusTick(elapsed: $elapsed, distance: $distanceMeters, type: ${workoutType.name}, '
      'state: ${workoutState.name}, rowing: $isRowing, pace: $pace, watts: $watts, spm: $strokeRate, '
      'hr: $heartRate, calories: $calories, resistance: $resistanceLevel)';
}

/// Data of one completed stroke.
///
/// The details are null when the device does not report them, as FTMS
/// rowers only count strokes; they are never estimated.
final class Stroke extends RowingEvent {
  const Stroke({
    required super.elapsed,
    required this.strokeNumber,
    required this.distanceMeters,
    this.driveLengthMeters,
    this.driveTime,
    this.recoveryTime,
    this.peakForceNewtons,
    this.averageForceNewtons,
    this.watts,
  });

  final int strokeNumber;
  final double distanceMeters;
  final double? driveLengthMeters;
  final Duration? driveTime;
  final Duration? recoveryTime;
  final double? peakForceNewtons;
  final double? averageForceNewtons;
  final int? watts;

  @override
  String toString() =>
      'Stroke(#$strokeNumber, elapsed: $elapsed, distance: $distanceMeters, '
      'driveLength: $driveLengthMeters, drive: $driveTime, recovery: $recoveryTime, '
      'peak: ${peakForceNewtons?.toStringAsFixed(1)} N, avg: ${averageForceNewtons?.toStringAsFixed(1)} N, '
      'watts: $watts)';
}

/// The force curve of one stroke's drive, complete and in order.
///
/// The PM5 sends it right after the drive, about 1.5 to 2 s before the
/// [Stroke] with the same [strokeNumber], which is only emitted at the end of
/// the recovery. Incomplete curves are never emitted.
final class StrokeForceCurve extends RowingEvent {
  StrokeForceCurve({
    required super.elapsed,
    required this.strokeNumber,
    required List<double> forcesNewtons,
    this.driveLengthMeters,
  }) : forcesNewtons = List.unmodifiable(forcesNewtons);

  /// Number of the stroke the curve belongs to, as in [Stroke.strokeNumber].
  final int strokeNumber;

  /// Force over the drive in newtons, evenly spaced in time (about 16 ms on
  /// the PM5); the number of values differs from stroke to stroke.
  final List<double> forcesNewtons;

  /// Drive length of the same stroke; null when the device reports none or 0.
  final double? driveLengthMeters;

  /// The largest value of [forcesNewtons], 0 for an empty curve.
  double get peakNewtons =>
      forcesNewtons.fold(0, (max, f) => f > max ? f : max);

  @override
  String toString() =>
      'StrokeForceCurve(#$strokeNumber, elapsed: $elapsed, points: ${forcesNewtons.length}, '
      'peak: ${peakNewtons.toStringAsFixed(1)} N, driveLength: $driveLengthMeters)';
}

/// The PM5 moved to another workout state.
final class WorkoutStateChanged extends RowingEvent {
  const WorkoutStateChanged({
    required super.elapsed,
    required this.previous,
    required this.current,
    required this.isReset,
  });

  final WorkoutState previous;
  final WorkoutState current;

  /// True when the PM5 started a new workout and time and distance restarted.
  final bool isReset;

  @override
  String toString() =>
      'WorkoutStateChanged(elapsed: $elapsed, ${previous.name} -> ${current.name}, reset: $isReset)';
}
