import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../db/database.dart';
import '../courses/course.dart';
import '../courses/course_repository.dart';
import '../courses/lap_tracker.dart';
import '../zones/zone_repository.dart';
import '../sources/erg_source.dart';
import '../templates/session_template.dart';
import 'session_accumulator.dart';

/// The root mean square of successive differences of [intervalsMs], rounded
/// to whole milliseconds; null with fewer than two intervals (Design D5).
int? rmssd(List<int> intervalsMs) {
  if (intervalsMs.length < 2) return null;
  var sum = 0;
  for (var i = 1; i < intervalsMs.length; i++) {
    final difference = intervalsMs[i] - intervalsMs[i - 1];
    sum += difference * difference;
  }
  return sqrt(sum / (intervalsMs.length - 1)).round();
}

/// Stores sessions with their samples, strokes and raw notifications.
class SessionRepository {
  SessionRepository(this._db);

  final AppDatabase _db;

  /// Starts a session; with a [template] it rows the course in the version
  /// the template uses now.
  Future<int> create({
    required DateTime startedAt,
    required ErgSourceKind source,
    ErgProtocol protocol = ErgProtocol.pm5,
    String? deviceName,
    SessionTemplate? template,
  }) {
    return _insert(
      startedAt: startedAt,
      source: source,
      protocol: protocol,
      deviceName: deviceName,
      templateId: template?.id,
      templateName: template?.name,
      courseVersionId: template?.course.versionId,
      plannedLaps: template?.laps,
    );
  }

  Future<int> _insert({
    required DateTime startedAt,
    required ErgSourceKind source,
    required ErgProtocol protocol,
    String? deviceName,
    int? templateId,
    String? templateName,
    int? courseVersionId,
    int? plannedLaps,
    bool imported = false,
  }) {
    return _db.into(_db.sessions).insert(SessionsCompanion.insert(
          startedAt: startedAt,
          status: SessionStatus.recording,
          source: source,
          protocol: Value(protocol),
          deviceName: Value(deviceName),
          templateId: Value(templateId),
          templateName: Value(templateName),
          courseVersionId: Value(courseVersionId),
          plannedLaps: Value(plannedLaps),
          imported: Value(imported),
        ));
  }

  /// Writes all rows of [batch] in one transaction.
  Future<void> write(SessionBatch batch) async {
    if (batch.isEmpty) return;
    await _db.batch((b) {
      b.insertAll(_db.samples, batch.samples);
      b.insertAll(_db.strokes, batch.strokes);
      b.insertAll(_db.rawPackets, batch.rawPackets);
      b.insertAll(_db.rrIntervals, batch.rrIntervals);
      // Replaced, as the recovery finishes a lap that may be partly stored.
      b.insertAll(_db.laps, batch.laps, mode: InsertMode.insertOrReplace);
      b.insertAll(_db.lapSegments, batch.lapSegments, mode: InsertMode.insertOrReplace);
    });
  }

