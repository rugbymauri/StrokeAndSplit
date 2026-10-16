import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../db/database.dart';
import '../db/watch.dart';
import 'course.dart';

/// How often a course was rowed: in all its versions and in the newest one.
typedef CourseRowCount = ({int total, int newest});

/// Stores courses with their versions (Design D4).
class CourseRepository {
  CourseRepository(this._db);

  final AppDatabase _db;

  /// Stores a new course in version 1 and returns its id.
  Future<int> create(String name, CourseDefinition definition) {
    return _db.transaction(() async {
      final id = await _db.into(_db.courses).insert(CoursesCompanion.insert(name: name, axis: definition.axis));
      await _insertVersion(id, 1, definition);
      return id;
    });
  }

  /// All courses that are not deleted, in their newest version, by name.
  Future<List<Course>> all() async {
    final rows = await (_db.select(_db.courses)
          ..where((c) => c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm.asc(c.name.collate(Collate.noCase))]))
        .get();
    return [for (final row in rows) await _withNewestVersion(row)];
  }

  Stream<List<Course>> watchAll() =>
      _db.watchTables([_db.courses, _db.courseVersions, _db.courseSegments, _db.zones], all);

  /// The course in its newest version, also when it is deleted.
  Future<Course?> get(int id) async {
    final row = await (_db.select(_db.courses)..where((c) => c.id.equals(id))).getSingleOrNull();
    return row == null ? null : _withNewestVersion(row);
  }

  /// The course as it was in the given version, e.g. as rowed in a session.
  Future<Course> atVersion(int versionId) async {
    final version = await (_db.select(_db.courseVersions)..where((v) => v.id.equals(versionId))).getSingle();
    final row = await (_db.select(_db.courses)..where((c) => c.id.equals(version.courseId))).getSingle();
    return _course(row, version);
  }

  /// A version of a course named [name] that rows like [definition],
  /// whichever zones it was placed from; null when there is none.
  Future<int?> findVersion(String name, CourseDefinition definition) async {
    final rows = await (_db.select(_db.courses)
          ..where((c) => c.name.equals(name) & c.axis.equalsValue(definition.axis) & c.deletedAt.isNull()))
        .get();
    for (final row in rows) {
      final versions = await (_db.select(_db.courseVersions)..where((v) => v.courseId.equals(row.id))).get();
      for (final version in versions) {
        if ((await _course(row, version)).definition.sameAs(definition)) return version.id;
      }
    }
    return null;
  }

  /// A version of a course named [name] with [definition]; a new course is
  /// created when there is none, e.g. for an imported session.
  Future<int> findOrCreateVersion(String name, CourseDefinition definition) {
    return _db.transaction(() async {
      final found = await findVersion(name, definition);
      if (found != null) return found;
      final id = await create(name, definition);
      return (await get(id))!.versionId;
    });
  }

  Future<void> rename(int id, String name) {
    return (_db.update(_db.courses)..where((c) => c.id.equals(id))).write(CoursesCompanion(name: Value(name)));
  }

  /// Changes length, segments or bands. A version that was rowed in a session
  /// stays as it is and the change becomes a new version; otherwise the
  /// newest version is changed in place.
  Future<void> updateDefinition(int id, CourseDefinition definition) {
    return _db.transaction(() async {
      final course = (await get(id))!;
      if (definition.axis != course.axis) throw ArgumentError('The axis of a course cannot change');
      if (definition == course.definition) return;

      final rowed = await (_db.select(_db.sessions)
            ..where((s) => s.courseVersionId.equals(course.versionId))
            ..limit(1))
          .getSingleOrNull();
      if (rowed != null) {
        await _insertVersion(id, course.version + 1, definition);
        return;
      }
      await (_db.update(_db.courseVersions)..where((v) => v.id.equals(course.versionId)))
          .write(CourseVersionsCompanion(length: Value(definition.length)));
      await (_db.delete(_db.courseSegments)..where((s) => s.versionId.equals(course.versionId))).go();
      await _insertSegments(course.versionId, definition);
    });
  }

  /// How often each course was rowed, by course id; a course never rowed is missing.
  Future<Map<int, CourseRowCount>> rowCounts() async {
    final versions = _db.courseVersions;
    final newest = versions.version.max();
    final newestRows = await (_db.selectOnly(versions)
          ..addColumns([versions.courseId, newest])
          ..groupBy([versions.courseId]))
        .get();
    final newestVersion = {for (final row in newestRows) row.read(versions.courseId)!: row.read(newest)!};

    final sessions = _db.sessions.id.count();
    final rows = await (_db.selectOnly(_db.sessions).join([
      innerJoin(versions, versions.id.equalsExp(_db.sessions.courseVersionId)),
    ])
          ..addColumns([versions.courseId, versions.version, sessions])
          ..groupBy([versions.id]))
        .get();
    final counts = <int, CourseRowCount>{};
    for (final row in rows) {
      final courseId = row.read(versions.courseId)!;
      final count = row.read(sessions)!;
      final before = counts[courseId] ?? (total: 0, newest: 0);
      counts[courseId] = (
        total: before.total + count,
        newest: row.read(versions.version) == newestVersion[courseId] ? count : before.newest,
      );
    }
    return counts;
  }

  Stream<Map<int, CourseRowCount>> watchRowCounts() =>
      _db.watchTables([_db.sessions, _db.courseVersions], rowCounts);

  /// Names of the templates that row this course.
  Future<List<String>> templatesUsing(int id) async {
    final query = _db.select(_db.templates).join([
      innerJoin(_db.templateBlocks, _db.templateBlocks.templateId.equalsExp(_db.templates.id)),
    ])
      ..where(_db.templateBlocks.courseId.equals(id))
      ..orderBy([OrderingTerm.asc(_db.templates.name)]);
    final rows = await query.get();
    return {for (final row in rows) row.readTable(_db.templates).name}.toList();
  }

  /// Removes the course from the list together with the templates using it;
  /// sessions rowed on it keep their version.
  Future<void> delete(int id) {
    return _db.transaction(() async {
      final blocks = await (_db.select(_db.templateBlocks)..where((b) => b.courseId.equals(id))).get();
      await (_db.delete(_db.templates)..where((t) => t.id.isIn(blocks.map((b) => b.templateId)))).go();
      await (_db.update(_db.courses)..where((c) => c.id.equals(id)))
          .write(CoursesCompanion(deletedAt: Value(clock.now())));
    });
  }

  Future<int> _insertVersion(int courseId, int version, CourseDefinition definition) async {
    final versionId = await _db.into(_db.courseVersions).insert(CourseVersionsCompanion.insert(
          courseId: courseId,
          version: version,
          length: definition.length,
          createdAt: clock.now(),
        ));
    await _insertSegments(versionId, definition);
    return versionId;
  }

  Future<void> _insertSegments(int versionId, CourseDefinition definition) {
    return _db.batch((b) => b.insertAll(_db.courseSegments, [
          for (final (i, s) in definition.segments.indexed)
            CourseSegmentsCompanion.insert(
              versionId: versionId,
              position: i,
              length: s.length,
              paceFastCs: Value(s.paceFastCs),
              paceSlowCs: Value(s.paceSlowCs),
              spmMin: Value(s.spmMin),
              spmMax: Value(s.spmMax),
              zoneId: Value(s.zoneId),
              zoneName: Value(s.zoneName),
            ),
        ]));
  }

  Future<Course> _withNewestVersion(CourseRow row) async {
    final version = await (_db.select(_db.courseVersions)
          ..where((v) => v.courseId.equals(row.id))
          ..orderBy([(v) => OrderingTerm.desc(v.version)])
          ..limit(1))
        .getSingle();
    return _course(row, version);
  }

  Future<Course> _course(CourseRow row, CourseVersionRow version) async {
    final segments = await (_db.select(_db.courseSegments)
          ..where((s) => s.versionId.equals(version.id))
          ..orderBy([(s) => OrderingTerm.asc(s.position)]))
        .get();
    return Course(
      id: row.id,
      name: row.name,
      versionId: version.id,
      version: version.version,
      definition: CourseDefinition(axis: row.axis, length: version.length, segments: [
        for (final s in segments)
          CourseSegment(
            length: s.length,
            paceFastCs: s.paceFastCs,
            paceSlowCs: s.paceSlowCs,
            spmMin: s.spmMin,
            spmMax: s.spmMax,
            zoneId: s.zoneId,
            zoneName: s.zoneName,
          ),
      ]),
    );
  }
}
