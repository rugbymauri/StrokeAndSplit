import 'package:flutter/foundation.dart' show immutable;

import '../courses/course.dart';

/// How long a planned session lasts (course-rowing-free, Design D1).
@immutable
sealed class PlanLength {
  const PlanLength();
}

/// Ends by itself after the last of [count] laps.
final class LapCount extends PlanLength {
  const LapCount(this.count);

  final int count;

  @override
  bool operator ==(Object other) => other is LapCount && other.count == count;

  @override
  int get hashCode => count.hashCode;
}

/// Ends by itself once the rowing time without pauses reaches [time].
final class TimeLimit extends PlanLength {
  const TimeLimit(this.time);

  final Duration time;

  @override
  bool operator ==(Object other) => other is TimeLimit && other.time == time;

  @override
  int get hashCode => time.hashCode;
}

/// Ends when the rower ends the session.
final class OpenLength extends PlanLength {
  const OpenLength();

  @override
  bool operator ==(Object other) => other is OpenLength;

  @override
  int get hashCode => 0;
}

/// What is rowed: a course for a [length], from a template or chosen right
/// on the course (course-rowing-free, Design D1). A free session has no plan.
@immutable
class SessionPlan {
  const SessionPlan({
    required this.course,
    required this.length,
    this.template,
  });

  /// The course in the version that is rowed.
  final Course course;

  final PlanLength length;

  /// The template the plan comes from; null when the course is rowed without one.
  final ({int id, String name})? template;

  /// The number of laps; null unless the plan has a fixed number of them.
  int? get plannedLaps => switch (length) {
    LapCount(:final count) => count,
    _ => null,
  };

  /// The rowing time after which the session ends; null without a time limit.
  Duration? get plannedDuration => switch (length) {
    TimeLimit(:final time) => time,
    _ => null,
  };
}