  /// Computes the summary from the stored rows and closes the session.
  Future<void> finish(int id, {SessionStatus status = SessionStatus.complete, DateTime? endedAt}) async {
    final samples = _db.samples;
    final values = await (_db.selectOnly(samples)
          ..addColumns([
            samples.tMs.max(),
            samples.distanceDm.max(),
            samples.watts.avg(),
            samples.heartRate.avg(),
            samples.heartRate.max(),
          ])
          ..where(samples.sessionId.equals(id)))
        .getSingle();
    final strokeCount = await (_db.selectOnly(_db.strokes)
          ..addColumns([countAll()])
          ..where(_db.strokes.sessionId.equals(id)))
        .map((row) => row.read(countAll())!)
        .getSingle();

    final durationMs = values.read(samples.tMs.max()) ?? 0;
    final distanceDm = values.read(samples.distanceDm.max()) ?? 0;
    final averageWatts = values.read(samples.watts.avg());
    final averageHeartRate = values.read(samples.heartRate.avg());
    final rr = await (_db.selectOnly(_db.rrIntervals)
          ..addColumns([_db.rrIntervals.rrMs])
          ..where(_db.rrIntervals.sessionId.equals(id))
          ..orderBy([OrderingTerm.asc(_db.rrIntervals.tMs), OrderingTerm.asc(_db.rrIntervals.rowId)]))
        .map((row) => row.read(_db.rrIntervals.rrMs)!)
        .get();
    await (_db.update(_db.sessions)..where((s) => s.id.equals(id))).write(SessionsCompanion(
      status: Value(status),
      endedAt: Value(endedAt),
      durationMs: Value(durationMs),
      distanceDm: Value(distanceDm),
      // Pace per 500 m in centiseconds: duration / distance * 500 m.
      averagePaceCs: Value(distanceDm > 0 ? (durationMs / 10 * 5000 / distanceDm).round() : null),
      averageWatts: Value(averageWatts?.round()),
      averageStrokeRate: Value(durationMs > 0 && strokeCount > 0 ? strokeCount * 60000 / durationMs : null),
      strokeCount: Value(strokeCount),
      averageHeartRate: Value(averageHeartRate?.round()),
      maxHeartRate: Value(values.read(samples.heartRate.max())),
      rmssdMs: Value(rmssd(rr)),
    ));
  }

  /// Closes sessions that were still recording when the app ended and marks
  /// them as incomplete. Returns how many there were.
  Future<int> recoverInterrupted() async {
    final interrupted =
        await (_db.select(_db.sessions)..where((s) => s.status.equalsValue(SessionStatus.recording))).get();
    for (final session in interrupted) {
      if (session.courseVersionId != null) await _finishLastLap(session);
      await finish(session.id, status: SessionStatus.incomplete);
    }
    return interrupted.length;
  }

  /// Finishes the lap that was running when the app ended from the stored
  /// samples (Design D5); the finished laps are stored already.
  Future<void> _finishLastLap(SessionRow session) async {
    final course = await CourseRepository(_db).atVersion(session.courseVersionId!);
    final last = await (_db.select(_db.laps)
          ..where((l) => l.sessionId.equals(session.id) & l.complete.equals(true))
          ..orderBy([(l) => OrderingTerm.desc(l.lapNo)])
          ..limit(1))
        .getSingleOrNull();
    final lap = (last?.lapNo ?? 0) + 1;
    if (session.plannedLaps != null && lap > session.plannedLaps!) return;

    final tracker = LapTracker(
      course.definition,
      plannedLaps: session.plannedLaps,
      startLap: lap,
      startWallMs: last?.endWallMs ?? 0,
      startDistanceDm: last?.endDistanceDm ?? 0,
    );
    final samples = await (_db.select(_db.samples)
          ..where((s) => s.sessionId.equals(session.id) & s.wallMs.isBiggerOrEqualValue(last?.endWallMs ?? 0))
          ..orderBy([(s) => OrderingTerm.asc(s.rowId)]))
        .get();
    for (final s in samples) {
      tracker.add(TrackPoint(wallMs: s.wallMs!, distanceDm: s.distanceDm, paceCs: s.paceCs, strokeRate: s.strokeRate));
    }
    tracker.finish();
    await write(SessionBatch(
      samples: const [],
      strokes: const [],
      rawPackets: const [],
      laps: [for (final l in tracker.takeLaps()) lapCompanion(session.id, l)],
      lapSegments: [for (final s in tracker.takeSegments()) segmentCompanion(session.id, s)],
    ));
  }

  /// All sessions, newest first.
  Stream<List<SessionRow>> watchAll() {
    return (_db.select(_db.sessions)..orderBy([(s) => OrderingTerm.desc(s.startedAt)])).watch();
  }

  Stream<SessionRow?> watch(int id) => (_db.select(_db.sessions)..where((s) => s.id.equals(id))).watchSingleOrNull();

