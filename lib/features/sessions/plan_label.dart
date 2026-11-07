import '../../data/db/database.dart';
import '../../l10n/l10n.dart';

/// The planned length of a session: `3 Runden`, `30 min` or `offen`
/// (course-rowing-free, Design D7).
String planLabel(
  AppLocalizations l10n, {
  int? plannedLaps,
  Duration? plannedDuration,
}) => switch ((plannedLaps, plannedDuration)) {
  (_, final duration?) => l10n.planMinutes(duration.inMinutes),
  (final laps?, null) => l10n.lapsCount(laps),
  (null, null) => l10n.planOpen,
};

/// What [session] rowed: the name of its workout, or without one the name of
/// its course and the planned length, e.g. `Seerunde · 30 min`; null for free
/// rowing or while [courseName] is not loaded yet. With [chain] the workout
/// is followed by its courses, e.g. `Intervalltraining · Einrudern + Seerunde`
/// (Change workout-course-chain).
String? sessionName(
  AppLocalizations l10n,
  SessionRow session,
  String? courseName, {
  bool chain = false,
}) {
  if (session.workoutName case final name?) {
    return chain && courseName != null ? '$name · $courseName' : name;
  }
  if (courseName == null) return null;
  final duration = session.plannedDurationMs;
  return '$courseName · ${planLabel(
    l10n,
    plannedLaps: session.plannedLaps,
    plannedDuration: duration == null ? null : Duration(milliseconds: duration),
  )}';
}
