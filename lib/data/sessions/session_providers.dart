import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../courses/course.dart';
import '../courses/lap_tracker.dart';
import '../db/database.dart';
import '../health/health_export.dart';
import '../sources/erg_source.dart';
import '../sources/erg_source_providers.dart';
import 'session_plan.dart';
import 'first_stroke.dart';
import 'pace_track.dart';
import 'session_accumulator.dart';
import 'session_repository.dart';

/// The local database; opened in `main` and overridden there.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('Open the database in main'),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(databaseProvider)),
);

/// All stored sessions, newest first.
final sessionsProvider = StreamProvider<List<SessionRow>>(
  (ref) => ref.watch(sessionRepositoryProvider).watchAll(),
);

final sessionProvider = StreamProvider.family<SessionRow?, int>(
  (ref, id) => ref.watch(sessionRepositoryProvider).watch(id),
);

/// The courses a stored session rowed, in their order; empty for a free
/// session (Change workout-course-chain).
final sessionCoursesProvider = FutureProvider.family<List<Course>, int>(
  (ref, id) => ref.watch(sessionRepositoryProvider).courses(id),
);

/// The laps of a session on a course, in order.
final sessionLapsProvider = StreamProvider.family<List<LapRow>, int>(
  (ref, id) => ref.watch(sessionRepositoryProvider).watchLaps(id),
);

/// The RR intervals of a stored session, oldest first; empty without a strap.
final sessionRrIntervalsProvider =
    FutureProvider.family<List<RrIntervalRow>, int>(
      (ref, id) => ref.watch(sessionRepositoryProvider).rrIntervals(id),
    );

/// The lowest heart rate of a stored session; null without one.
final sessionMinHeartRateProvider = FutureProvider.family<int?, int>(
  (ref, id) => ref.watch(sessionRepositoryProvider).minHeartRate(id),
);

/// The pace of a stored session over its rowed time; empty without samples.
final sessionPaceTrackProvider = FutureProvider.family<PaceTrack, int>(
  (ref, id) => ref.watch(sessionRepositoryProvider).paceTrack(id),
);

/// A session being recorded right now, or with a workout one that is ready
/// and starts with the first stroke.
class ActiveRecording {
  const ActiveRecording({
    required this.sessionId,
    required this.progress,
    this.plan,
    this.ghost = true,
    this.lap,
    this.paused = false,
  });

  /// Null while the session is ready but not started; nothing is stored yet.
  final int? sessionId;

  /// Time and distance since the session started.
  final SessionProgress progress;

  /// What is rowed; null for a free session.
  final SessionPlan? plan;

  /// Whether the ghosts of [plan] run; fixed when the session starts
  /// (template-screen, Design D4). Without a plan it has no meaning.
  final bool ghost;

  /// Where the session is on the course of [plan].
  final LapProgress? lap;

  /// Whether the session is paused because the rower stopped (Change auto-pause, Design D4).
  final bool paused;

  /// Whether the session waits for the first stroke (start-on-first-stroke, Design D1).
  bool get ready => sessionId == null;

  /// The index in [SessionPlan.courses] of the course being rowed; null
  /// without a plan (workout-course-chain, Design D6).
  int? get courseIndex => switch ((plan, lap)) {
    (final plan?, final lap?) => plan.courseAt(lap.segmentIndex),
    _ => null,
  };

  /// The name of the course being rowed, only when the plan has several.
  String? get courseName => switch ((plan, courseIndex)) {
    (final plan?, final index?) when plan.courses.length > 1 =>
      plan.courses[index].name,
    _ => null,
  };
}

/// A session that ended by itself after its last lap, until the live
/// display has shown its summary.
final finishedSessionProvider = NotifierProvider<FinishedSession, int?>(
  FinishedSession.new,
);

class FinishedSession extends Notifier<int?> {
  @override
  int? build() => null;

  void report(int sessionId) => state = sessionId;

  void clear() => state = null;
}

/// How often buffered rows are written; at most this much is lost when the
/// app ends unexpectedly.
final recordingFlushIntervalProvider = Provider(
  (ref) => const Duration(seconds: 2),
);

final sessionRecorderProvider =
    NotifierProvider<SessionRecorder, ActiveRecording?>(SessionRecorder.new);

/// Records the active source into a session until it is stopped.
class SessionRecorder extends Notifier<ActiveRecording?> {
  SessionAccumulator? _accumulator;
  StreamSubscription<RawPacket>? _packets;
  void Function(RawPacket packet)? _onPacket;
  Timer? _flushTimer;
  var _writes = Future<void>.value();

  /// The session being created after the first stroke, see [_begin].
  Future<void>? _beginning;

  @override
  ActiveRecording? build() {
    ref.onDispose(_stopListening);
    return null;
  }

  SessionRepository get _repository => ref.read(sessionRepositoryProvider);

