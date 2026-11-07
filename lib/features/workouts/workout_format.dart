import '../../data/sessions/session_plan.dart';
import '../../l10n/l10n.dart';
import '../live/formatters.dart';

/// `3 Runden`, `1 Runde` or `offen`, in the language of [l10n].
String formatLaps(AppLocalizations l10n, int? laps) =>
    laps == null ? l10n.lapsOpen : l10n.lapsCount(laps);

/// The length of a workout: `3 Runden`, `45:00` or `offen` (Change
/// workout-course-chain).
String formatPlanLength(AppLocalizations l10n, PlanLength length) =>
    switch (length) {
      LapCount(:final count) => l10n.lapsCount(count),
      TimeLimit(:final time) => formatElapsed(time),
      OpenLength() => l10n.lapsOpen,
    };
