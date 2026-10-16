import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sessions/session_providers.dart';
import 'course.dart';
import 'course_repository.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) => CourseRepository(ref.watch(databaseProvider)));

/// All courses that are not deleted, by name.
final coursesProvider = StreamProvider<List<Course>>((ref) => ref.watch(courseRepositoryProvider).watchAll());
