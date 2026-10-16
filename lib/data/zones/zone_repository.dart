import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../courses/course.dart';
import '../courses/course_layout.dart';
import '../courses/course_repository.dart';
import '../db/database.dart';
import '../db/watch.dart';
import 'zone.dart';

/// A change to a zone that would leave [courses] invalid, e.g. because the
/// zone would overlap another one or reach beyond the end.
class ZoneConflict implements Exception {
  const ZoneConflict(this.courses);

  /// The names of the courses.
  final List<String> courses;

  @override
  String toString() => 'ZoneConflict(${courses.join(', ')})';
}

/// Stores zones (Change zones).
class ZoneRepository {
  ZoneRepository(this._db);

  final AppDatabase _db;

  /// Stores a new zone and returns its id; throws an [ArgumentError] for a
  /// zone with [zoneErrors].
  Future<int> create(Zone zone) {
    _check(zone);
    return _db.into(_db.zones).insert(ZonesCompanion.insert(
          name: zone.name.trim(),
          axis: zone.axis,
          length: zone.length,
          paceFastCs: Value(zone.paceFastCs),
          paceSlowCs: Value(zone.paceSlowCs),
          spmMin: Value(zone.spmMin),
          spmMax: Value(zone.spmMax),
        ));
  }

  /// The id of a zone that is not deleted and equals [zone] apart from the
  /// id; a new zone is created when there is none, e.g. on import.
  Future<int> findOrCreate(Zone zone) async {
    for (final existing in await all()) {
      if (existing.sameAs(zone)) return existing.id;
    }
    return create(zone);
  }

  /// [definition] with every segment that has a band placed from a stored
  /// zone of the same name and bands (Design D6); segments without a zone
  /// name are named after [course] and their position (Design D5).
  Future<CourseDefinition> placeZones(String course, CourseDefinition definition) async {
    return CourseDefinition(axis: definition.axis, length: definition.length, segments: [
      for (final (i, s) in definition.segments.indexed)
        if (s.isFree)
          s
        else
          await _placed(s, s.zoneName ?? '$course ${i + 1}', definition.axis),
    ]);
  }

  Future<CourseSegment> _placed(CourseSegment segment, String name, CourseAxis axis) async {
    final zone = Zone(
      name: name,
      axis: axis,
      length: segment.length,
      paceFastCs: segment.paceFastCs,
      paceSlowCs: segment.paceSlowCs,
      spmMin: segment.spmMin,
      spmMax: segment.spmMax,
    );
    return zone.copyWith(id: await findOrCreate(zone)).segment;
  }

  /// All zones that are not deleted, by axis and name.
  Future<List<Zone>> all() async {
    final rows = await (_db.select(_db.zones)
          ..where((z) => z.deletedAt.isNull())
          ..orderBy([(z) => OrderingTerm.asc(z.axis), (z) => OrderingTerm.asc(z.name.collate(Collate.noCase))]))
        .get();
    return [for (final row in rows) _zone(row)];
  }

  /// All zones with the number of courses they are placed in.
  Future<List<ZoneUsage>> allWithUsage() async {
    final counts = {
      for (final row in await _db.customSelect('''
          SELECT cs.zone_id AS zone, COUNT(DISTINCT c.id) AS courses
          FROM course_segments cs
          JOIN course_versions v ON v.id = cs.version_id
          JOIN courses c ON c.id = v.course_id
          WHERE c.deleted_at IS NULL AND cs.zone_id IS NOT NULL
            AND v.version = (SELECT MAX(version) FROM course_versions WHERE course_id = c.id)
          GROUP BY cs.zone_id''').get())
        row.read<int>('zone'): row.read<int>('courses'),
    };
    return [for (final zone in await all()) ZoneUsage(zone, counts[zone.id] ?? 0)];
  }

  Stream<List<ZoneUsage>> watchAllWithUsage() =>
      _db.watchTables([_db.zones, _db.courses, _db.courseVersions, _db.courseSegments], allWithUsage);

