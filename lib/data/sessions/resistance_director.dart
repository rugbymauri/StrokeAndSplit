import 'package:clock/clock.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../courses/course.dart';

/// Decides which resistance level a rower should have while a session runs
/// (Change resistance-control, Design D4). It is pure: it gets the segments,
/// the levels the rower reports and the taps on − and +, and returns the
/// level to send, or null when nothing is to be sent.
///
/// - A segment with a level gets that level; every other segment gets the
///   base level, the one the rower reported first. A segment that starts
///   before the rower reported any level waits for that report, so the base
///   level is the one the rower had and not the one just sent.
/// - A level the rower reports that differs from the one asked for is a
///   change by hand: it holds until the next segment, and in a segment
///   without level it becomes the base level. A pause is no event, so a
///   change during a pause is a change by hand as well.
/// - For [grace] after sending, the rower may still report the old level.
class ResistanceDirector {
  ResistanceDirector({
    required this.range,
    this.grace = const Duration(seconds: 3),
  });

  /// The levels of the rower; it changes when the rower reconnects.
  ResistanceRange range;

  final Duration grace;

  int? _base;
  int? _target;
  int? _reported;
  var _segmentHasLevel = false;
  DateTime? _sentAt;

  /// The segment that started before the rower reported its first level.
  CourseSegment? _waitingSegment;

  /// The level asked for, or the one reported when nothing was asked for.
  int? get target => _target ?? _reported;

  /// The base level for segments without level.
  int? get baseLevel => _base;

  /// The rower reports [level]; returns the level to send, which is only
  /// ever the one of a segment that waited for this first report.
  int? reported(int level) {
    final whole = range.wholeLevel(level);
    _reported = whole;
    if (_base == null) {
      _base = whole;
      _target ??= whole;
      final waiting = _waitingSegment;
      _waitingSegment = null;
      return waiting == null ? null : segmentStarted(waiting);
    }
    if (whole == _target) {
      _sentAt = null;
      return null;
    }
    if (_waiting) return null;
    _target = whole;
    if (!_segmentHasLevel) _base = whole;
    return null;
  }

  /// A session starts: its base level is the level the rower has now.
  void sessionStarted() {
    _segmentHasLevel = false;
    _base = target ?? _base;
  }

  /// A segment of the course starts: its level, or the base level.
  int? segmentStarted(CourseSegment segment) {
    final level = segment.resistanceLevel;
    _segmentHasLevel = level != null;
    if (_base == null) {
      _waitingSegment = segment;
      return null;
    }
    final wanted = level ?? _base;
    if (wanted == null) return null;
    final clamped = range.clamp(wanted);
    _target = clamped;
    return clamped == _reported ? null : _send(clamped);
  }

  /// The user taps + (1) or − (-1): a change by hand from the level asked
  /// for, so quick taps add up.
  int? step(int delta) {
    final from = target;
    if (from == null) return null;
    final next = range.clamp(from + delta);
    if (next == from) return null;
    _target = next;
    if (!_segmentHasLevel) _base = next;
    return _send(next);
  }

  /// The rower is connected again: the level asked for is sent once more.
  int? reconnected() {
    final level = _target;
    return level == null ? null : _send(level);
  }

  /// The rower refused [level] or did not answer: the level it reports
  /// counts again, and nothing is sent until the next segment or tap (D5).
  void failed(int level) {
    if (level != _target) return;
    _sentAt = null;
    final reported = _reported;
    _target = reported;
    if (!_segmentHasLevel && reported != null) _base = reported;
  }

  bool get _waiting {
    final sentAt = _sentAt;
    return sentAt != null && clock.now().difference(sentAt) < grace;
  }

  int _send(int level) {
    _sentAt = clock.now();
    return level;
  }
}
