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
  /// The session rows a single course (Change workout-course-chain, D4).
  static const _single =
      '(SELECT COUNT(*) FROM session_courses x WHERE x.session_id = s.id) = 1';

  static final _counted =
      "s.source IN ('${ErgSourceKind.pm5.name}', '${ErgSourceKind.ftms.name}') AND s.imported = 0";

  /// The complete runs over course [courseId], one ranking per length of the
  /// rowed versions, the current length first (Design D2). A session with
  /// this course alone runs it once per complete lap; in a chain each lap
  /// runs it once, complete when its end was reached (Change
  /// workout-course-chain, Design D4).
  Future<List<Ranking>> course(int courseId) async {
    final laps = await _db
        .customSelect(
          '''
        SELECT s.id AS session, s.started_at AS started_at, c.axis AS axis, v.length AS length, l.lap_no AS lap,
          l.start_wall_ms AS start_wall, l.end_wall_ms AS end_wall,
          l.start_distance_dm AS start_distance, l.end_distance_dm AS end_distance
        FROM laps l
        JOIN sessions s ON s.id = l.session_id
        JOIN session_courses sc ON sc.session_id = s.id
        JOIN course_versions v ON v.id = sc.course_version_id
        JOIN courses c ON c.id = v.course_id
        WHERE v.course_id = ? AND c.deleted_at IS NULL AND l.complete = 1 AND $_counted
          AND $_single''',
          variables: [Variable.withInt(courseId)],
        )
        .get();
    final runs = await _db
        .customSelect(
          '''
        SELECT s.id AS session, s.started_at AS started_at, c.axis AS axis, v.length AS length,
          l.lap_no AS lap, sc.first_segment AS position,
          l.start_wall_ms AS lap_wall, l.start_distance_dm AS lap_distance,
          (SELECT COALESCE(SUM(b.duration_ms), 0) FROM lap_segments b WHERE b.session_id = l.session_id
            AND b.lap_no = l.lap_no AND b.position < sc.first_segment) AS before_wall,
          (SELECT COALESCE(SUM(b.distance_dm), 0) FROM lap_segments b WHERE b.session_id = l.session_id
            AND b.lap_no = l.lap_no AND b.position < sc.first_segment) AS before_distance,
          SUM(ls.duration_ms) AS duration, SUM(ls.distance_dm) AS distance
        FROM session_courses sc
        JOIN sessions s ON s.id = sc.session_id
        JOIN course_versions v ON v.id = sc.course_version_id
        JOIN courses c ON c.id = v.course_id
        JOIN (SELECT version_id, COUNT(*) AS count FROM course_segments GROUP BY version_id) n
          ON n.version_id = v.id
        JOIN laps l ON l.session_id = s.id
        JOIN lap_segments ls ON ls.session_id = l.session_id AND ls.lap_no = l.lap_no
          AND ls.position >= sc.first_segment AND ls.position < sc.first_segment + n.count
        WHERE v.course_id = ? AND c.deleted_at IS NULL AND $_counted AND NOT $_single
          AND (l.complete = 1 OR EXISTS (SELECT 1 FROM lap_segments b WHERE b.session_id = l.session_id
            AND b.lap_no = l.lap_no AND b.position >= sc.first_segment + n.count))
        GROUP BY sc.session_id, sc.position, l.lap_no
        HAVING COUNT(*) = n.count''',
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
        for (final row in laps)
          (
            axis: _axis(row),
            length: row.read<int>('length'),
            laps: null,
            courseLengths: null,
            entry: _entry(row, lap: row.read<int>('lap')),
          ),
        for (final row in runs)
          (
            axis: _axis(row),
            length: row.read<int>('length'),
            laps: null,
            courseLengths: null,
            entry: _segmentEntry(row),
          ),
      ],
      current: current == null
          ? null
          : (_axis(current), current.read<int>('length'), null, null),
    );
  }

  /// The segments of complete laps on which zone [zoneId] lay, one ranking
  /// per length of the zone when rowed, the current length first (Design
  /// D2). Start and end follow from the start of the lap and the segments
  /// before (Design D5). A lap segment belongs to the course of the session
  /// whose segments it falls into (Change workout-course-chain, Design D4).
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
        JOIN session_courses sc ON sc.session_id = ls.session_id
        JOIN course_segments cs ON cs.version_id = sc.course_version_id
          AND cs.position = ls.position - sc.first_segment
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
          (
            axis: _axis(row),
            length: row.read<int>('length'),
            laps: null,
            courseLengths: null,
            entry: _segmentEntry(row),
          ),
      ],
      current: current == null
          ? null
          : (_axis(current), current.read<int>('length'), null, null),
    );
  }

  /// The sessions on workout [workoutId] with all planned laps complete,
  /// ranked by the sum of their laps; one ranking per order of course
  /// lengths and number of laps, the current ones first (Design D2; Change
  /// workout-course-chain, Design D4). A workout with an open number of laps
  /// or a duration has no ranking.
  Future<List<Ranking>> workout(int workoutId) async {
    final workout = await _db
        .customSelect(
          'SELECT laps FROM workouts WHERE id = ?',
          variables: [Variable.withInt(workoutId)],
        )
        .getSingleOrNull();
    final laps = workout?.read<int?>('laps');
    if (laps == null) return [];
    final blocks = await _db
        .customSelect(
          '''
        SELECT c.axis AS axis,
          (SELECT v.length FROM course_versions v WHERE v.course_id = b.course_id
            ORDER BY v.version DESC LIMIT 1) AS length
        FROM workout_blocks b JOIN courses c ON c.id = b.course_id
        WHERE b.workout_id = ? ORDER BY b.position''',
          variables: [Variable.withInt(workoutId)],
        )
        .get();
    if (blocks.isEmpty) return [];
    final currentLengths = [for (final b in blocks) b.read<int>('length')];

    final rows = await _db
        .customSelect(
          '''
        SELECT s.id AS session, s.started_at AS started_at, s.planned_laps AS laps,
          MIN(l.start_wall_ms) AS start_wall, MAX(l.end_wall_ms) AS end_wall,
          MIN(l.start_distance_dm) AS start_distance, MAX(l.end_distance_dm) AS end_distance,
          SUM(l.end_wall_ms - l.start_wall_ms) AS duration, SUM(l.end_distance_dm - l.start_distance_dm) AS distance
        FROM sessions s
        JOIN laps l ON l.session_id = s.id
        WHERE s.workout_id = ? AND l.complete = 1 AND l.lap_no <= s.planned_laps AND $_counted
        GROUP BY s.id
        HAVING COUNT(*) = s.planned_laps''',
          variables: [Variable.withInt(workoutId)],
        )
        .get();
    final chains = await _chains([
      for (final r in rows) r.read<int>('session'),
    ]);
    return _rankings(
      [
        for (final row in rows)
          if (chains[row.read<int>('session')] case (final axis, final lengths))
            (
              axis: axis,
              length: lengths.fold(0, (sum, l) => sum + l),
              laps: row.read<int>('laps'),
              courseLengths: lengths,
              entry: _entry(
                row,
                durationMs: row.read<int>('duration'),
                distanceDm: row.read<int>('distance'),
              ),
            ),
      ],
      current: (
        _axis(blocks.first),
        currentLengths.fold(0, (sum, l) => sum + l),
        laps,
        currentLengths,
      ),
    );
  }

  /// The complete laps of sessions on workout [workoutId], one ranking per
  /// order of course lengths, none current; the ghost of the lap track of a
  /// workout with several courses (Change workout-course-chain, Design D5).
  Future<List<Ranking>> workoutLaps(int workoutId) async {
    final rows = await _db
        .customSelect(
          '''
        SELECT s.id AS session, s.started_at AS started_at, l.lap_no AS lap,
          l.start_wall_ms AS start_wall, l.end_wall_ms AS end_wall,
          l.start_distance_dm AS start_distance, l.end_distance_dm AS end_distance
        FROM laps l
        JOIN sessions s ON s.id = l.session_id
        WHERE s.workout_id = ? AND l.complete = 1 AND $_counted''',
          variables: [Variable.withInt(workoutId)],
        )
        .get();
    final chains = await _chains(
      {for (final r in rows) r.read<int>('session')}.toList(),
    );
    return _rankings([
      for (final row in rows)
        if (chains[row.read<int>('session')] case (final axis, final lengths))
          (
            axis: axis,
            length: lengths.fold(0, (sum, l) => sum + l),
            laps: null,
            courseLengths: lengths,
            entry: _entry(row, lap: row.read<int>('lap')),
          ),
    ], current: null);
  }

  /// The axis and the course lengths in their order of each of [sessionIds].
  Future<Map<int, (CourseAxis, List<int>)>> _chains(
    List<int> sessionIds,
  ) async {
    if (sessionIds.isEmpty) return const {};
    final rows = await _db
        .customSelect(
          '''
        SELECT sc.session_id AS session, c.axis AS axis, v.length AS length
        FROM session_courses sc
        JOIN course_versions v ON v.id = sc.course_version_id
        JOIN courses c ON c.id = v.course_id
        WHERE sc.session_id IN (${List.filled(sessionIds.length, '?').join(', ')})
        ORDER BY sc.session_id, sc.position''',
          variables: [for (final id in sessionIds) Variable.withInt(id)],
        )
        .get();
    final chains = <int, (CourseAxis, List<int>)>{};
    for (final row in rows) {
      final session = row.read<int>('session');
      final chain = chains[session] ??= (_axis(row), <int>[]);
      chain.$2.add(row.read<int>('length'));
    }
    return chains;
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
    _db.sessionCourses,
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

  /// One ranking per axis, length, number of laps and order of course
  /// lengths; [current] first, the others by length.
  static List<Ranking> _rankings(
    List<
      ({
        CourseAxis axis,
        int length,
        int? laps,
        List<int>? courseLengths,
        RankingEntry entry,
      })
    >
    rows, {
    required (CourseAxis, int, int?, List<int>?)? current,
  }) {
    String key(CourseAxis axis, int length, int? laps, List<int>? lengths) =>
        '${axis.name}|$length|$laps|${lengths?.join(',')}';
    final groups =
        <String, (CourseAxis, int, int?, List<int>?, List<RankingEntry>)>{};
    for (final r in rows) {
      final group = groups[key(r.axis, r.length, r.laps, r.courseLengths)] ??= (
        r.axis,
        r.length,
        r.laps,
        r.courseLengths,
        [],
      );
      group.$5.add(r.entry);
    }
    final currentKey = current == null
        ? null
        : key(current.$1, current.$2, current.$3, current.$4);
    final keys = groups.keys.toList()
      ..sort((a, b) {
        if (a == currentKey || b == currentKey) return a == currentKey ? -1 : 1;
        final (ga, gb) = (groups[a]!, groups[b]!);
        final byLength = ga.$2.compareTo(gb.$2);
        if (byLength != 0) return byLength;
        final byAxis = ga.$1.index.compareTo(gb.$1.index);
        if (byAxis != 0) return byAxis;
        final byLaps = (ga.$3 ?? 0).compareTo(gb.$3 ?? 0);
        return byLaps != 0 ? byLaps : a.compareTo(b);
      });
    return [
      for (final k in keys)
        if (groups[k] case (
          final axis,
          final length,
          final laps,
          final lengths,
          final entries,
        ))
          Ranking(
            axis: axis,
            length: length,
            laps: laps,
            courseLengths: lengths,
            entries: rankEntries(axis, entries),
          ),
    ];
  }
}