  Future<SessionRow?> get(int id) => (_db.select(_db.sessions)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<void> delete(int id) {
    return _db.transaction(() async {
      await (_db.delete(_db.samples)..where((r) => r.sessionId.equals(id))).go();
      await (_db.delete(_db.strokes)..where((r) => r.sessionId.equals(id))).go();
      await (_db.delete(_db.rawPackets)..where((r) => r.sessionId.equals(id))).go();
      await (_db.delete(_db.laps)..where((r) => r.sessionId.equals(id))).go();
      await (_db.delete(_db.lapSegments)..where((r) => r.sessionId.equals(id))).go();
      await (_db.delete(_db.rrIntervals)..where((r) => r.sessionId.equals(id))).go();
      await (_db.delete(_db.sessions)..where((s) => s.id.equals(id))).go();
    });
  }

  /// The laps of a session on a course, in order.
  Future<List<LapRow>> laps(int id) => _laps(id).get();

  Stream<List<LapRow>> watchLaps(int id) => _laps(id).watch();

  SimpleSelectStatement<$LapsTable, LapRow> _laps(int id) {
    return _db.select(_db.laps)
      ..where((l) => l.sessionId.equals(id))
      ..orderBy([(l) => OrderingTerm.asc(l.lapNo)]);
  }

  /// The RR intervals of a session in the order of their end times, on the
  /// session's wall-clock axis.
  Future<List<RrIntervalRow>> rrIntervals(int id) => (_db.select(_db.rrIntervals)
        ..where((r) => r.sessionId.equals(id))
        ..orderBy([(r) => OrderingTerm.asc(r.tMs), (r) => OrderingTerm.asc(r.rowId)]))
      .get();

  Future<bool> hasRawPackets(int id) async {
    final row = await (_db.select(_db.rawPackets)
          ..where((r) => r.sessionId.equals(id))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// The raw notifications of a session, in the AergRow raw format.
  Future<RawRecording> rawRecording(int id) async {
    final session = await get(id);
    if (session == null) throw StateError('No session $id');
    final rows = await (_db.select(_db.rawPackets)
          ..where((r) => r.sessionId.equals(id))
          ..orderBy([(r) => OrderingTerm.asc(r.tMs), (r) => OrderingTerm.asc(r.rowId)]))
        .get();
    return RawRecording(
      metadata: {
        'format': RawRecording.formatName,
        'version': 1,
        'source': session.source.name,
        'protocol': session.protocol.name,
        'device': ?session.deviceName,
        'recordedAt': session.startedAt.toUtc().toIso8601String(),
      },
      packets: [
        for (final r in rows)
          RawPacket(time: Duration(milliseconds: r.tMs), characteristicId: r.characteristicId, bytes: r.bytes),
      ],
    );
  }

  /// The session as an `.aergrow` file (Design D8): gzip-compressed lines in
  /// the AergRow raw format, with the summary in the header, and template and
  /// course of a session on a course (Design D7).
  Future<List<int>> export(int id) async {
    final session = (await get(id))!;
    final recording = await rawRecording(id);
    final versionId = session.courseVersionId;
    final course = versionId == null ? null : await CourseRepository(_db).atVersion(versionId);
    final metadata = {
      ...recording.metadata,
      if (course != null) ...{
        'template': {'name': session.templateName, 'laps': session.plannedLaps},
        'course': _courseJson(course),
      },
      'session': {
        'status': session.status.name,
        'endedAt': ?session.endedAt?.toUtc().toIso8601String(),
        'durationMs': session.durationMs,
        'distanceDm': session.distanceDm,
        'averagePaceCs': ?session.averagePaceCs,
        'averageWatts': ?session.averageWatts,
        'averageStrokeRate': ?session.averageStrokeRate,
        'strokeCount': session.strokeCount,
        'averageHeartRate': ?session.averageHeartRate,
        'maxHeartRate': ?session.maxHeartRate,
        'rmssdMs': ?session.rmssdMs,
      },
    };
    final lines = RawRecording(metadata: metadata, packets: recording.packets).toLines();
    return gzip.encode(utf8.encode('${lines.join('\n')}\n'));
  }

  /// Imports an `.aergrow` file or an uncompressed raw recording. Samples,
  /// strokes, RR intervals and summary are derived from the raw notifications
  /// again, so
  /// decoder fixes apply to imported sessions too. The session is marked as
  /// imported and counts in no ranking (Change statistics, Design D3).
  /// Returns the new id.
  Future<int> import(List<int> bytes) async {
    final isGzip = bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;
    final text = utf8.decode(isGzip ? gzip.decode(bytes) : bytes);
    final recording = RawRecording.parseLines(const LineSplitter().convert(text));
    final metadata = recording.metadata;
    final session = metadata['session'] as Map<String, Object?>? ?? const {};
    final template = metadata['template'] as Map<String, Object?>?;
    final course = switch (metadata['course']) {
      final Map<String, Object?> json => (name: json['name']! as String, definition: _courseDefinition(json)),
      _ => null,
    };

    // Files from before FTMS support name no protocol and are PM5 recordings.
    final protocol = ErgProtocol.parse(metadata['protocol']);
    final id = await _insert(
      startedAt: DateTime.tryParse(metadata['recordedAt'] as String? ?? '') ?? clock.now(),
      source: ErgSourceKind.values.asNameMap()[metadata['source']] ?? ErgSourceKind.pm5,
      protocol: protocol,
      deviceName: metadata['device'] as String?,
      templateName: template?['name'] as String?,
      courseVersionId: course == null ? null : await _importCourse(course.name, course.definition),
      plannedLaps: template?['laps'] as int?,
      imported: true,
    );
    final accumulator = SessionAccumulator(
      id,
      protocol: protocol,
      course: course?.definition,
      plannedLaps: template?['laps'] as int?,
    );
    recording.packets.forEach(accumulator.add);
    accumulator.finish();
    await write(accumulator.takeBatch());
    await finish(
      id,
      status: session['status'] == SessionStatus.incomplete.name ? SessionStatus.incomplete : SessionStatus.complete,
      endedAt: DateTime.tryParse(session['endedAt'] as String? ?? ''),
    );
    return id;
  }

  /// The version of an imported course: one that rows the same, or a new
  /// course with its zones, which are created when missing (Design D6).
  Future<int> _importCourse(String name, CourseDefinition definition) {
    return _db.transaction(() async {
      final courses = CourseRepository(_db);
      final found = await courses.findVersion(name, definition);
      if (found != null) return found;
      final placed = await ZoneRepository(_db).placeZones(name, definition);
      return courses.findOrCreateVersion(name, placed);
    });
  }

  static Map<String, Object?> _courseJson(Course course) => {
        'name': course.name,
        'axis': course.axis.name,
        'length': course.definition.length,
        'segments': [
          for (final s in course.definition.segments)
            {
              'length': s.length,
              'paceFastCs': ?s.paceFastCs,
              'paceSlowCs': ?s.paceSlowCs,
              'spmMin': ?s.spmMin,
              'spmMax': ?s.spmMax,
              if (s.zoneName case final name?)
                'zone': {
                  'name': name,
                  'axis': course.axis.name,
                  'length': s.length,
                  'paceFastCs': ?s.paceFastCs,
                  'paceSlowCs': ?s.paceSlowCs,
                  'spmMin': ?s.spmMin,
                  'spmMax': ?s.spmMax,
                },
            },
        ],
      };

  static CourseDefinition _courseDefinition(Map<String, Object?> json) => CourseDefinition(
        axis: CourseAxis.values.byName(json['axis']! as String),
        length: json['length']! as int,
        segments: [
          for (final s in (json['segments']! as List).cast<Map<String, Object?>>())
            CourseSegment(
              length: s['length']! as int,
              paceFastCs: s['paceFastCs'] as int?,
              paceSlowCs: s['paceSlowCs'] as int?,
              spmMin: s['spmMin'] as int?,
              spmMax: s['spmMax'] as int?,
              zoneName: (s['zone'] as Map<String, Object?>?)?['name'] as String?,
            ),
        ],
      );
}
