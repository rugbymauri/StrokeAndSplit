import 'package:drift/drift.dart';

import '../db/database.dart';
import '../statistics/ranking.dart';
import 'ghost.dart';

/// Rebuilds how a ranking entry went from the samples of its session
/// (Change ghost, Design D2, D3); the schema stays as it is.
class GhostRepository {
  GhostRepository(this._db);

  final AppDatabase _db;

  /// The course of [entry] from its beginning to its end, with wall-clock
  /// time and distance counted from its beginning; null if its session has
  /// no samples in that span, e.g. one recorded before schema 2 without
  /// wall-clock times.
  Future<GhostTrack?> track(RankingEntry entry) async {
    // Laps run on the session time; sessions before schema 7 only have the
    // wall clock, which was their session time (Change auto-pause, Design D2).
    Expression<int> time(Samples s) => coalesce([s.activeMs, s.wallMs]);
    final samples = await (_db.select(_db.samples)
          ..where((s) =>
              s.sessionId.equals(entry.sessionId) & time(s).isBetweenValues(entry.startWallMs, entry.endWallMs))
          ..orderBy([(s) => OrderingTerm.asc(time(s)), (s) => OrderingTerm.asc(s.wallMs)]))
        .get();
    if (samples.isEmpty) return null;

    final durationMs = entry.endWallMs - entry.startWallMs;
    final distanceDm = entry.endDistanceDm - entry.startDistanceDm;
    final points = [const GhostPoint(wallMs: 0, distanceDm: 0)];
    for (final sample in samples) {
      // The boundaries of the entry lie between two samples; the distance
      // within the entry never goes back, even if a counter wobbles.
      final rowed = (sample.distanceDm - entry.startDistanceDm).clamp(points.last.distanceDm, distanceDm);
      points.add(GhostPoint(wallMs: (sample.activeMs ?? sample.wallMs!) - entry.startWallMs, distanceDm: rowed));
    }
    points.add(GhostPoint(wallMs: durationMs, distanceDm: distanceDm));
    return GhostTrack(points);
  }
}
