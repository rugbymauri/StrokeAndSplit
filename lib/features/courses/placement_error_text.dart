import '../../data/courses/course_layout.dart';
import '../../l10n/l10n.dart';

/// [error] in words for the user (Design D4).
String placementErrorText(AppLocalizations l10n, PlacementError error) => switch (error.kind) {
      PlacementErrorKind.lengthMissing => l10n.placementLengthMissing,
      PlacementErrorKind.zoneMissing => l10n.placementZoneMissing,
      PlacementErrorKind.axisMismatch =>
        l10n.placementAxisMismatch(error.zone!, error.zoneAxis!.name, error.courseAxis!.name),
      PlacementErrorKind.beforeStart => l10n.placementBeforeStart(error.zone!),
      PlacementErrorKind.beyondEnd => l10n.placementBeyondEnd(error.zone!, error.range!, error.courseLength!),
      PlacementErrorKind.overlap => l10n.placementOverlap(error.zone!, error.range!, error.other!, error.otherRange!),
    };