  /// The zone, also when it is deleted.
  Future<Zone?> get(int id) async {
    final row = await (_db.select(_db.zones)..where((z) => z.id.equals(id))).getSingleOrNull();
    return row == null ? null : _zone(row);
  }

  /// Names of the courses whose current version contains the zone, by name.
  Future<List<String>> coursesUsing(int id) async {
    final rows = await _db.customSelect('''
        SELECT DISTINCT c.name AS name
        FROM course_segments cs
        JOIN course_versions v ON v.id = cs.version_id
        JOIN courses c ON c.id = v.course_id
        WHERE c.deleted_at IS NULL AND cs.zone_id = ?
          AND v.version = (SELECT MAX(version) FROM course_versions WHERE course_id = c.id)
        ORDER BY c.name COLLATE NOCASE''', variables: [Variable.withInt(id)]).get();
    return [for (final row in rows) row.read<String>('name')];
  }

  /// Changes name, length and bands in every course that contains the zone
  /// (Design D3); the axis only while no course contains it. Throws a
  /// [ZoneConflict] and changes nothing when a course would become invalid.
  Future<void> update(Zone zone) {
    _check(zone);
    return _db.transaction(() async {
      final old = (await get(zone.id))!;
      if (zone.axis != old.axis && (await coursesUsing(zone.id)).isNotEmpty) {
        throw ArgumentError('The axis of a zone in a course cannot change');
      }
      await (_db.update(_db.zones)..where((z) => z.id.equals(zone.id))).write(ZonesCompanion(
        name: Value(zone.name.trim()),
        axis: Value(zone.axis),
        length: Value(zone.length),
        paceFastCs: Value(zone.paceFastCs),
        paceSlowCs: Value(zone.paceSlowCs),
        spmMin: Value(zone.spmMin),
        spmMax: Value(zone.spmMax),
      ));
      await _relayoutCourses(zone.id, remove: false);
    });
  }

  /// Removes the zone from the list and from the courses containing it,
  /// which become free there (Design D4); sessions keep the name.
  Future<void> delete(int id) {
    return _db.transaction(() async {
      await (_db.update(_db.zones)..where((z) => z.id.equals(id)))
          .write(ZonesCompanion(deletedAt: Value(clock.now())));
      await _relayoutCourses(id, remove: true);
    });
  }

  /// Lays out again every course containing zone [id] and stores it with the
  /// version rule of courses: a rowed version stays, the change becomes a
  /// new one.
  Future<void> _relayoutCourses(int id, {required bool remove}) async {
    final courses = CourseRepository(_db);
    final zones = {for (final z in await all()) z.id: z};
    final conflicts = <String>[];
    final changes = <(int, CourseDefinition)>[];
    for (final course in await courses.all()) {
      final placements = course.definition.placements;
      if (!placements.any((p) => p.zoneId == id)) continue;
      final layout = resolveCourse(
        axis: course.axis,
        length: course.definition.length,
        placements: [for (final p in placements) if (!remove || p.zoneId != id) p],
        zones: zones,
      );
      if (layout.isValid) {
        changes.add((course.id, layout.definition!));
      } else {
        conflicts.add(course.name);
      }
    }
    if (conflicts.isNotEmpty) throw ZoneConflict(conflicts);
    for (final (courseId, definition) in changes) {
      await courses.updateDefinition(courseId, definition);
    }
  }

  static void _check(Zone zone) {
    final errors = zoneErrors(zone);
    if (errors.isNotEmpty) throw ArgumentError(errors.join(' '));
  }

  static Zone _zone(ZoneRow row) => Zone(
        id: row.id,
        name: row.name,
        axis: row.axis,
        length: row.length,
        paceFastCs: row.paceFastCs,
        paceSlowCs: row.paceSlowCs,
        spmMin: row.spmMin,
        spmMax: row.spmMax,
      );
}
