import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:erg_protocol/erg_protocol.dart';

import '../courses/course.dart';
import '../courses/lap_tracker.dart';
import '../db/database.dart';

/// Rows collected since the last write.
class SessionBatch {
  const SessionBatch({
    required this.samples,
    required this.strokes,
    required this.rawPackets,
    this.laps = const [],
    this.lapSegments = const [],
    this.rrIntervals = const [],
  });

  final List<SamplesCompanion> samples;
  final List<StrokesCompanion> strokes;
  final List<RawPacketsCompanion> rawPackets;
  final List<LapsCompanion> laps;
  final List<LapSegmentsCompanion> lapSegments;
  final List<RrIntervalsCompanion> rrIntervals;

  bool get isEmpty =>
      samples.isEmpty &&
      strokes.isEmpty &&
      rawPackets.isEmpty &&
      laps.isEmpty &&
      lapSegments.isEmpty &&
      rrIntervals.isEmpty;
}

/// Turns the notifications of one session into session-relative rows.
///
/// Recording and importing both feed the raw notifications through this,
/// so an imported session ends up with the same rows as the recorded one.
/// On a [course] it also follows the laps (Design D2).
class SessionAccumulator {
  SessionAccumulator(
    this.sessionId, {
    this.protocol = ErgProtocol.pm5,
    CourseDefinition? course,
    int? plannedLaps,
  })  : _tracker = course == null ? null : LapTracker(course, plannedLaps: plannedLaps),
        _decoder = ErgDecoder.forProtocol(protocol, onWarning: (message) => debugPrint('${protocol.name}: $message'));

  final int sessionId;

  /// Protocol of the raw notifications; picks the decoder.
  final ErgProtocol protocol;
  final LapTracker? _tracker;
  final ErgDecoder _decoder;
  Duration? _firstPacketTime;
  var _wallMs = 0;
  SessionOffset? _offset;
  var _lastPm5Distance = 0.0;
  var _lastPm5Elapsed = Duration.zero;
  (int, int)? _lastSample;

  var _samples = <SamplesCompanion>[];
  var _strokes = <StrokesCompanion>[];
  var _rawPackets = <RawPacketsCompanion>[];
  var _rrIntervals = <RrIntervalsCompanion>[];

  /// Time and distance since the session started.
  SessionProgress get progress => _offset?.current ?? const SessionProgress(distanceMeters: 0, elapsed: Duration.zero);

  /// The latest status, with the PM5's own time and distance.
  StatusTick? lastTick;

  /// Where the session is on its course; null without a course.
  LapProgress? get lapProgress => _tracker?.progress;

  /// Whether the last of a fixed number of laps is done.
  bool get lapsFinished => _tracker?.finished ?? false;

  void add(RawPacket packet) {
    final first = _firstPacketTime ??= packet.time;
    // The arrival times keep running while the PM5 pauses its clock (Design D1).
    _wallMs = (packet.time - first).inMilliseconds;
    _rawPackets.add(RawPacketsCompanion.insert(
      sessionId: sessionId,
      tMs: _wallMs,
      characteristicId: packet.characteristicId,
      bytes: packet.bytes,
    ));
    _decoder.decode(packet).forEach(_onEvent);
  }

  /// Handles what the decoder still holds back and closes an unfinished lap;
  /// call once at the end.
  void finish() {
    _decoder.flush().forEach(_onEvent);
    _tracker?.finish();
  }

  SessionBatch takeBatch() {
    final tracker = _tracker;
    final batch = SessionBatch(
      samples: _samples,
      strokes: _strokes,
      rawPackets: _rawPackets,
      laps: [for (final lap in tracker?.takeLaps() ?? const <LapResult>[]) lapCompanion(sessionId, lap)],
      lapSegments: [
        for (final segment in tracker?.takeSegments() ?? const <SegmentResult>[]) segmentCompanion(sessionId, segment),
      ],
      rrIntervals: _rrIntervals,
    );
    _samples = [];
    _strokes = [];
    _rawPackets = [];
    _rrIntervals = [];
    return batch;
  }

