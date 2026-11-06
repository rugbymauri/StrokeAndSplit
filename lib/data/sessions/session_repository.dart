import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../db/database.dart';
import '../health/health_workout.dart';
import '../courses/course.dart';
import '../courses/course_repository.dart';
import '../courses/lap_tracker.dart';
import '../zones/zone_repository.dart';
import '../sources/erg_source.dart';
import 'session_plan.dart';
import 'pace_track.dart';
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
    SessionPlan? plan,
  }) {
    return _insert(
      startedAt: startedAt,
      source: source,
      protocol: protocol,
      deviceName: deviceName,
      templateId: plan?.template?.id,
      templateName: plan?.template?.name,
      courseVersionId: plan?.course.versionId,
      plannedLaps: plan?.plannedLaps,
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
    return _db
        .into(_db.sessions)
        .insert(
          SessionsCompanion.insert(
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
          ),
        );
  }

  /// Writes all rows of [batch] in one transaction.
  Future<void> write(SessionBatch batch) async {
    if (batch.isEmpty) return;
    await _db.batch((b) {
      b.insertAll(_db.samples, batch.samples);
      b.insertAll(_db.strokes, batch.strokes);
      b.insertAll(_db.rawPackets, batch.rawPackets);
      b.insertAll(_db.rrIntervals, batch.rrIntervals);
      b.insertAll(_db.pauses, batch.pauses);
      // Replaced, as the recovery finishes a lap that may be partly stored.
      b.insertAll(_db.laps, batch.laps, mode: InsertMode.insertOrReplace);
      b.insertAll(
        _db.lapSegments,
        batch.lapSegments,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// Computes the summary from the stored rows and closes the session.
  Future<void> finish(
    int id, {
    SessionStatus status = SessionStatus.complete,
    DateTime? endedAt,
  }) async {
    final samples = _db.samples;
    final values =
        await (_db.selectOnly(samples)
              ..addColumns([
                samples.tMs.max(),
                samples.activeMs.max(),
                samples.distanceDm.max(),
                samples.watts.avg(),
                samples.heartRate.avg(),
                samples.heartRate.max(),
              ])
              ..where(samples.sessionId.equals(id)))
            .getSingle();
    final strokeCount =
        await (_db.selectOnly(_db.strokes)
              ..addColumns([countAll()])
              ..where(_db.strokes.sessionId.equals(id)))
            .map((row) => row.read(countAll())!)
            .getSingle();

    // The session time without pauses; sessions before schema 7 only have the monitor's time.
    final durationMs =
        values.read(samples.activeMs.max()) ??
        values.read(samples.tMs.max()) ??
        0;
    final pauses = _db.pauses;
    final pauseValues =
        await (_db.selectOnly(pauses)
              ..addColumns([
                countAll(),
                (pauses.endWallMs - pauses.startWallMs).sum(),
              ])
              ..where(pauses.sessionId.equals(id)))
            .getSingle();
    final distanceDm = values.read(samples.distanceDm.max()) ?? 0;
    final averageWatts = values.read(samples.watts.avg());
    final averageHeartRate = values.read(samples.heartRate.avg());
    final rr =
        await (_db.selectOnly(_db.rrIntervals)
              ..addColumns([_db.rrIntervals.rrMs])
              ..where(_db.rrIntervals.sessionId.equals(id))
              ..orderBy([
                OrderingTerm.asc(_db.rrIntervals.tMs),
                OrderingTerm.asc(_db.rrIntervals.rowId),
              ]))
            .map((row) => row.read(_db.rrIntervals.rrMs)!)
            .get();
    await (_db.update(_db.sessions)..where((s) => s.id.equals(id))).write(
      SessionsCompanion(
        status: Value(status),
        endedAt: Value(endedAt),
        durationMs: Value(durationMs),
        distanceDm: Value(distanceDm),
        // Pace per 500 m in centiseconds: duration / distance * 500 m.
        averagePaceCs: Value(
          distanceDm > 0 ? (durationMs / 10 * 5000 / distanceDm).round() : null,
        ),
        averageWatts: Value(averageWatts?.round()),
        averageStrokeRate: Value(
          durationMs > 0 && strokeCount > 0
              ? strokeCount * 60000 / durationMs
              : null,
        ),
        strokeCount: Value(strokeCount),
        averageHeartRate: Value(averageHeartRate?.round()),
        maxHeartRate: Value(values.read(samples.heartRate.max())),
        rmssdMs: Value(rmssd(rr)),
        pauseCount: Value(pauseValues.read(countAll())!),
        pausedMs: Value(
          pauseValues.read((pauses.endWallMs - pauses.startWallMs).sum()) ?? 0,
        ),
      ),
    );
  }

  /// Closes sessions that were still recording when the app ended and marks
  /// them as incomplete. Returns how many there were.
  Future<int> recoverInterrupted() async {
    final interrupted = await (_db.select(
      _db.sessions,
    )..where((s) => s.status.equalsValue(SessionStatus.recording))).get();
    for (final session in interrupted) {
      if (session.courseVersionId != null) await _finishLastLap(session);
      await finish(session.id, status: SessionStatus.incomplete);
    }
    return interrupted.length;
  }

  /// Finishes the lap that was running when the app ended from the stored
  /// samples (Design D5); the finished laps are stored already.
  Future<void> _finishLastLap(SessionRow session) async {
    final course = await CourseRepository(_db)
        .atVersion(session.courseVersionId!);
    final last =
        await (_db.select(_db.laps)
              ..where(
                (l) => l.sessionId.equals(session.id) & l.complete.equals(true),
              )
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
    // The laps run on the session time; sessions before schema 7 only have the wall clock (auto-pause, Design D2).
    final samples =
        await (_db.select(_db.samples)
              ..where(
                (s) =>
                    s.sessionId.equals(session.id) &
                    coalesce([s.activeMs, s.wallMs])
                        .isBiggerOrEqualValue(last?.endWallMs ?? 0),
              )
              ..orderBy([(s) => OrderingTerm.asc(s.rowId)]))
            .get();
    for (final s in samples) {
      tracker.add(
        TrackPoint(
          wallMs: s.activeMs ?? s.wallMs!,
          distanceDm: s.distanceDm,
          paceCs: s.paceCs,
          strokeRate: s.strokeRate,
        ),
      );
    }
    tracker.finish();
    await write(
      SessionBatch(
        samples: const [],
        strokes: const [],
        rawPackets: const [],
        laps: [for (final l in tracker.takeLaps()) lapCompanion(session.id, l)],
        lapSegments: [
          for (final s in tracker.takeSegments())
            segmentCompanion(session.id, s),
        ],
      ),
    );
  }

  /// All sessions, newest first.
  Stream<List<SessionRow>> watchAll() {
    return (_db.select(
      _db.sessions,
    )..orderBy([(s) => OrderingTerm.desc(s.startedAt)])).watch();
  }

  Stream<SessionRow?> watch(int id) => (_db.select(
    _db.sessions,
  )..where((s) => s.id.equals(id))).watchSingleOrNull();

  Future<SessionRow?> get(int id) => (_db.select(
    _db.sessions,
  )..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<void> delete(int id) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.samples,
      )..where((r) => r.sessionId.equals(id))).go();
      await (_db.delete(
        _db.strokes,
      )..where((r) => r.sessionId.equals(id))).go();
      await (_db.delete(
        _db.rawPackets,
      )..where((r) => r.sessionId.equals(id))).go();
      await (_db.delete(_db.laps)..where((r) => r.sessionId.equals(id))).go();
      await (_db.delete(
        _db.lapSegments,
      )..where((r) => r.sessionId.equals(id))).go();
      await (_db.delete(
        _db.rrIntervals,
      )..where((r) => r.sessionId.equals(id))).go();
      await (_db.delete(_db.pauses)..where((r) => r.sessionId.equals(id))).go();
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

  /// The pauses of a session in order (Change auto-pause, Design D3).
  Future<List<PauseRow>> pauses(int id) =>
      (_db.select(_db.pauses)
            ..where((p) => p.sessionId.equals(id))
            ..orderBy([(p) => OrderingTerm.asc(p.startWallMs)]))
          .get();

  /// The RR intervals of a session in the order of their end times, on the
  /// session's wall-clock axis.
  Future<List<RrIntervalRow>> rrIntervals(int id) =>
      (_db.select(_db.rrIntervals)
            ..where((r) => r.sessionId.equals(id))
            ..orderBy([
              (r) => OrderingTerm.asc(r.tMs),
              (r) => OrderingTerm.asc(r.rowId),
            ]))
          .get();

  /// The lowest heart rate of a stored session; null without one. Not stored with the session, so older
  /// sessions show it as well.
  Future<int?> minHeartRate(int id) async {
    final lowest = _db.samples.heartRate.min();
    final row =
        await (_db.selectOnly(_db.samples)
              ..addColumns([lowest])
              ..where(
                _db.samples.sessionId.equals(id) &
                    _db.samples.heartRate.isBiggerThanValue(0),
              ))
            .getSingle();
    return row.read(lowest);
  }

  /// The pace of a stored session in steps of rowed time, without its pauses; empty without samples.
  Future<PaceTrack> paceTrack(int id) async {
    final time = coalesce([_db.samples.activeMs, _db.samples.tMs]);
    final rows =
        await (_db.selectOnly(_db.samples)
              ..addColumns([time, _db.samples.distanceDm])
              ..where(_db.samples.sessionId.equals(id))
              ..orderBy([OrderingTerm.asc(_db.samples.tMs)]))
            .get();
    return PaceTrack.of([
      for (final row in rows)
        (row.read(time)!, row.read(_db.samples.distanceDm)!),
    ]);
  }

  /// What the export to Health Connect needs of a stored session (Change health-connect, Design D3); null
  /// when there is no such session. Sessions before schema 2 have no wall clock, so their time is the rower's.
  Future<HealthSessionData?> healthData(int id) async {
    final session = await get(id);
    if (session == null) return null;
    final samples = _db.samples;
    final wall = coalesce([samples.wallMs, samples.tMs]);
    final rows =
        await (_db.selectOnly(samples)
              ..addColumns([
                wall,
                samples.heartRate,
                samples.watts,
                samples.paceCs,
                samples.calories,
              ])
              ..where(samples.sessionId.equals(id))
              ..orderBy([OrderingTerm.asc(samples.tMs)]))
            .get();
    return HealthSessionData(
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      distanceDm: session.distanceDm,
      templateName: session.templateName,
      points: [
        for (final row in rows)
          HealthPoint(
            wallMs: row.read(wall)!,
            heartRate: row.read(samples.heartRate),
            watts: row.read(samples.watts),
            paceCs: row.read(samples.paceCs),
            calories: row.read(samples.calories),
          ),
      ],
      laps: [
        for (final lap in await laps(id))
          (
            startMs: lap.startWallMs,
            endMs: lap.endWallMs,
            distanceDm: lap.endDistanceDm - lap.startDistanceDm,
          ),
      ],
      pauses: [
        for (final p in await pauses(id))
          (startWallMs: p.startWallMs, endWallMs: p.endWallMs),
      ],
    );
  }

  /// Records that the session was written to Health Connect [at] that moment (Design D6).
  Future<void> markHealthExported(int id, DateTime at) =>
      (_db.update(_db.sessions)..where((s) => s.id.equals(id))).write(
        SessionsCompanion(healthExportedAt: Value(at)),
      );

  /// Records that the session is not in Health Connect after all, e.g. after a failed write.
  Future<void> clearHealthExported(int id) =>
      (_db.update(_db.sessions)..where((s) => s.id.equals(id))).write(
        const SessionsCompanion(healthExportedAt: Value(null)),
      );

  Future<bool> hasRawPackets(int id) async {
    final row =
        await (_db.select(_db.rawPackets)
              ..where((r) => r.sessionId.equals(id))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// The raw notifications of a session, in the Stroke & Split raw format.
  Future<RawRecording> rawRecording(int id) async {
    final session = await get(id);
    if (session == null) throw StateError('No session $id');
    final rows =
        await (_db.select(_db.rawPackets)
              ..where((r) => r.sessionId.equals(id))
              ..orderBy([
                (r) => OrderingTerm.asc(r.tMs),
                (r) => OrderingTerm.asc(r.rowId),
              ]))
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
          RawPacket(
            time: Duration(milliseconds: r.tMs),
            characteristicId: r.characteristicId,
            bytes: r.bytes,
          ),
      ],
    );
  }

  /// The session as a `.strokesplit` file (Design D8): gzip-compressed lines
  /// in the Stroke & Split raw format, with the summary in the header, and template and
  /// course of a session on a course (Design D7).
  Future<List<int>> export(int id) async {
    final session = (await get(id))!;
    final recording = await rawRecording(id);
    final versionId = session.courseVersionId;
    final course = versionId == null
        ? null
        : await CourseRepository(_db).atVersion(versionId);
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
        'pauseCount': session.pauseCount,
        'pausedMs': session.pausedMs,
      },
    };
    final lines = RawRecording(
      metadata: metadata,
      packets: recording.packets,
    ).toLines();
    return gzip.encode(utf8.encode('${lines.join('\n')}\n'));
  }

  /// Imports a `.strokesplit` or older `.aergrow` file or an uncompressed raw recording. Samples,
  /// strokes, RR intervals and summary are derived from the raw notifications
  /// again, so
  /// decoder fixes apply to imported sessions too. The session is marked as
  /// imported and counts in no ranking (Change statistics, Design D3).
  /// Returns the new id.
  Future<int> import(List<int> bytes) async {
    final isGzip = bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;
    final text = utf8.decode(isGzip ? gzip.decode(bytes) : bytes);
    final recording = RawRecording.parseLines(
      const LineSplitter().convert(text),
    );
    final metadata = recording.metadata;
    final session = metadata['session'] as Map<String, Object?>? ?? const {};
    final template = metadata['template'] as Map<String, Object?>?;
    final course = switch (metadata['course']) {
      final Map<String, Object?> json => (
        name: json['name']! as String,
        definition: _courseDefinition(json),
      ),
      _ => null,
    };

    // Files from before FTMS support name no protocol and are PM5 recordings.
    final protocol = ErgProtocol.parse(metadata['protocol']);
    final id = await _insert(
      startedAt:
          DateTime.tryParse(metadata['recordedAt'] as String? ?? '') ??
          clock.now(),
      source:
          ErgSourceKind.values.asNameMap()[metadata['source']] ??
          ErgSourceKind.pm5,
      protocol: protocol,
      deviceName: metadata['device'] as String?,
      templateName: template?['name'] as String?,
      courseVersionId: course == null
          ? null
          : await _importCourse(course.name, course.definition),
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
      status: session['status'] == SessionStatus.incomplete.name
          ? SessionStatus.incomplete
          : SessionStatus.complete,
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
          'resistanceLevel': ?s.resistanceLevel,
          if (s.zoneName case final name?)
            'zone': {
              'name': name,
              'axis': course.axis.name,
              'length': s.length,
              'paceFastCs': ?s.paceFastCs,
              'paceSlowCs': ?s.paceSlowCs,
              'spmMin': ?s.spmMin,
              'spmMax': ?s.spmMax,
              'resistanceLevel': ?s.resistanceLevel,
            },
        },
    ],
  };

  static CourseDefinition _courseDefinition(
    Map<String, Object?> json,
  ) => CourseDefinition(
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
          resistanceLevel: s['resistanceLevel'] as int?,
          zoneName: (s['zone'] as Map<String, Object?>?)?['name'] as String?,
        ),
    ],
  );
}
