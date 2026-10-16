import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:pm5_protocol/pm5_protocol.dart';

import '../db/database.dart';
import '../sources/erg_source.dart';
import '../templates/session_template.dart';
import 'session_accumulator.dart';

/// Stores sessions with their samples, strokes and raw notifications.
class SessionRepository {
  SessionRepository(this._db);

  final AppDatabase _db;

  /// Starts a session; with a [template] it rows the course in the version
  /// the template uses now.
  Future<int> create({
    required DateTime startedAt,
    required ErgSourceKind source,
    String? deviceName,
    SessionTemplate? template,
  }) {
    return _db.into(_db.sessions).insert(SessionsCompanion.insert(
          startedAt: startedAt,
          status: SessionStatus.recording,
          source: source,
          deviceName: Value(deviceName),
          templateId: Value(template?.id),
          templateName: Value(template?.name),
          courseVersionId: Value(template?.course.versionId),
          plannedLaps: Value(template?.laps),
        ));
  }

  /// Writes all rows of [batch] in one transaction.
  Future<void> write(SessionBatch batch) async {
    if (batch.isEmpty) return;
    await _db.batch((b) {
      b.insertAll(_db.samples, batch.samples);
      b.insertAll(_db.strokes, batch.strokes);
      b.insertAll(_db.rawPackets, batch.rawPackets);
      // Replaced, as the recovery finishes a lap that may be partly stored.
      b.insertAll(_db.laps, batch.laps, mode: InsertMode.insertOrReplace);
      b.insertAll(_db.lapSegments, batch.lapSegments, mode: InsertMode.insertOrReplace);
    });
  }

  /// Computes the summary from the stored rows and closes the session.
  Future<void> finish(int id, {SessionStatus status = SessionStatus.complete, DateTime? endedAt}) async {
    final samples = _db.samples;
    final values = await (_db.selectOnly(samples)
          ..addColumns([samples.tMs.max(), samples.distanceDm.max(), samples.watts.avg()])
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
    ));
  }

  /// Closes sessions that were still recording when the app ended and marks
  /// them as incomplete. Returns how many there were.
  Future<int> recoverInterrupted() async {
    final interrupted = await (_db.select(_db.sessions)..where((s) => s.status.equalsValue(SessionStatus.recording))).get();
    for (final session in interrupted) {
      await finish(session.id, status: SessionStatus.incomplete);
    }
    return interrupted.length;
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
      await (_db.delete(_db.sessions)..where((s) => s.id.equals(id))).go();
    });
  }

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
  /// the AergRow raw format, with the summary in the header.
  Future<List<int>> export(int id) async {
    final session = (await get(id))!;
    final recording = await rawRecording(id);
    final metadata = {
      ...recording.metadata,
      'session': {
        'status': session.status.name,
        'endedAt': ?session.endedAt?.toUtc().toIso8601String(),
        'durationMs': session.durationMs,
        'distanceDm': session.distanceDm,
        'averagePaceCs': ?session.averagePaceCs,
        'averageWatts': ?session.averageWatts,
        'averageStrokeRate': ?session.averageStrokeRate,
        'strokeCount': session.strokeCount,
      },
    };
    final lines = RawRecording(metadata: metadata, packets: recording.packets).toLines();
    return gzip.encode(utf8.encode('${lines.join('\n')}\n'));
  }

  /// Imports an `.aergrow` file or an uncompressed raw recording. Samples,
  /// strokes and summary are derived from the raw notifications again, so
  /// decoder fixes apply to imported sessions too. Returns the new id.
  Future<int> import(List<int> bytes) async {
    final isGzip = bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;
    final text = utf8.decode(isGzip ? gzip.decode(bytes) : bytes);
    final recording = RawRecording.parseLines(const LineSplitter().convert(text));
    final metadata = recording.metadata;
    final session = metadata['session'] as Map<String, Object?>? ?? const {};

    final id = await create(
      startedAt: DateTime.tryParse(metadata['recordedAt'] as String? ?? '') ?? clock.now(),
      source: ErgSourceKind.values.asNameMap()[metadata['source']] ?? ErgSourceKind.pm5,
      deviceName: metadata['device'] as String?,
    );
    final accumulator = SessionAccumulator(id);
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
}
