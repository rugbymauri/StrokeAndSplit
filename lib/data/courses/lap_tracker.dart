import 'course.dart';

/// One measurement of a session on a course.
class TrackPoint {
  const TrackPoint({required this.wallMs, required this.distanceDm, this.paceCs, this.strokeRate});

  /// Wall-clock time since the session started; keeps running in pauses.
  final int wallMs;
  final int distanceDm;

  /// Pace per 500 m in centiseconds; null while not rowing.
  final int? paceCs;
  final int? strokeRate;
}

/// Where a value stands relative to a band.
enum BandStatus {
  /// The segment has no such band.
  none,
  inBand,

  /// Below the lower bound: a faster pace than the band, or fewer strokes.
  below,

  /// Above the upper bound: a slower pace than the band, or more strokes.
  above,

  /// There is no value, e.g. while paused.
  missing,
}

/// The live state on the course.
class LapProgress {
  const LapProgress({
    required this.lap,
    required this.plannedLaps,
    required this.segmentIndex,
    required this.segment,
    required this.segmentStart,
    required this.segmentEnd,
    required this.remaining,
    required this.pace,
    required this.strokeRate,
    required this.lapInZoneShare,
    this.lapTime = Duration.zero,
    this.courseTime = Duration.zero,
    this.segmentTime = Duration.zero,
    this.courseDistanceDm = 0,
  });

  /// Starting at 1.
  final int lap;
  final int? plannedLaps;
  final int segmentIndex;
  final CourseSegment segment;

  /// Segment boundaries within the lap, in the unit of the course.
  final int segmentStart;
  final int segmentEnd;

  /// Left until the end of the segment: metres, or seconds on a time course.
  final double remaining;
  final BandStatus pace;
  final BandStatus strokeRate;

  /// Share of time in the zone so far in this lap; null without bands.
  final double? lapInZoneShare;

  /// Wall-clock time since the lap started, pauses included as in the lap results.
  final Duration lapTime;

  /// Wall-clock time since the first lap started, pauses included; the ghost
  /// of the template runs on it (Change ghost, Design D2).
  final Duration courseTime;

  /// Wall-clock time since the current segment started, pauses included; the
  /// ghost of the zone starts anew with it.
  final Duration segmentTime;

  /// Distance rowed since the first lap started, in decimetres.
  final double courseDistanceDm;
}

/// A lap, with wall-clock times and session distances.
class LapResult {
  const LapResult({
    required this.lap,
    required this.startWallMs,
    required this.endWallMs,
    required this.startDistanceDm,
    required this.endDistanceDm,
    required this.complete,
    required this.inZoneShare,
  });

  final int lap;
  final int startWallMs;
  final int endWallMs;
  final int startDistanceDm;
  final int endDistanceDm;
  final bool complete;
  final double? inZoneShare;

  int get durationMs => endWallMs - startWallMs;
  int get distanceDm => endDistanceDm - startDistanceDm;
}

/// A segment of a lap; the last one of an unfinished lap is partial.
class SegmentResult {
  const SegmentResult({
    required this.lap,
    required this.position,
    required this.durationMs,
    required this.distanceDm,
    required this.inZoneShare,
  });

  final int lap;
  final int position;
  final int durationMs;
  final int distanceDm;
  final double? inZoneShare;
}

/// Follows a session along a course (Design D2, D3): counts laps and
/// segments, places their boundaries between measurements and measures the
/// time in the zone. It is pure, so recording, import and recovery give the
/// same results.
class LapTracker {
  /// Starts at the beginning of lap [startLap]; later laps than the first are
  /// used to finish an interrupted lap from stored samples.
  LapTracker(
    this.course, {
    this.plannedLaps,
    int startLap = 1,
    int startWallMs = 0,
    int startDistanceDm = 0,
  })  : _lap = startLap,
        _scale = course.axis == CourseAxis.distance ? 10 : 1000,
        _previous = _Point(startWallMs.toDouble(), startDistanceDm.toDouble(), null, null) {
    _start = _previous;
    _ends = [for (final end in course.segmentEnds) end * _scale];
    _lapStart = _position(_previous);
    _startLap(_previous);
  }

  final CourseDefinition course;
  final int? plannedLaps;

  /// Axis units per unit of the course: decimetres per metre or ms per s.
  final int _scale;
  late final List<int> _ends;

  /// Where the tracker started: the beginning of the first lap it follows.
  late final _Point _start;
  int _lap;
  late double _lapStart;
  late _Point _lapStartPoint;
  var _segment = 0;
  late _Point _segmentStartPoint;
  _Point _previous;
  var _segmentInZoneMs = 0.0;
  var _segmentBandMs = 0.0;
  var _lapInZoneMs = 0.0;
  var _lapBandMs = 0.0;
  var _finished = false;

  var _laps = <LapResult>[];
  var _segments = <SegmentResult>[];

  /// Whether the last of a fixed number of laps is done.
  bool get finished => _finished;

  void add(TrackPoint point) {
    if (_finished) return;
    final p = _Point(point.wallMs.toDouble(), point.distanceDm.toDouble(), point.paceCs, point.strokeRate);
    var q = _previous;
    final position = _position(p);
    // Each boundary between the two points on its own, e.g. after a long gap.
    while (position >= _boundary && _position(q) < _boundary) {
      final f = (_boundary - _position(q)) / (position - _position(q));
      // The boundary keeps the values of the earlier point.
      final b = _Point(q.wallMs + f * (p.wallMs - q.wallMs), q.distanceDm + f * (p.distanceDm - q.distanceDm),
          q.paceCs, q.strokeRate);
      _count(q, b);
      _closeSegment(b, complete: true);
      if (_finished) {
        _previous = b;
        return;
      }
      q = b;
    }
    _count(q, p);
    _previous = p;
  }

