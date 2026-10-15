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
    this.pace,
    this.watts,
    this.strokeRate,
    this.heartRate,
    this.calories,
  });

  final double distanceMeters;
  final WorkoutType workoutType;
  final WorkoutState workoutState;

  /// Current pace per 500 m; null while not rowing.
  final Duration? pace;
  final int? watts;

  /// Strokes per minute.
  final int? strokeRate;

  /// Beats per minute; null when no heart rate monitor is connected.
  final int? heartRate;
  final int? calories;
}

/// Data of one completed stroke.
final class Stroke extends RowingEvent {
  const Stroke({
    required super.elapsed,
    required this.strokeNumber,
    required this.distanceMeters,
    required this.driveLengthMeters,
    required this.driveTime,
    required this.recoveryTime,
    required this.peakForceNewtons,
    required this.averageForceNewtons,
    this.watts,
  });

  final int strokeNumber;
  final double distanceMeters;
  final double driveLengthMeters;
  final Duration driveTime;
  final Duration recoveryTime;
  final double peakForceNewtons;
  final double averageForceNewtons;
  final int? watts;
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
}
