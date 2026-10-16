import 'package:flutter/foundation.dart' show immutable;

import '../courses/course.dart';

/// What to row: a course and a number of laps (Design D4).
@immutable
class SessionTemplate {
  const SessionTemplate({required this.id, required this.name, required this.course, required this.laps});

  final int id;
  final String name;

  /// The course in its newest version.
  final Course course;

  /// Null for an open number of laps.
  final int? laps;
}
