import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show immutable, mapEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../sessions/session_providers.dart';
import '../sources/erg_source.dart';
import 'ranking.dart';
import 'ranking_providers.dart';
import 'ranking_repository.dart';

/// Where the laps, zones and the whole of one session stand in their rankings
/// right now, only places 1–3 (Change statistics, Design D6).
@immutable
class SessionPlaces {
  const SessionPlaces({
    this.session,
    this.laps = const {},
    this.zones = const {},
  });

  static const none = SessionPlaces();

  /// The place of the session in the ranking of its workout.
  final int? session;

  /// The place of each lap in the ranking of its course, by lap number.
  final Map<int, int> laps;

  /// The place of each zone run in the ranking of its zone, by lap number and
  /// position of the segment.
  final Map<(int, int), int> zones;

  @override
  bool operator ==(Object other) =>
      other is SessionPlaces &&
      other.session == session &&
      mapEquals(other.laps, laps) &&
      mapEquals(other.zones, zones);

  @override
  int get hashCode => Object.hash(
    session,
    Object.hashAllUnordered(laps.entries.map((e) => (e.key, e.value))),
    Object.hashAllUnordered(zones.entries.map((e) => (e.key, e.value))),
  );

  @override
  String toString() =>
      'SessionPlaces(session $session, laps $laps, zones $zones)';
}

/// Looks up a session in the rankings of its workout, course and zones.
class SessionPlacesRepository {
  SessionPlacesRepository(this._db, this._rankings);

  final AppDatabase _db;
  final RankingRepository _rankings;

  static const _podium = 3;

  Future<SessionPlaces> places(int sessionId) async {
    final session = await _db
        .customSelect(
          '''
        SELECT s.source AS source, s.workout_id AS workout FROM sessions s WHERE s.id = ?''',
          variables: [Variable.withInt(sessionId)],
        )
        .getSingleOrNull();
    final courses = await _db
        .customSelect(
          '''
        SELECT sc.course_version_id AS version, v.course_id AS course
        FROM session_courses sc JOIN course_versions v ON v.id = sc.course_version_id
        WHERE sc.session_id = ? ORDER BY sc.position''',
          variables: [Variable.withInt(sessionId)],
        )
        .get();
    // Sessions of the simulator or a replay never count (Design D3).
    final source = session == null
        ? null
        : ErgSourceKind.values.byName(session.read<String>('source'));
    if (session == null || courses.isEmpty) {
      return SessionPlaces.none;
    }
    if (source != ErgSourceKind.pm5 && source != ErgSourceKind.ftms) {
      return SessionPlaces.none;
    }

    /// The places of this session's entries in [rankings], by [key].
    Map<K, int> places<K>(
      List<Ranking> rankings,
      K Function(RankingEntry) key,
    ) => {
      for (final ranking in rankings)
        for (final (i, entry) in ranking.entries.take(_podium).indexed)
          if (entry.sessionId == sessionId) key(entry): i + 1,
    };

    final workoutId = session.read<int?>('workout');
    final zoneIds = await _db
        .customSelect(
          'SELECT DISTINCT zone_id AS zone FROM course_segments '
          'WHERE version_id IN (${List.filled(courses.length, '?').join(', ')}) AND zone_id IS NOT NULL',
          variables: [
            for (final c in courses) Variable.withInt(c.read<int>('version')),
          ],
        )
        .map((row) => row.read<int>('zone'))
        .get();
    return SessionPlaces(
      session: workoutId == null
          ? null
          : places(await _rankings.workout(workoutId), (_) => 0)[0],
      // A lap of a chain runs several courses, so only a single course
      // places its laps (Change workout-course-chain).
      laps: courses.length == 1
          ? places(
              await _rankings.course(courses.single.read<int>('course')),
              (e) => e.lap!,
            )
          : const {},
      zones: {
        for (final zoneId in zoneIds)
          ...places(await _rankings.zone(zoneId), (e) => (e.lap!, e.position!)),
      },
    );
  }
}

final sessionPlacesRepositoryProvider = Provider<SessionPlacesRepository>(
  (ref) => SessionPlacesRepository(
    ref.watch(databaseProvider),
    ref.watch(rankingRepositoryProvider),
  ),
);

/// The current places 1–3 of a session, again after every change to the
/// rankings, e.g. when a later session overtakes it.
final sessionPlacesProvider = StreamProvider.family<SessionPlaces, int>((
  ref,
  sessionId,
) {
  final repository = ref.watch(sessionPlacesRepositoryProvider);
  return ref
      .watch(rankingRepositoryProvider)
      .watch(() => repository.places(sessionId));
});
