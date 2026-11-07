import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/statistics/session_places.dart';
import 'package:strokesplit/data/workouts/workout_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/rowed_sessions.dart';
import '../../support/test_database.dart';

import 'package:strokesplit/data/sessions/session_plan.dart';

void main() {
  test('follows the rankings when later sessions overtake a session', () async {
    final db = openTestDatabase();
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final course = await CourseRepository(db).create(
      'Seerunde',
      CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
    );
    final workouts = WorkoutRepository(db);
    final workout = (await workouts.get(
      await workouts.create(
        'Seerunde x1',
        courseIds: [course],
        length: const LapCount(1),
      ),
    ))!;
    final id = await storeRowedSession(
      db,
      workout: workout,
      laps: [RowedLap.single(248000, 1000)],
    );
    final seen = <SessionPlaces>[];
    container.listen(
      sessionPlacesProvider(id),
      (_, next) => seen.addAll([?next.value]),
      fireImmediately: true,
    );
    await pumpEventQueue();
    expect(seen.last, const SessionPlaces(session: 1, laps: {1: 1}));

    await storeRowedSession(
      db,
      workout: workout,
      laps: [RowedLap.single(245000, 1000)],
    );
    await pumpEventQueue();
    expect(seen.last, const SessionPlaces(session: 2, laps: {1: 2}));

    for (final ms in [240000, 242000]) {
      await storeRowedSession(
        db,
        workout: workout,
        laps: [RowedLap.single(ms, 1000)],
      );
    }
    await pumpEventQueue();
    expect(seen.last, SessionPlaces.none);
  });

  test('gives no places to a session of the simulator', () async {
    final db = openTestDatabase();
    final course = await CourseRepository(db).create(
      'Seerunde',
      CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
    );
    final workouts = WorkoutRepository(db);
    final workout = (await workouts.get(
      await workouts.create(
        'Seerunde x1',
        courseIds: [course],
        length: const LapCount(1),
      ),
    ))!;
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final id = await storeRowedSession(
      db,
      workout: workout,
      source: ErgSourceKind.simulator,
      laps: [RowedLap.single(248000, 1000)],
    );

    expect(
      await container.read(sessionPlacesRepositoryProvider).places(id),
      SessionPlaces.none,
    );
  });
}
