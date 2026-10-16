import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../courses/lap_tracker.dart';
import '../db/database.dart';
import '../sources/erg_source.dart';
import '../sources/erg_source_providers.dart';
import '../templates/session_template.dart';
import 'session_accumulator.dart';
import 'session_repository.dart';

/// The local database; opened in `main` and overridden there.
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('Open the database in main'));

final sessionRepositoryProvider = Provider<SessionRepository>((ref) => SessionRepository(ref.watch(databaseProvider)));

/// All stored sessions, newest first.
final sessionsProvider = StreamProvider<List<SessionRow>>((ref) => ref.watch(sessionRepositoryProvider).watchAll());

final sessionProvider = StreamProvider.family<SessionRow?, int>(
  (ref, id) => ref.watch(sessionRepositoryProvider).watch(id),
);

/// The laps of a session on a course, in order.
final sessionLapsProvider = StreamProvider.family<List<LapRow>, int>(
  (ref, id) => ref.watch(sessionRepositoryProvider).watchLaps(id),
);

/// A session being recorded right now.
class ActiveRecording {
  const ActiveRecording({required this.sessionId, required this.progress, this.template, this.lap});

  final int sessionId;

  /// Time and distance since the session started.
  final SessionProgress progress;

  /// What is rowed; null for a free session.
  final SessionTemplate? template;

  /// Where the session is on the course of [template].
  final LapProgress? lap;
}

/// A session that ended by itself after its last lap, until the live
/// display has shown its summary.
final finishedSessionProvider = NotifierProvider<FinishedSession, int?>(FinishedSession.new);

class FinishedSession extends Notifier<int?> {
  @override
  int? build() => null;

  void report(int sessionId) => state = sessionId;

  void clear() => state = null;
}

/// How often buffered rows are written; at most this much is lost when the
/// app ends unexpectedly.
final recordingFlushIntervalProvider = Provider((ref) => const Duration(seconds: 2));

final sessionRecorderProvider = NotifierProvider<SessionRecorder, ActiveRecording?>(SessionRecorder.new);

/// Records the active source into a session until it is stopped.
class SessionRecorder extends Notifier<ActiveRecording?> {
  SessionAccumulator? _accumulator;
  StreamSubscription<RawPacket>? _packets;
  Timer? _flushTimer;
  var _writes = Future<void>.value();

  @override
  ActiveRecording? build() {
    ref.onDispose(_stopListening);
    return null;
  }

  SessionRepository get _repository => ref.read(sessionRepositoryProvider);

  /// Starts a session with the active source; time and distance count from
  /// zero, whatever the PM5 shows at the moment. With a [template] the
  /// session follows its course and ends by itself after the last lap.
  Future<void> start({SessionTemplate? template}) async {
    if (state != null) return;
    final source = ref.read(activeErgSourceProvider);
    if (source == null) throw StateError('No data source');

    final id = await _repository.create(
      startedAt: clock.now(),
      source: source.kind,
      deviceName: source.kind == ErgSourceKind.pm5 ? source.name : null,
      template: template,
    );
    final accumulator = _accumulator = SessionAccumulator(
      id,
      course: template?.course.definition,
      plannedLaps: template?.laps,
    );
    ActiveRecording current() => ActiveRecording(
          sessionId: id,
          progress: accumulator.progress,
          template: template,
          lap: accumulator.lapProgress,
        );
    state = current();
    _packets = source.packets.listen((packet) {
      accumulator.add(packet);
      // On a course the rest of a time segment runs on while paused.
      if (template != null || accumulator.progress != state?.progress) state = current();
      if (accumulator.lapsFinished) unawaited(_finishAfterLastLap());
    });
    _flushTimer = Timer.periodic(ref.read(recordingFlushIntervalProvider), (_) => _flush());
  }

  Future<void> _finishAfterLastLap() async {
    final id = await stop();
    if (id != null) ref.read(finishedSessionProvider.notifier).report(id);
  }

  /// Ends the session, stores its summary and returns its id.
  Future<int?> stop() async {
    final recording = state;
    final accumulator = _accumulator;
    if (recording == null || accumulator == null) return null;
    _stopListening();
    accumulator.finish();
    _flush();
    await _writes;
    await _repository.finish(recording.sessionId, endedAt: clock.now());
    _accumulator = null;
    state = null;
    return recording.sessionId;
  }

  void _flush() {
    final batch = _accumulator?.takeBatch();
    if (batch == null || batch.isEmpty) return;
    final repository = _repository;
    // Chained, so batches are written in order.
    _writes = _writes.then((_) => repository.write(batch));
  }

  void _stopListening() {
    _packets?.cancel();
    _packets = null;
    _flushTimer?.cancel();
    _flushTimer = null;
  }
}
