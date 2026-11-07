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

/// What is rowed: one or more courses one after the other for a [length],
/// from a workout or chosen right on a course (course-rowing-free, Design
/// D1; workout-course-chain, Design D2). A free session has no plan.
@immutable
class SessionPlan {
  SessionPlan({
    required List<Course> courses,
    required this.length,
    this.workout,
  }) : courses = List.unmodifiable(courses),
       courseStarts = _starts(courses),
       definition = CourseDefinition.chain([
         for (final c in courses) c.definition,
       ]);

  static List<int> _starts(List<Course> courses) {
    var start = 0;
    return List.unmodifiable([
      for (final c in courses)
        (start += c.definition.segments.length) - c.definition.segments.length,
    ]);
  }

  /// The courses in the version that is rowed, in their order; at least one.
  final List<Course> courses;

  /// The courses as one: a lap rows all of them.
  final CourseDefinition definition;

  /// The index of the first segment of each course within a lap.
  final List<int> courseStarts;

  final PlanLength length;

  /// The workout the plan comes from; null when the course is rowed without one.
  final ({int id, String name})? workout;

  CourseAxis get axis => definition.axis;

  /// The index of the course that segment [segment] of a lap belongs to.
  int courseAt(int segment) {
    var index = 0;
    while (index + 1 < courseStarts.length &&
        courseStarts[index + 1] <= segment) {
      index++;
    }
    return index;
  }

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
