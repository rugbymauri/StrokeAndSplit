/// Display formats of ranking entries (Change statistics).
library;

import 'package:intl/intl.dart';

import '../../data/courses/course.dart';
import '../../data/statistics/ranking.dart';
import '../../l10n/l10n.dart';
import '../live/formatters.dart';

/// What is ranked: the time on a distance axis, e.g. `4:08.0`, the metres on
/// a time axis, e.g. `1030 m`.
String formatRankingValue(CourseAxis axis, RankingEntry entry) => switch (axis) {
      CourseAxis.distance => formatLapTime(Duration(milliseconds: entry.durationMs)),
      CourseAxis.time => '${entry.distanceDm ~/ 10} m',
    };

/// The pace per 500 m with pauses, e.g. `2:04.0`.
String formatRankingPace(RankingEntry entry) {
  final paceCs = entry.paceCs;
  return formatPace(paceCs == null ? null : Duration(milliseconds: paceCs * 10));
}

/// The date of the session, e.g. `16.10.2026` in German.
String formatRankingDate(AppLocalizations l10n, RankingEntry entry) =>
    DateFormat.yMd(l10n.localeName).format(entry.startedAt.toLocal());
