import 'package:flutter/foundation.dart' show immutable, listEquals;

import '../db/database.dart';

/// A rowed lap, zone or session in a ranking (Change statistics, Design D5).
///
/// Times are wall-clock times since the start of the session, distances are
/// session distances; both include pauses.
@immutable
class RankingEntry {
  const RankingEntry({
    required this.sessionId,
    required this.startedAt,
    this.lap,
    this.position,
    required this.startWallMs,
    required this.endWallMs,
    required this.startDistanceDm,
    required this.endDistanceDm,
    int? durationMs,
    int? distanceDm,
  })  : durationMs = durationMs ?? endWallMs - startWallMs,
        distanceDm = distanceDm ?? endDistanceDm - startDistanceDm;

  final int sessionId;

  /// When the session started; its date is shown with the entry.
  final DateTime startedAt;

  /// The lap of a course or zone entry; null for a whole session.
  final int? lap;

  /// The position of the segment in the lap; only for a zone entry.
  final int? position;

  final int startWallMs;
  final int endWallMs;
  final int startDistanceDm;
  final int endDistanceDm;

  /// What is ranked: the sum over the laps of a session, otherwise the span
  /// from start to end.
  final int durationMs;
  final int distanceDm;

  /// Pace per 500 m in centiseconds, pauses included (Design D4); null
  /// without distance.
  int? get paceCs => distanceDm > 0 ? (durationMs / 10 * 5000 / distanceDm).round() : null;

  /// When the entry began; the earlier one is ahead on a tie.
  DateTime get rowedAt => startedAt.add(Duration(milliseconds: startWallMs));

  @override
  bool operator ==(Object other) =>
      other is RankingEntry &&
      other.sessionId == sessionId &&
      other.startedAt == startedAt &&
      other.lap == lap &&
      other.position == position &&
      other.startWallMs == startWallMs &&
      other.endWallMs == endWallMs &&
      other.startDistanceDm == startDistanceDm &&
      other.endDistanceDm == endDistanceDm &&
      other.durationMs == durationMs &&
      other.distanceDm == distanceDm;

  @override
  int get hashCode => Object.hash(sessionId, startedAt, lap, position, startWallMs, endWallMs, startDistanceDm,
      endDistanceDm, durationMs, distanceDm);

  @override
  String toString() => 'RankingEntry(session $sessionId, lap $lap, position $position, '
      '$durationMs ms, $distanceDm dm)';
}

/// The entries of one length of a template, course or zone, best first
/// (Design D2).
@immutable
class Ranking {
  const Ranking({required this.axis, required this.length, this.laps, required this.entries});

  /// The axis of the course: time is ranked on a distance axis, metres on a
  /// time axis.
  final CourseAxis axis;

  /// Of the course or zone, in metres or seconds depending on [axis].
  final int length;

  /// The number of laps of a template ranking; null otherwise.
  final int? laps;

  final List<RankingEntry> entries;

  /// The first [count] places.
  Ranking top(int count) => Ranking(axis: axis, length: length, laps: laps, entries: entries.take(count).toList());

  @override
  bool operator ==(Object other) =>
      other is Ranking &&
      other.axis == axis &&
      other.length == length &&
      other.laps == laps &&
      listEquals(other.entries, entries);

  @override
  int get hashCode => Object.hash(axis, length, laps, Object.hashAll(entries));

  @override
  String toString() => 'Ranking($axis, $length, laps $laps, $entries)';
}

/// [entries] best first: less time on a distance axis, more metres on a time
/// axis, the earlier entry ahead on a tie (Design D3).
List<RankingEntry> rankEntries(CourseAxis axis, Iterable<RankingEntry> entries) {
  int value(RankingEntry e) => switch (axis) {
        CourseAxis.distance => e.durationMs,
        CourseAxis.time => -e.distanceDm,
      };
  return entries.toList()
    ..sort((a, b) {
      final byValue = value(a).compareTo(value(b));
      if (byValue != 0) return byValue;
      final byTime = a.rowedAt.compareTo(b.rowedAt);
      return byTime != 0 ? byTime : a.sessionId.compareTo(b.sessionId);
    });
}
