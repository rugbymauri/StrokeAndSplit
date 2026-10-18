import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/templates/session_template.dart';
import 'package:drift/drift.dart';

/// A lap as stored after rowing: its segments in order, each with its time
/// in ms and its distance in metres.
class RowedLap {
  const RowedLap(this.segments, {this.complete = true});

  /// A lap with a single segment.
  RowedLap.single(int ms, int metres, {bool complete = true}) : this([(ms, metres)], complete: complete);

  final List<(int, int)> segments;
  final bool complete;
}

/// Stores a finished session on [courseVersionId], or on the course of
/// [template], with [laps] one after the other from the start.
Future<int> storeRowedSession(
  AppDatabase db, {
  int? courseVersionId,
  SessionTemplate? template,
  int? plannedLaps,
  DateTime? startedAt,
  ErgSourceKind source = ErgSourceKind.pm5,
  required List<RowedLap> laps,
}) async {
  final id = await db.into(db.sessions).insert(SessionsCompanion.insert(
        startedAt: startedAt ?? DateTime(2026, 10, 1, 7),
        status: SessionStatus.complete,
        source: source,
        templateId: Value(template?.id),
        templateName: Value(template?.name),
        courseVersionId: Value(courseVersionId ?? template!.course.versionId),
        plannedLaps: Value(template == null ? plannedLaps : template.laps),
      ));
  var wallMs = 0;
  var distanceDm = 0;
  await db.batch((b) {
    for (final (i, lap) in laps.indexed) {
      final startWallMs = wallMs;
      final startDistanceDm = distanceDm;
      for (final (position, (ms, metres)) in lap.segments.indexed) {
        b.insert(db.lapSegments, LapSegmentsCompanion.insert(
          sessionId: id,
          lapNo: i + 1,
          position: position,
          durationMs: ms,
          distanceDm: metres * 10,
        ));
        wallMs += ms;
        distanceDm += metres * 10;
      }
      b.insert(db.laps, LapsCompanion.insert(
        sessionId: id,
        lapNo: i + 1,
        startWallMs: startWallMs,
        endWallMs: wallMs,
        startDistanceDm: startDistanceDm,
        endDistanceDm: distanceDm,
        complete: lap.complete,
      ));
    }
  });
  return id;
}
