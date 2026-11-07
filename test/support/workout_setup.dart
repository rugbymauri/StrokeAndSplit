import 'package:strokesplit/app/platform_providers.dart';
import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sources/rower_choice.dart';
import 'package:strokesplit/data/workouts/workout_repository.dart';
import 'package:strokesplit/features/workouts/workouts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_ble_transport.dart';
import 'localized_app.dart';
import 'test_database.dart';

/// A database with courses and workouts, and the app around a screen of the
/// workout choice.
class WorkoutSetup {
  WorkoutSetup({this.rower = const RowerChoice.simulator()});

  final RowerChoice rower;
  final db = openTestDatabase();
  late final courses = CourseRepository(db);
  late final workouts = WorkoutRepository(db);
  late final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      wakelockProvider.overrideWithValue(FakeWakelock()),
      rowerChoiceStoreProvider.overrideWithValue(MemoryRowerChoiceStore(rower)),
    ],
  );

  Future<int> addCourse(
    WidgetTester tester,
    String name, {
    int length = 1000,
  }) async => (await tester.runAsync(
    () => courses.create(
      name,
      CourseDefinition.single(axis: CourseAxis.distance, length: length),
    ),
  ))!;

  /// A course of 1000 m with the zone „Tempo“ from 200 to 800 m.
  Future<int> addCourseWithZone(WidgetTester tester, String name) async =>
      (await tester.runAsync(
        () => courses.create(
          name,
          const CourseDefinition(
            axis: CourseAxis.distance,
            length: 1000,
            segments: [
              CourseSegment(length: 200),
              CourseSegment(
                length: 600,
                paceFastCs: 12500,
                paceSlowCs: 13000,
                spmMin: 20,
                spmMax: 22,
                zoneName: 'Tempo',
              ),
              CourseSegment(length: 200),
            ],
          ),
        ),
      ))!;

  Future<int> addWorkout(
    WidgetTester tester,
    String name, {
    required int courseId,
    int? laps = 3,
  }) async => (await tester.runAsync(
    () => workouts.create(name, courseId: courseId, laps: laps),
  ))!;

  Future<void> pump(
    WidgetTester tester, {
    Widget home = const WorkoutsScreen(),
    Locale locale = const Locale('de'),
  }) async {
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: LocalizedApp(locale: locale, home: home),
      ),
    );
    await settle(tester);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
    }
  }

  /// Opens the screen of the workout [name] from the list.
  Future<void> openWorkout(WidgetTester tester, String name) async {
    await tester.tap(find.text(name));
    await settle(tester);
  }
}
