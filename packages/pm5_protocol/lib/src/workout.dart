/// Workout type as reported by the PM5 (General Status, byte 6).
///
/// Values follow the Concept2 PM5 Bluetooth Smart Interface Definition.
enum WorkoutType {
  justRowNoSplits(0),
  justRowSplits(1),
  fixedDistanceNoSplits(2),
  fixedDistanceSplits(3),
  fixedTimeNoSplits(4),
  fixedTimeSplits(5),
  fixedTimeInterval(6),
  fixedDistanceInterval(7),
  variableInterval(8),
  variableUndefinedRestInterval(9),
  fixedCalorie(10),
  fixedWattMinutes(11),
  fixedCalorieInterval(12),
  unknown(-1);

  const WorkoutType(this.code);

  final int code;

  static WorkoutType fromCode(int code) =>
      values.firstWhere((t) => t.code == code, orElse: () => WorkoutType.unknown);
}

/// Coarse phase of a workout, derived from [WorkoutState].
enum WorkoutPhase { waiting, rowing, rest, finished, unknown }

/// Workout state as reported by the PM5 (General Status, byte 8).
enum WorkoutState {
  waitToBegin(0, WorkoutPhase.waiting),
  workoutRow(1, WorkoutPhase.rowing),
  countdownPause(2, WorkoutPhase.waiting),
  intervalRest(3, WorkoutPhase.rest),
  intervalWorkTime(4, WorkoutPhase.rowing),
  intervalWorkDistance(5, WorkoutPhase.rowing),
  intervalRestEndToWorkTime(6, WorkoutPhase.rest),
  intervalRestEndToWorkDistance(7, WorkoutPhase.rest),
  intervalWorkTimeToRest(8, WorkoutPhase.rowing),
  intervalWorkDistanceToRest(9, WorkoutPhase.rowing),
  workoutEnd(10, WorkoutPhase.finished),
  terminate(11, WorkoutPhase.finished),
  workoutLogged(12, WorkoutPhase.finished),
  rearm(13, WorkoutPhase.waiting),
  unknown(-1, WorkoutPhase.unknown);

  const WorkoutState(this.code, this.phase);

  final int code;
  final WorkoutPhase phase;

  static WorkoutState fromCode(int code) =>
      values.firstWhere((s) => s.code == code, orElse: () => WorkoutState.unknown);
}
