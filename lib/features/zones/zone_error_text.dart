import '../../data/zones/zone.dart';
import '../../l10n/l10n.dart';

/// [error] in words for the user (Design D4).
String zoneErrorText(AppLocalizations l10n, ZoneError error) => switch (error) {
  ZoneError.nameMissing => l10n.zoneErrorNameMissing,
  ZoneError.lengthMissing => l10n.zoneErrorLengthMissing,
  ZoneError.bandMissing => l10n.zoneErrorBandMissing,
  ZoneError.paceBoundMissing => l10n.zoneErrorPaceBoundMissing,
  ZoneError.paceReversed => l10n.zoneErrorPaceReversed,
  ZoneError.spmBoundMissing => l10n.zoneErrorSpmBoundMissing,
  ZoneError.spmReversed => l10n.zoneErrorSpmReversed,
  ZoneError.resistanceLevelTooLow => l10n.zoneErrorResistanceLevelTooLow,
};
