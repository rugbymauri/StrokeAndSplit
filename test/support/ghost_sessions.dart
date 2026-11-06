import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/templates/session_template.dart';
import 'package:drift/drift.dart';

import 'rowed_sessions.dart';

/// Stores a finished session like [storeRowedSession] together with its
/// samples: one per second, rowed evenly through each segment. Without
/// [wallClock] the samples lack the wall-clock time, as before schema 2.
Future<int> storeRowedSessionWithSamples(
  AppDatabase db, {
  int? courseVersionId,
  SessionTemplate? template,
  DateTime? startedAt,
  ErgSourceKind source = ErgSourceKind.pm5,
  bool wallClock = true,
  required List<RowedLap> laps,
}) async {
  final id = await storeRowedSession(
    db,
    courseVersionId: courseVersionId,
    template: template,
    startedAt: startedAt,
    source: source,
    laps: laps,
  );
  await storeSamples(db, id, laps, wallClock: wallClock);
  return id;
}

/// Stores the samples of [laps] rowed from the start of session [id]: one
/// per second, rowed evenly through each segment.
Future<void> storeSamples(
  AppDatabase db,
  int id,
  List<RowedLap> laps, {
  bool wallClock = true,
}) async {
  final segments = [for (final lap in laps) ...lap.segments];
  final endMs = segments.fold(0, (sum, s) => sum + s.$1);
  int distanceDmAt(int wallMs) {
    var startMs = 0;
    var startDm = 0;
    for (final (ms, metres) in segments) {
      if (wallMs <= startMs + ms) {
        return startDm + (metres * 10 * (wallMs - startMs) / ms).round();
      }
      startMs += ms;
      startDm += metres * 10;
    }
    return startDm;
  }

  await db.batch((b) {
    for (var wallMs = 0; wallMs <= endMs; wallMs += 1000) {
      b.insert(
        db.samples,
        SamplesCompanion.insert(
          sessionId: id,
          tMs: wallMs,
          distanceDm: distanceDmAt(wallMs),
          wallMs: Value(wallClock ? wallMs : null),
        ),
      );
    }
  });
}
