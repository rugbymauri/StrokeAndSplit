import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../courses/course_repository.dart';
import '../db/database.dart';
import '../db/watch.dart';
import 'workout.dart';

/// Stores workouts, each with a single block for now (Design D4).
class WorkoutRepository {
  WorkoutRepository(this._db) : _courses = CourseRepository(_db);

  final AppDatabase _db;
  final CourseRepository _courses;

  /// Stores a workout rowing [courseId] for [laps] laps, or open laps when
  /// null, and returns its id.
  Future<int> create(String name, {required int courseId, required int? laps}) {
    _checkLaps(laps);
    return _db.transaction(() async {
      final id = await _db
          .into(_db.workouts)
          .insert(WorkoutsCompanion.insert(name: name, createdAt: clock.now()));
      await _db
          .into(_db.workoutBlocks)
          .insert(
            WorkoutBlocksCompanion.insert(
              workoutId: id,
              position: 0,
              courseId: courseId,
              laps: Value(laps),
            ),
          );
      return id;
    });
  }

  /// All workouts by name, with their course in its newest version.
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

  /// Changes the workout; sessions rowed with it keep their laps.
  Future<void> update(
    int id, {
    required String name,
    required int courseId,
    required int? laps,
  }) {
    _checkLaps(laps);
    return _db.transaction(() async {
      await (_db.update(_db.workouts)..where((t) => t.id.equals(id))).write(
        WorkoutsCompanion(name: Value(name)),
      );
      await (_db.update(
        _db.workoutBlocks,
      )..where((b) => b.workoutId.equals(id) & b.position.equals(0))).write(
        WorkoutBlocksCompanion(courseId: Value(courseId), laps: Value(laps)),
      );
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

  void _checkLaps(int? laps) {
    if (laps != null && laps < 1) {
      throw ArgumentError.value(
        laps,
        'laps',
        'At least one lap, or null for open laps',
      );
    }
  }

  Future<Workout> _workout(WorkoutRow row) async {
    final block =
        await (_db.select(_db.workoutBlocks)
              ..where((b) => b.workoutId.equals(row.id))
              ..orderBy([(b) => OrderingTerm.asc(b.position)])
              ..limit(1))
            .getSingle();
    return Workout(
      id: row.id,
      name: row.name,
      course: (await _courses.get(block.courseId))!,
      laps: block.laps,
    );
  }
}
