import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sessions/session_providers.dart';
import 'workout.dart';
import 'workout_repository.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(ref.watch(databaseProvider)),
);

/// All workouts by name.
final workoutsProvider = StreamProvider<List<Workout>>(
  (ref) => ref.watch(workoutRepositoryProvider).watchAll(),
);