  /// Closes a lap that was started but not finished as incomplete.
  void finish() {
    if (_finished || _position(_previous) <= _lapStart) return;
    _emitSegment(_previous);
    _emitLap(_previous, complete: false);
    _finished = true;
  }

  LapProgress get progress {
    final segment = course.segments[_segment];
    final start = _segment == 0 ? 0 : _ends[_segment - 1] ~/ _scale;
    final lapInZone = _lapBandMs + _segmentBandMs;
    return LapProgress(
      lap: _lap,
      plannedLaps: plannedLaps,
      segmentIndex: _segment,
      segment: segment,
      segmentStart: start,
      segmentEnd: start + segment.length,
      remaining: ((_boundary - _position(_previous)) / _scale).clamp(0, double.infinity),
      pace: _paceStatus(segment, _previous.paceCs),
      strokeRate: _spmStatus(segment, _previous.strokeRate),
      lapInZoneShare: lapInZone > 0 ? (_lapInZoneMs + _segmentInZoneMs) / lapInZone : null,
      lapTime: _since(_lapStartPoint),
      courseTime: _since(_start),
      segmentTime: _since(_segmentStartPoint),
      courseDistanceDm: _previous.distanceDm - _start.distanceDm,
    );
  }

  /// The laps finished since the last call.
  List<LapResult> takeLaps() {
    final laps = _laps;
    _laps = [];
    return laps;
  }

  /// The segments finished since the last call.
  List<SegmentResult> takeSegments() {
    final segments = _segments;
    _segments = [];
    return segments;
  }

  Duration _since(_Point start) => Duration(milliseconds: (_previous.wallMs - start.wallMs).round());

  double get _boundary => _lapStart + _ends[_segment];

  double _position(_Point p) => course.axis == CourseAxis.distance ? p.distanceDm : p.wallMs;

  void _startLap(_Point at) {
    _lapStartPoint = at;
    _segmentStartPoint = at;
    _segment = 0;
    _lapInZoneMs = 0;
    _lapBandMs = 0;
  }

  /// Adds the time from [from] to [to] with the zone state of [from].
  void _count(_Point from, _Point to) {
    final segment = course.segments[_segment];
    if (segment.isFree) return;
    final duration = to.wallMs - from.wallMs;
    _segmentBandMs += duration;
    if (_inZone(segment, from)) _segmentInZoneMs += duration;
  }

  void _closeSegment(_Point at, {required bool complete}) {
    _emitSegment(at);
    if (_segment < course.segments.length - 1) {
      _segment++;
      _segmentStartPoint = at;
      return;
    }
    _emitLap(at, complete: complete);
    if (plannedLaps != null && _lap >= plannedLaps!) {
      _finished = true;
      return;
    }
    _lap++;
    _lapStart = _position(at);
    _startLap(at);
  }

  void _emitSegment(_Point at) {
    final start = _segmentStartPoint;
    _segments.add(SegmentResult(
      lap: _lap,
      position: _segment,
      durationMs: at.wallMs.round() - start.wallMs.round(),
      distanceDm: at.distanceDm.round() - start.distanceDm.round(),
      inZoneShare: _segmentBandMs > 0 ? _segmentInZoneMs / _segmentBandMs : null,
    ));
    _lapInZoneMs += _segmentInZoneMs;
    _lapBandMs += _segmentBandMs;
    _segmentInZoneMs = 0;
    _segmentBandMs = 0;
  }

  void _emitLap(_Point at, {required bool complete}) {
    final start = _lapStartPoint;
    _laps.add(LapResult(
      lap: _lap,
      startWallMs: start.wallMs.round(),
      endWallMs: at.wallMs.round(),
      startDistanceDm: start.distanceDm.round(),
      endDistanceDm: at.distanceDm.round(),
      complete: complete,
      inZoneShare: _lapBandMs > 0 ? _lapInZoneMs / _lapBandMs : null,
    ));
  }

  static bool _inZone(CourseSegment segment, _Point p) {
    bool ok(BandStatus s) => s == BandStatus.none || s == BandStatus.inBand;
    return ok(_paceStatus(segment, p.paceCs)) && ok(_spmStatus(segment, p.strokeRate));
  }

  static BandStatus _paceStatus(CourseSegment segment, int? paceCs) {
    if (!segment.hasPaceBand) return BandStatus.none;
    if (paceCs == null) return BandStatus.missing;
    // The pace as the rower sees it, in whole seconds, so `2:45` is in a band from 2:45 even at 2:44.6.
    final shownCs = (paceCs / 100).round() * 100;
    if (shownCs < segment.paceFastCs!) return BandStatus.below;
    if (shownCs > segment.paceSlowCs!) return BandStatus.above;
    return BandStatus.inBand;
  }

  static BandStatus _spmStatus(CourseSegment segment, int? strokeRate) {
    if (!segment.hasSpmBand) return BandStatus.none;
    if (strokeRate == null || strokeRate == 0) return BandStatus.missing;
    if (strokeRate < segment.spmMin!) return BandStatus.below;
    if (strokeRate > segment.spmMax!) return BandStatus.above;
    return BandStatus.inBand;
  }
}

class _Point {
  const _Point(this.wallMs, this.distanceDm, this.paceCs, this.strokeRate);

  final double wallMs;
  final double distanceDm;
  final int? paceCs;
  final int? strokeRate;
}
