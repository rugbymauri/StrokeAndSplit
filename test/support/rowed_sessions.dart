import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/workouts/workout.dart';
import 'package:drift/drift.dart';

import 'session_rows.dart';

/// A lap as stored after rowing: its segments in order, each with its time
/// in ms and its distance in metres.
class RowedLap {
  const RowedLap(this.segments, {this.complete = true});

  /// A lap with a single segment.
  RowedLap.single(int ms, int metres, {bool complete = true})
    : this([(ms, metres)], complete: complete);

  final List<(int, int)> segments;
  final bool complete;
}

/// Stores a finished session on [courseVersionId], or on the courses of
/// [workout], with [laps] one after the other from the start; a lap of a
/// workout with several courses has the segments of all of them.
Future<int> storeRowedSession(
  AppDatabase db, {
  int? courseVersionId,
  Workout? workout,
  int? plannedLaps,
  Duration? plannedDuration,
  DateTime? startedAt,
  ErgSourceKind source = ErgSourceKind.pm5,
  required List<RowedLap> laps,
}) async {
  final id = await insertSession(
    db,
    SessionsCompanion.insert(
      startedAt: startedAt ?? DateTime(2026, 10, 1, 7),
      status: SessionStatus.complete,
      source: source,
      workoutId: Value(workout?.id),
      workoutName: Value(workout?.name),
      plannedLaps: Value(workout == null ? plannedLaps : workout.laps),
      plannedDurationMs: Value(plannedDuration?.inMilliseconds),
    ),
    courseVersionIds: courseVersionId != null
        ? [courseVersionId]
        : [for (final c in workout!.courses) c.versionId],
  );
  var wallMs = 0;
  var distanceDm = 0;
  await db.batch((b) {
    for (final (i, lap) in laps.indexed) {
      final startWallMs = wallMs;
      final startDistanceDm = distanceDm;
      for (final (position, (ms, metres)) in lap.segments.indexed) {
        b.insert(
          db.lapSegments,
          LapSegmentsCompanion.insert(
            sessionId: id,
            lapNo: i + 1,
            position: position,
            durationMs: ms,
            distanceDm: metres * 10,
          ),
        );
        wallMs += ms;
        distanceDm += metres * 10;
      }
      b.insert(
        db.laps,
        LapsCompanion.insert(
          sessionId: id,
          lapNo: i + 1,
          startWallMs: startWallMs,
          endWallMs: wallMs,
          startDistanceDm: startDistanceDm,
          endDistanceDm: distanceDm,
          complete: lap.complete,
        ),
      );
    }
  });
  return id;
}
