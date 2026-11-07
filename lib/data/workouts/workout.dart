import 'package:flutter/foundation.dart' show immutable;

import '../courses/course.dart';
import '../sessions/session_plan.dart';

/// What to row: one or more courses one after the other, for a number of
/// laps, a duration or open (Change workout-course-chain, Design D1).
@immutable
class Workout {
  const Workout({
    required this.id,
    required this.name,
    required this.courses,
    required this.length,
  });

  final int id;
  final String name;

  /// The courses in their newest version and their order; at least one, all
  /// on one axis.
  final List<Course> courses;

  /// The length of the whole chain.
  final PlanLength length;

  CourseAxis get axis => courses.first.axis;

  /// The courses shown as one, named `Einrudern + Seerunde`.
  Course get chain => Course.chain(courses);

  /// The length of one lap: the courses together.
  int get lapLength => courses.fold(0, (sum, c) => sum + c.definition.length);

  /// The number of laps; null unless the workout has a fixed number of them.
  int? get laps => switch (length) {
    LapCount(:final count) => count,
    _ => null,
  };

  /// Rowing this workout (course-rowing-free, Design D1).
  SessionPlan toPlan() => SessionPlan(
    courses: courses,
    length: length,
    workout: (id: id, name: name),
  );
}
