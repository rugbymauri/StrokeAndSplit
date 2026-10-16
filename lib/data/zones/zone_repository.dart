import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../db/database.dart';
import 'zone.dart';

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

  Stream<List<ZoneUsage>> watchAllWithUsage() {
    return _db
        .customSelect('SELECT 1', readsFrom: {_db.zones, _db.courses, _db.courseVersions, _db.courseSegments})
        .watch()
        .asyncMap((_) => allWithUsage());
  }

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

  /// Changes name, length and bands; the axis only while no course contains
  /// the zone.
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
    });
  }

  /// Removes the zone from the list.
  Future<void> delete(int id) {
    return (_db.update(_db.zones)..where((z) => z.id.equals(id))).write(ZonesCompanion(deletedAt: Value(clock.now())));
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
