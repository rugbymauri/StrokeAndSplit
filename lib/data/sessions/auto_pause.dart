import 'dart:math';

import 'package:erg_protocol/erg_protocol.dart';

/// A pause of a session, on the wall-clock axis of its raw packets.
class PauseSpan {
  const PauseSpan({required this.startWallMs, required this.endWallMs});

  final int startWallMs;
  final int endWallMs;

  int get durationMs => endWallMs - startWallMs;

  @override
  bool operator ==(Object other) =>
      other is PauseSpan && other.startWallMs == startWallMs && other.endWallMs == endWallMs;

  @override
  int get hashCode => Object.hash(startWallMs, endWallMs);

  @override
  String toString() => 'PauseSpan($startWallMs–$endWallMs ms)';
}

/// Pauses a session when the rower stops and resumes it with the next stroke
/// (Change auto-pause, Design D1). It is pure and works on the decoded events
/// only, so PM5, FTMS, import and replay get the same pauses.
///
/// A pause begins [overdue] after the next stroke was due in the rhythm of
/// the last two strokes, as strokes come once per cycle: at 18 strokes per
/// minute they are 3.3 s apart. The rhythm is the longer of the last two gaps
/// between strokes. It ends with the next stroke rowed after it
/// began, or when the monitor reports rowing again, then from where the
/// distance rose again.
class AutoPause {
  /// How long the next stroke may be overdue before the session pauses.
  static const overdue = Duration(seconds: 3);

  /// The longest rhythm that is measured; a longer gap between two strokes counts as this long.
  static const longestRhythm = Duration(seconds: 6);

  var _wallMs = 0;

  /// The last stroke, or the start or end of the last pause when none came since.
  var _lastStrokeMs = 0;
  var _strokeSinceResume = false;
  int? _rhythmMs;
  int? _lastGapMs;
  int? _pauseStartMs;
  var _pausedMs = 0;
  bool? _rowing;
  double? _distance;

  /// The monitor's clock at the last status.
  Duration? _elapsed;

  /// The distance stands still once it has not risen for this long.
  static const _stillMs = 1000;

  /// The first status since the distance last stood still, and the last one that showed it rising.
  int? _riseStartMs;
  int? _lastRiseMs;
  var _pauses = <PauseSpan>[];

  /// Whether the session is paused right now.
  bool get paused => _pauseStartMs != null;

  /// Wall-clock time since the session started without its pauses; stands
  /// still in a pause and never goes back.
  int get activeMs => (_pauseStartMs ?? _wallMs) - _pausedMs;

  /// When the next stroke is overdue and the session pauses, on the wall clock:
  /// [overdue] after the start or a pause without a stroke since, else
  /// [overdue] after the next stroke was due. After the first stroke the
  /// rhythm is not known yet and counts as [longestRhythm].
  int get _pauseDueMs {
    final rhythmMs = _rhythmMs ?? (_strokeSinceResume ? longestRhythm.inMilliseconds : 0);
    return _lastStrokeMs + rhythmMs + overdue.inMilliseconds;
  }

  /// Adds the [events] decoded from the packet that arrived at [wallMs].
  void add(int wallMs, Iterable<RowingEvent> events) {
    _wallMs = wallMs;
    var rowingAgain = false;
    int? strokeMs;
    for (final event in events) {
      switch (event) {
        case StatusTick():
          final distance = _distance;
          if (distance != null && event.distanceMeters > distance) {
            final lastRise = _lastRiseMs;
            if (lastRise == null || wallMs - lastRise > _stillMs) _riseStartMs = wallMs;
            _lastRiseMs = wallMs;
          }
          if (_rowing == false && event.isRowing) rowingAgain = true;
          _rowing = event.isRowing;
          _distance = event.distanceMeters;
          _elapsed = event.elapsed;
        case Stroke():
          strokeMs = _rowedAt(event, wallMs);
        default:
          break;
      }
    }

    var resumed = false;
    if (strokeMs != null) {
      final pauseStart = _pauseStartMs;
      if (pauseStart != null && strokeMs >= pauseStart) {
        _resume(pauseStart, strokeMs);
        resumed = true;
      }
      _count(strokeMs);
      // A stroke reported late moves a pause that began before the stroke after it was overdue.
      final started = _pauseStartMs;
      if (started != null && _pauseDueMs > started) _pauseStartMs = null;
    }
    if (_pauseStartMs == null && wallMs >= _pauseDueMs) _pauseStartMs = _pauseDueMs;

    final pauseStart = _pauseStartMs;
    if (pauseStart != null && rowingAgain && !resumed) {
      _resume(pauseStart, max(pauseStart, _riseStartMs ?? wallMs));
    }
  }

  /// Takes the stroke rowed at [strokeMs] into the rhythm: the longer of the
  /// last two gaps, so one quick stroke does not shorten it.
  void _count(int strokeMs) {
    if (strokeMs < _lastStrokeMs) return;
    if (_strokeSinceResume) {
      final gap = min(strokeMs - _lastStrokeMs, longestRhythm.inMilliseconds);
      _rhythmMs = max(gap, _lastGapMs ?? 0);
      _lastGapMs = gap;
    }
    _lastStrokeMs = strokeMs;
    _strokeSinceResume = true;
  }

  /// When [stroke] was rowed on the wall clock. The PM5 reports a stroke at
  /// the end of its recovery, and the last one only when it stops, seconds
  /// later; its time on the monitor's clock tells how long ago it was.
  int _rowedAt(Stroke stroke, int wallMs) {
    final elapsed = _elapsed;
    if (elapsed == null || elapsed <= stroke.elapsed) return wallMs;
    return wallMs - (elapsed - stroke.elapsed).inMilliseconds;
  }

  void _resume(int start, int end) {
    if (end > start) _pauses.add(PauseSpan(startWallMs: start, endWallMs: end));
    _pausedMs += end - start;
    _pauseStartMs = null;
    _lastStrokeMs = end;
    _strokeSinceResume = false;
    _rhythmMs = null;
    _lastGapMs = null;
  }

  /// The pauses that ended since the last call; a running pause is not among them.
  List<PauseSpan> takePauses() {
    final pauses = _pauses;
    _pauses = [];
    return pauses;
  }
}
