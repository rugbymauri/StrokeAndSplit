import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../courses/course_repository.dart';
import '../db/database.dart';
import '../db/watch.dart';
import '../sessions/session_plan.dart';
import 'workout.dart';

/// Stores workouts: their courses as blocks in order and their length
/// (Change workout-course-chain, Design D1).
class WorkoutRepository {
  WorkoutRepository(this._db) : _courses = CourseRepository(_db);

  final AppDatabase _db;
  final CourseRepository _courses;

  /// Stores a workout rowing [courseIds] one after the other for [length]
  /// and returns its id.
  Future<int> create(
    String name, {
    required List<int> courseIds,
    required PlanLength length,
  }) {
    return _db.transaction(() async {
      await _check(courseIds, length);
      final id = await _db
          .into(_db.workouts)
          .insert(
            WorkoutsCompanion.insert(
              name: name,
              createdAt: clock.now(),
              laps: Value(_laps(length)),
              durationS: Value(_durationS(length)),
            ),
          );
      await _insertBlocks(id, courseIds);
      return id;
    });
  }

  /// All workouts by name, with their courses in their newest version.
  Future<List<Workout>> all() async {
    final rows =
        await (_db.select(_db.workouts)..orderBy([
              (t) => OrderingTerm.asc(t.name.collate(Collate.noCase)),
            ]))
            .get();
    return [for (final row in rows) await _workout(row)];
  }

  Stream<List<Workout>> watchAll() => _db.watchTables([
    _db.workouts,
    _db.workoutBlocks,
    _db.courses,
    _db.courseVersions,
    _db.courseSegments,
  ], all);

  Future<Workout?> get(int id) async {
    final row = await (_db.select(
      _db.workouts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _workout(row);
  }

  /// Changes the workout; sessions rowed with it keep their courses and laps.
  Future<void> update(
    int id, {
    required String name,
    required List<int> courseIds,
    required PlanLength length,
  }) {
    return _db.transaction(() async {
      await _check(courseIds, length);
      await (_db.update(_db.workouts)..where((t) => t.id.equals(id))).write(
        WorkoutsCompanion(
          name: Value(name),
          laps: Value(_laps(length)),
          durationS: Value(_durationS(length)),
        ),
      );
      await (_db.delete(
        _db.workoutBlocks,
      )..where((b) => b.workoutId.equals(id))).go();
      await _insertBlocks(id, courseIds);
    });
  }

  /// Deletes the workout; its sessions stay and keep its name.
  Future<void> delete(int id) {
    return _db.transaction(() async {
      await (_db.update(_db.sessions)..where((s) => s.workoutId.equals(id)))
          .write(const SessionsCompanion(workoutId: Value(null)));
      await (_db.delete(_db.workouts)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<void> _insertBlocks(int workoutId, List<int> courseIds) async {
    for (final (position, courseId) in courseIds.indexed) {
      await _db
          .into(_db.workoutBlocks)
          .insert(
            WorkoutBlocksCompanion.insert(
              workoutId: workoutId,
              position: position,
              courseId: courseId,
            ),
          );
    }
  }

  Future<void> _check(List<int> courseIds, PlanLength length) async {
    if (courseIds.isEmpty) {
      throw ArgumentError.value(courseIds, 'courseIds', 'At least one course');
    }
    final axes = {
      for (final id in courseIds.toSet()) (await _courses.get(id))?.axis,
    };
    if (axes.contains(null) || axes.length > 1) {
      throw ArgumentError.value(
        courseIds,
        'courseIds',
        'Existing courses on one axis',
      );
    }
    switch (length) {
      case LapCount(:final count) when count < 1:
        throw ArgumentError.value(count, 'length', 'At least one lap');
      case TimeLimit(:final time) when time.inSeconds < 1:
        throw ArgumentError.value(time, 'length', 'At least one second');
      case _:
    }
  }

  static int? _laps(PlanLength length) => switch (length) {
    LapCount(:final count) => count,
    _ => null,
  };

  static int? _durationS(PlanLength length) => switch (length) {
    TimeLimit(:final time) => time.inSeconds,
    _ => null,
  };

  Future<Workout> _workout(WorkoutRow row) async {
    final blocks =
        await (_db.select(_db.workoutBlocks)
              ..where((b) => b.workoutId.equals(row.id))
              ..orderBy([(b) => OrderingTerm.asc(b.position)]))
            .get();
    return Workout(
      id: row.id,
      name: row.name,
      courses: [for (final b in blocks) (await _courses.get(b.courseId))!],
      length: switch ((row.laps, row.durationS)) {
        (final laps?, _) => LapCount(laps),
        (_, final seconds?) => TimeLimit(Duration(seconds: seconds)),
        _ => const OpenLength(),
      },
    );
  }
}
