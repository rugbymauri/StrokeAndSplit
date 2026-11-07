import 'package:drift/drift.dart';

import '../db/database.dart';
import '../db/watch.dart';
import '../sources/erg_source.dart';
import 'ranking.dart';

/// Computes the rankings from the stored sessions on every call, so they
/// need no upkeep when sessions change (Change statistics, Design D1).
class RankingRepository {
  RankingRepository(this._db);

  final AppDatabase _db;

  /// Only sessions rowed on an erg on this device count, none imported (Design D3).
  static final _counted =
      "s.source IN ('${ErgSourceKind.pm5.name}', '${ErgSourceKind.ftms.name}') AND s.imported = 0";

  /// The complete laps on course [courseId], one ranking per length of the
  /// rowed versions, the current length first (Design D2).
  Future<List<Ranking>> course(int courseId) async {
    final rows = await _db
        .customSelect(
          '''
        SELECT s.id AS session, s.started_at AS started_at, c.axis AS axis, v.length AS length, l.lap_no AS lap,
          l.start_wall_ms AS start_wall, l.end_wall_ms AS end_wall,
          l.start_distance_dm AS start_distance, l.end_distance_dm AS end_distance
        FROM laps l
        JOIN sessions s ON s.id = l.session_id
        JOIN course_versions v ON v.id = s.course_version_id
        JOIN courses c ON c.id = v.course_id
        WHERE v.course_id = ? AND c.deleted_at IS NULL AND l.complete = 1 AND $_counted''',
          variables: [Variable.withInt(courseId)],
        )
        .get();
    final current = await _db
        .customSelect(
          '''
        SELECT c.axis AS axis, v.length AS length
        FROM course_versions v JOIN courses c ON c.id = v.course_id
        WHERE v.course_id = ? ORDER BY v.version DESC LIMIT 1''',
          variables: [Variable.withInt(courseId)],
        )
        .getSingleOrNull();
    return _rankings(
      [
        for (final row in rows)
          (
            _axis(row),
            row.read<int>('length'),
            null,
            _entry(row, lap: row.read<int>('lap')),
          ),
      ],
      current: current == null
          ? null
          : (_axis(current), current.read<int>('length'), null),
    );
  }

  /// The segments of complete laps on which zone [zoneId] lay, one ranking
  /// per length of the zone when rowed, the current length first (Design
  /// D2). Start and end follow from the start of the lap and the segments
  /// before (Design D5).
  Future<List<Ranking>> zone(int zoneId) async {
    final rows = await _db
        .customSelect(
          '''
        SELECT s.id AS session, s.started_at AS started_at, c.axis AS axis, cs.length AS length,
          ls.lap_no AS lap, ls.position AS position, ls.duration_ms AS duration, ls.distance_dm AS distance,
          l.start_wall_ms AS lap_wall, l.start_distance_dm AS lap_distance,
          (SELECT COALESCE(SUM(b.duration_ms), 0) FROM lap_segments b
            WHERE b.session_id = ls.session_id AND b.lap_no = ls.lap_no AND b.position < ls.position) AS before_wall,
          (SELECT COALESCE(SUM(b.distance_dm), 0) FROM lap_segments b
            WHERE b.session_id = ls.session_id AND b.lap_no = ls.lap_no AND b.position < ls.position) AS before_distance
        FROM lap_segments ls
        JOIN laps l ON l.session_id = ls.session_id AND l.lap_no = ls.lap_no
        JOIN sessions s ON s.id = ls.session_id
        JOIN course_segments cs ON cs.version_id = s.course_version_id AND cs.position = ls.position
        JOIN course_versions v ON v.id = cs.version_id
        JOIN courses c ON c.id = v.course_id
        JOIN zones z ON z.id = cs.zone_id
        WHERE cs.zone_id = ? AND z.deleted_at IS NULL AND l.complete = 1 AND $_counted''',
          variables: [Variable.withInt(zoneId)],
        )
        .get();
    final current = await _db
        .customSelect(
          'SELECT axis, length FROM zones WHERE id = ?',
          variables: [Variable.withInt(zoneId)],
        )
        .getSingleOrNull();
    return _rankings(
      [
        for (final row in rows)
          (_axis(row), row.read<int>('length'), null, _segmentEntry(row)),
      ],
      current: current == null
          ? null
          : (_axis(current), current.read<int>('length'), null),
    );
  }

