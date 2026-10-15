import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:pm5_protocol/pm5_protocol.dart';

import '../db/database.dart';

/// Rows collected since the last write.
class SessionBatch {
  const SessionBatch({required this.samples, required this.strokes, required this.rawPackets});

  final List<SamplesCompanion> samples;
  final List<StrokesCompanion> strokes;
  final List<RawPacketsCompanion> rawPackets;

  bool get isEmpty => samples.isEmpty && strokes.isEmpty && rawPackets.isEmpty;
}

/// Turns the notifications of one session into session-relative rows.
///
/// Recording and importing both feed the raw notifications through this,
/// so an imported session ends up with the same rows as the recorded one.
class SessionAccumulator {
  SessionAccumulator(this.sessionId);

  final int sessionId;

  final _decoder = Pm5Decoder(onWarning: (message) => debugPrint('PM5: $message'));
  Duration? _firstPacketTime;
  SessionOffset? _offset;
  var _lastPm5Distance = 0.0;
  var _lastPm5Elapsed = Duration.zero;
  (int, int)? _lastSample;

  var _samples = <SamplesCompanion>[];
  var _strokes = <StrokesCompanion>[];
  var _rawPackets = <RawPacketsCompanion>[];

  /// Time and distance since the session started.
  SessionProgress get progress => _offset?.current ?? const SessionProgress(distanceMeters: 0, elapsed: Duration.zero);

  /// The latest status, with the PM5's own time and distance.
  StatusTick? lastTick;

  void add(RawPacket packet) {
    final first = _firstPacketTime ??= packet.time;
    _rawPackets.add(RawPacketsCompanion.insert(
      sessionId: sessionId,
      tMs: (packet.time - first).inMilliseconds,
      characteristicId: packet.characteristicId,
      bytes: packet.bytes,
    ));
    _decoder.decode(packet).forEach(_onEvent);
  }

  /// Handles what the decoder still holds back; call once at the end.
  void finish() => _decoder.flush().forEach(_onEvent);

  SessionBatch takeBatch() {
    final batch = SessionBatch(samples: _samples, strokes: _strokes, rawPackets: _rawPackets);
    _samples = [];
    _strokes = [];
    _rawPackets = [];
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
    }
  }

  void _onTick(StatusTick tick) {
    lastTick = tick;
    final offset = _offset ??= SessionOffset.start(pm5Distance: tick.distanceMeters, pm5Elapsed: tick.elapsed);
    final progress = offset.update(pm5Distance: tick.distanceMeters, pm5Elapsed: tick.elapsed);
    _lastPm5Distance = tick.distanceMeters;
    _lastPm5Elapsed = tick.elapsed;

    final tMs = progress.elapsed.inMilliseconds;
    final distanceDm = (progress.distanceMeters * 10).round();
    // While paused the PM5 repeats the same values; they add nothing.
    if (_lastSample == (tMs, distanceDm)) return;
    _lastSample = (tMs, distanceDm);
    _samples.add(SamplesCompanion.insert(
      sessionId: sessionId,
      tMs: tMs,
      distanceDm: distanceDm,
      paceCs: Value(tick.pace == null ? null : tick.pace!.inMilliseconds ~/ 10),
      watts: Value(tick.watts),
      strokeRate: Value(tick.strokeRate),
      heartRate: Value(tick.heartRate),
      calories: Value(tick.calories),
    ));
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
      driveLengthMeters: stroke.driveLengthMeters,
      driveTimeMs: stroke.driveTime.inMilliseconds,
      recoveryTimeMs: stroke.recoveryTime.inMilliseconds,
      peakForceNewtons: stroke.peakForceNewtons,
      averageForceNewtons: stroke.averageForceNewtons,
      watts: Value(stroke.watts),
    ));
  }
}
