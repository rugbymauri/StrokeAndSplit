import 'package:drift/drift.dart';

import '../db/database.dart';
import 'ranking.dart';

/// Computes the rankings from the stored sessions on every call, so they
/// need no upkeep when sessions change (Change statistics, Design D1).
class RankingRepository {
  RankingRepository(this._db);

  final AppDatabase _db;

  /// The complete laps on course [courseId], one ranking per length of the
  /// rowed versions, the current length first (Design D2).
  Future<List<Ranking>> course(int courseId) async {
    final rows = await _db.customSelect('''
        SELECT s.id AS session, s.started_at AS started_at, c.axis AS axis, v.length AS length, l.lap_no AS lap,
          l.start_wall_ms AS start_wall, l.end_wall_ms AS end_wall,
          l.start_distance_dm AS start_distance, l.end_distance_dm AS end_distance
        FROM laps l
        JOIN sessions s ON s.id = l.session_id
        JOIN course_versions v ON v.id = s.course_version_id
        JOIN courses c ON c.id = v.course_id
        WHERE v.course_id = ? AND l.complete = 1''', variables: [Variable.withInt(courseId)]).get();
    final current = await _db.customSelect('''
        SELECT c.axis AS axis, v.length AS length
        FROM course_versions v JOIN courses c ON c.id = v.course_id
        WHERE v.course_id = ? ORDER BY v.version DESC LIMIT 1''',
        variables: [Variable.withInt(courseId)]).getSingleOrNull();
    return _rankings(
      [for (final row in rows) (_axis(row), row.read<int>('length'), null, _entry(row, lap: row.read<int>('lap')))],
      current: current == null ? null : (_axis(current), current.read<int>('length'), null),
    );
  }

  static CourseAxis _axis(QueryRow row) => CourseAxis.values.byName(row.read<String>('axis'));

  RankingEntry _entry(QueryRow row, {int? lap, int? position, int? durationMs, int? distanceDm}) => RankingEntry(
        sessionId: row.read<int>('session'),
        startedAt: row.read<DateTime>('started_at'),
        lap: lap,
        position: position,
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
        Ranking(axis: key.$1, length: key.$2, laps: key.$3, entries: rankEntries(key.$1, groups[key]!)),
    ];
  }
}
