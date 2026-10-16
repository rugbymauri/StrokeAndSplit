import '../../l10n/l10n.dart';

/// `3 Runden`, `1 Runde` or `offen`, in the language of [l10n].
String formatLaps(AppLocalizations l10n, int? laps) => laps == null ? l10n.lapsOpen : l10n.lapsCount(laps);