  /// The sessions on workout [workoutId] with all planned laps complete,
  /// ranked by the sum of their laps; one ranking per course length and
  /// number of laps, the current ones first (Design D2). A workout with an
  /// open number of laps has no ranking.
  Future<List<Ranking>> workout(int workoutId) async {
    final current = await _db
        .customSelect(
          '''
        SELECT c.axis AS axis, v.length AS length, b.laps AS laps
        FROM workout_blocks b
        JOIN courses c ON c.id = b.course_id
        JOIN course_versions v ON v.course_id = c.id
        WHERE b.workout_id = ? AND b.position = 0
        ORDER BY v.version DESC LIMIT 1''',
          variables: [Variable.withInt(workoutId)],
        )
        .getSingleOrNull();
    final laps = current?.read<int?>('laps');
    if (current == null || laps == null) return [];

    final rows = await _db
        .customSelect(
          '''
        SELECT s.id AS session, s.started_at AS started_at, c.axis AS axis, v.length AS length, s.planned_laps AS laps,
          MIN(l.start_wall_ms) AS start_wall, MAX(l.end_wall_ms) AS end_wall,
          MIN(l.start_distance_dm) AS start_distance, MAX(l.end_distance_dm) AS end_distance,
          SUM(l.end_wall_ms - l.start_wall_ms) AS duration, SUM(l.end_distance_dm - l.start_distance_dm) AS distance
        FROM sessions s
        JOIN laps l ON l.session_id = s.id
        JOIN course_versions v ON v.id = s.course_version_id
        JOIN courses c ON c.id = v.course_id
        WHERE s.workout_id = ? AND l.complete = 1 AND l.lap_no <= s.planned_laps AND $_counted
        GROUP BY s.id
        HAVING COUNT(*) = s.planned_laps''',
          variables: [Variable.withInt(workoutId)],
        )
        .get();
    return _rankings(
      [
        for (final row in rows)
          (
            _axis(row),
            row.read<int>('length'),
            row.read<int>('laps'),
            _entry(
              row,
              durationMs: row.read<int>('duration'),
              distanceDm: row.read<int>('distance'),
            ),
          ),
      ],
      current: (_axis(current), current.read<int>('length'), laps),
    );
  }

  /// [load] now and again after every change to sessions, laps, courses,
  /// zones or workouts, e.g. a new, imported or deleted session.
  Stream<T> watch<T>(Future<T> Function() load) => _db.watchTables([
    _db.sessions,
    _db.laps,
    _db.lapSegments,
    _db.courses,
    _db.courseVersions,
    _db.courseSegments,
    _db.zones,
    _db.workouts,
    _db.workoutBlocks,
  ], load);

  static RankingEntry _segmentEntry(QueryRow row) {
    final startWallMs =
        row.read<int>('lap_wall') + row.read<int>('before_wall');
    final startDistanceDm =
        row.read<int>('lap_distance') + row.read<int>('before_distance');
    return RankingEntry(
      sessionId: row.read<int>('session'),
      startedAt: row.read<DateTime>('started_at'),
      lap: row.read<int>('lap'),
      position: row.read<int>('position'),
      startWallMs: startWallMs,
      endWallMs: startWallMs + row.read<int>('duration'),
      startDistanceDm: startDistanceDm,
      endDistanceDm: startDistanceDm + row.read<int>('distance'),
    );
  }

  static CourseAxis _axis(QueryRow row) =>
      CourseAxis.values.byName(row.read<String>('axis'));

  static RankingEntry _entry(
    QueryRow row, {
    int? lap,
    int? durationMs,
    int? distanceDm,
  }) => RankingEntry(
    sessionId: row.read<int>('session'),
    startedAt: row.read<DateTime>('started_at'),
    lap: lap,
    startWallMs: row.read<int>('start_wall'),
    endWallMs: row.read<int>('end_wall'),
    startDistanceDm: row.read<int>('start_distance'),
    endDistanceDm: row.read<int>('end_distance'),
    durationMs: durationMs,
    distanceDm: distanceDm,
  );

  /// One ranking per axis, length and number of laps; [current] first, the
  /// others by length.
  static List<Ranking> _rankings(
    List<(CourseAxis, int, int?, RankingEntry)> rows, {
    required (CourseAxis, int, int?)? current,
  }) {
    final groups = <(CourseAxis, int, int?), List<RankingEntry>>{};
    for (final (axis, length, laps, entry) in rows) {
      (groups[(axis, length, laps)] ??= []).add(entry);
    }
    final keys = groups.keys.toList()
      ..sort((a, b) {
        if (a == current || b == current) return a == current ? -1 : 1;
        final byLength = a.$2.compareTo(b.$2);
        if (byLength != 0) return byLength;
        final byAxis = a.$1.index.compareTo(b.$1.index);
        return byAxis != 0 ? byAxis : (a.$3 ?? 0).compareTo(b.$3 ?? 0);
      });
    return [
      for (final key in keys)
        Ranking(
          axis: key.$1,
          length: key.$2,
          laps: key.$3,
          entries: rankEntries(key.$1, groups[key]!),
        ),
    ];
  }
}
