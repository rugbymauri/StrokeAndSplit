import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../courses/course_repository.dart';
import '../db/database.dart';
import '../db/watch.dart';
import 'session_template.dart';

/// Stores templates, each with a single block for now (Design D4).
class TemplateRepository {
  TemplateRepository(this._db) : _courses = CourseRepository(_db);

  final AppDatabase _db;
  final CourseRepository _courses;

  /// Stores a template rowing [courseId] for [laps] laps, or open laps when
  /// null, and returns its id.
  Future<int> create(String name, {required int courseId, required int? laps}) {
    _checkLaps(laps);
    return _db.transaction(() async {
      final id = await _db.into(_db.templates).insert(TemplatesCompanion.insert(name: name, createdAt: clock.now()));
      await _db.into(_db.templateBlocks).insert(
            TemplateBlocksCompanion.insert(templateId: id, position: 0, courseId: courseId, laps: Value(laps)),
          );
      return id;
    });
  }

  /// All templates by name, with their course in its newest version.
  Future<List<SessionTemplate>> all() async {
    final rows = await (_db.select(_db.templates)
          ..orderBy([(t) => OrderingTerm.asc(t.name.collate(Collate.noCase))]))
        .get();
    return [for (final row in rows) await _template(row)];
  }

  Stream<List<SessionTemplate>> watchAll() => _db.watchTables(
        [_db.templates, _db.templateBlocks, _db.courses, _db.courseVersions, _db.courseSegments],
        all,
      );

  Future<SessionTemplate?> get(int id) async {
    final row = await (_db.select(_db.templates)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _template(row);
  }

  /// Changes the template; sessions rowed with it keep their laps.
  Future<void> update(int id, {required String name, required int courseId, required int? laps}) {
    _checkLaps(laps);
    return _db.transaction(() async {
      await (_db.update(_db.templates)..where((t) => t.id.equals(id))).write(TemplatesCompanion(name: Value(name)));
      await (_db.update(_db.templateBlocks)..where((b) => b.templateId.equals(id) & b.position.equals(0)))
          .write(TemplateBlocksCompanion(courseId: Value(courseId), laps: Value(laps)));
    });
  }

  /// Deletes the template; its sessions stay and keep its name.
  Future<void> delete(int id) {
    return _db.transaction(() async {
      await (_db.update(_db.sessions)..where((s) => s.templateId.equals(id)))
          .write(const SessionsCompanion(templateId: Value(null)));
      await (_db.delete(_db.templates)..where((t) => t.id.equals(id))).go();
    });
  }

  void _checkLaps(int? laps) {
    if (laps != null && laps < 1) throw ArgumentError.value(laps, 'laps', 'At least one lap, or null for open laps');
  }

  Future<SessionTemplate> _template(TemplateRow row) async {
    final block = await (_db.select(_db.templateBlocks)
          ..where((b) => b.templateId.equals(row.id))
          ..orderBy([(b) => OrderingTerm.asc(b.position)])
          ..limit(1))
        .getSingle();
    return SessionTemplate(
      id: row.id,
      name: row.name,
      course: (await _courses.get(block.courseId))!,
      laps: block.laps,
    );
  }
}