  /// Starts a session with the active source; time and distance count from
  /// zero, whatever the PM5 shows at the moment. With a [plan] the session is
  /// only ready: it starts with the first stroke, follows its course and ends
  /// by itself after the last lap. Without [ghost] no ghost runs in this
  /// session.
  Future<void> start({SessionPlan? plan, bool ghost = true}) async {
    if (state != null) return;
    final source = ref.read(activeErgSourceProvider);
    if (source == null) throw StateError('No data source');
    if (plan == null) return _begin(source, null, ghost, const []);

    state = ActiveRecording(
      sessionId: null,
      progress: const SessionProgress(
        distanceMeters: 0,
        elapsed: Duration.zero,
      ),
      plan: plan,
      ghost: ghost,
      lap: LapTracker(plan.definition, plannedLaps: plan.plannedLaps).progress,
    );
    final detector = FirstStrokeDetector(source.protocol);
    List<RawPacket>? early;
    _listen(source, (packet) {
      // Packets that arrive while the session is created are added to the early ones.
      if (early case final early?) return early.add(packet);
      final first = early = detector.add(packet);
      if (first != null) _beginning = _begin(source, plan, ghost, first);
    });
  }

  /// Creates the session and records [source] into it, starting with [early]
  /// packets: the base of the first stroke and what followed (Design D2).
  Future<void> _begin(
    ErgSource source,
    SessionPlan? plan,
    bool ghost,
    List<RawPacket> early,
  ) async {
    final id = await _repository.create(
      startedAt: clock.now(),
      source: source.kind,
      protocol: source.protocol,
      deviceName:
          source.kind == ErgSourceKind.pm5 || source.kind == ErgSourceKind.ftms
          ? source.name
          : null,
      plan: plan,
    );
    final accumulator = _accumulator = SessionAccumulator(
      id,
      protocol: source.protocol,
      course: plan?.definition,
      plannedLaps: plan?.plannedLaps,
      plannedDuration: plan?.plannedDuration,
    );
    ActiveRecording current() => ActiveRecording(
      sessionId: id,
      progress: accumulator.progress,
      plan: plan,
      ghost: ghost,
      lap: accumulator.lapProgress,
      paused: accumulator.paused,
    );
    void add(RawPacket packet) {
      // Stopped after the last lap while the early packets are still added.
      if (_accumulator != accumulator) return;
      accumulator.add(packet);
      // On a course the live state follows every value, e.g. the zone status.
      final changed =
          accumulator.progress != state?.progress ||
          accumulator.paused != state?.paused;
      if (plan != null || changed) state = current();
      if (accumulator.planFinished) unawaited(_finishAfterPlan());
    }

    state = current();
    _listen(source, add);
    _flushTimer = Timer.periodic(
      ref.read(recordingFlushIntervalProvider),
      (_) => _flush(),
    );
    early.forEach(add);
  }

  /// Hands the packets of [source] to [onPacket]; one subscription for the
  /// whole session, so no packet is lost when the session starts.
  void _listen(ErgSource source, void Function(RawPacket packet) onPacket) {
    _onPacket = onPacket;
    _packets ??= source.packets.listen((packet) => _onPacket?.call(packet));
  }

  /// Ends the session after its last lap or its time limit; an unfinished lap
  /// stays incomplete.
  Future<void> _finishAfterPlan() async {
    final id = await stop();
    if (id != null) ref.read(finishedSessionProvider.notifier).report(id);
  }

  /// Ends the session, stores its summary and returns its id.
  Future<int?> stop() async {
    final beginning = _beginning;
    // After the first stroke the session is kept, even while it is being created.
    if (beginning != null && (state?.ready ?? false)) await beginning;
    if (state?.ready ?? false) {
      // Nothing is stored before the first stroke.
      _stopListening();
      state = null;
      return null;
    }
    final recording = state;
    final accumulator = _accumulator;
    final id = recording?.sessionId;
    if (accumulator == null || id == null) return null;
    _stopListening();
    _accumulator = null;
    _beginning = null;
    accumulator.finish();
    _flush(accumulator);
    await _writes;
    await _repository.finish(id, endedAt: clock.now());
    state = null;
    // In the background, so the summary does not wait for Health Connect (health-connect, Design D4).
    unawaited(ref.read(healthExporterProvider).sessionFinished(id));
    return id;
  }

  void _flush([SessionAccumulator? accumulator]) {
    final batch = (accumulator ?? _accumulator)?.takeBatch();
    if (batch == null || batch.isEmpty) return;
    final repository = _repository;
    // Chained, so batches are written in order.
    _writes = _writes.then((_) => repository.write(batch));
  }

  void _stopListening() {
    _packets?.cancel();
    _packets = null;
    _onPacket = null;
    _flushTimer?.cancel();
    _flushTimer = null;
  }
}