  void _onEvent(RowingEvent event) {
    switch (event) {
      case StatusTick():
        _onTick(event);
      case Stroke():
        _onStroke(event);
      case WorkoutStateChanged():
        // A reset shows up as counters going backwards, see SessionOffset.
        break;
      case HeartBeatIntervals():
        _onHeartBeats(event);
    }
  }

  void _onTick(StatusTick tick) {
    lastTick = tick;
    final offset = _offset ??= SessionOffset.start(deviceDistance: tick.distanceMeters, deviceElapsed: tick.elapsed);
    final progress = offset.update(deviceDistance: tick.distanceMeters, deviceElapsed: tick.elapsed);
    _lastPm5Distance = tick.distanceMeters;
    _lastPm5Elapsed = tick.elapsed;

    final tMs = progress.elapsed.inMilliseconds;
    final distanceDm = (progress.distanceMeters * 10).round();
    final paceCs = tick.pace == null ? null : tick.pace!.inMilliseconds ~/ 10;
    final tracker = _tracker;
    tracker?.add(TrackPoint(wallMs: _wallMs, distanceDm: distanceDm, paceCs: paceCs, strokeRate: tick.strokeRate));
    // While paused the PM5 repeats the same values; they add nothing to a
    // free session, but on a course the zone counts the pause.
    if (tracker == null && _lastSample == (tMs, distanceDm)) return;
    _lastSample = (tMs, distanceDm);
    _samples.add(SamplesCompanion.insert(
      sessionId: sessionId,
      tMs: tMs,
      distanceDm: distanceDm,
      paceCs: Value(paceCs),
      watts: Value(tick.watts),
      strokeRate: Value(tick.strokeRate),
      heartRate: Value(tick.heartRate),
      calories: Value(tick.calories),
      wallMs: Value(_wallMs),
    ));
  }

  /// Stores each interval at the time it ended (Design D4), on the wall-clock
  /// axis of the raw packets: unlike the rower's clock it keeps running in a
  /// pause, while the heart keeps beating.
  void _onHeartBeats(HeartBeatIntervals beats) {
    final first = _firstPacketTime!;
    for (final (i, end) in beats.intervalEnds.indexed) {
      _rrIntervals.add(RrIntervalsCompanion.insert(
        sessionId: sessionId,
        tMs: (end - first).inMilliseconds,
        rrMs: beats.intervalsMs[i],
      ));
    }
  }

  void _onStroke(Stroke stroke) {
    if (_offset == null) return;
    // Strokes carry the PM5 counters; place them relative to the last tick.
    final dt = stroke.elapsed - _lastPm5Elapsed;
    final dd = stroke.distanceMeters - _lastPm5Distance;
    final progress = this.progress;
    _strokes.add(StrokesCompanion.insert(
      sessionId: sessionId,
      tMs: (progress.elapsed + (dt.isNegative ? Duration.zero : dt)).inMilliseconds,
      distanceDm: ((progress.distanceMeters + (dd < 0 ? 0 : dd)) * 10).round(),
      strokeNumber: stroke.strokeNumber,
      driveLengthMeters: Value(stroke.driveLengthMeters),
      driveTimeMs: Value(stroke.driveTime?.inMilliseconds),
      recoveryTimeMs: Value(stroke.recoveryTime?.inMilliseconds),
      peakForceNewtons: Value(stroke.peakForceNewtons),
      averageForceNewtons: Value(stroke.averageForceNewtons),
      watts: Value(stroke.watts),
    ));
  }
}

LapsCompanion lapCompanion(int sessionId, LapResult lap) => LapsCompanion.insert(
      sessionId: sessionId,
      lapNo: lap.lap,
      startWallMs: lap.startWallMs,
      endWallMs: lap.endWallMs,
      startDistanceDm: lap.startDistanceDm,
      endDistanceDm: lap.endDistanceDm,
      complete: lap.complete,
      inZoneShare: Value(lap.inZoneShare),
    );

LapSegmentsCompanion segmentCompanion(int sessionId, SegmentResult segment) => LapSegmentsCompanion.insert(
      sessionId: sessionId,
      lapNo: segment.lap,
      position: segment.position,
      durationMs: segment.durationMs,
      distanceDm: segment.distanceDm,
      inZoneShare: Value(segment.inZoneShare),
    );
