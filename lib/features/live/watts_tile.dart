import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sessions/resistance_providers.dart';
import '../../l10n/l10n.dart';
import 'formatters.dart';
import 'metric_tile.dart';

/// The watts with the resistance level below them; with a rower whose level
/// can be set, oar blade buttons lower and raise it (Change
/// resistance-control, Design D6).
///
/// See also `ResistanceCard`, which takes the level over in landscape.
class WattsTile extends ConsumerWidget {
  const WattsTile({
    super.key,
    required this.tick,
    required this.fontSize,
    this.compact = false,
    this.showResistance = true,
  });

  final StatusTick? tick;
  final double fontSize;
  final bool compact;

  /// False where the [ResistanceCard] shows the level, so the tile shows neither level nor buttons
  /// (live-zone-targets, Design D7).
  final bool showResistance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (!showResistance) {
      return MetricTile(
        label: l10n.metricWatts,
        value: formatWhole(tick?.watts),
        valueKey: const Key('metric-watts'),
        fontSize: fontSize,
        compact: compact,
      );
    }
    final resistance = ref.watch(resistanceProvider);
    final level = resistance.level ?? tick?.resistanceLevel;
    final footnote = resistance.refused
        ? l10n.metricResistanceRefused
        : formatResistanceLevel(l10n, level);
    final controller = ref.read(resistanceProvider.notifier);
    return MetricTile(
      label: l10n.metricWatts,
      value: formatWhole(tick?.watts),
      valueKey: const Key('metric-watts'),
      fontSize: fontSize,
      footnote: footnote,
      footnoteKey: const Key('metric-resistance'),
      compact: compact,
      stepper: resistance.canSet
          ? TileStepper(
              lowerLabel: l10n.resistanceLower,
              raiseLabel: l10n.resistanceRaise,
              lowerKey: const Key('resistance-lower'),
              raiseKey: const Key('resistance-raise'),
              onLower: resistance.canLower ? () => controller.step(-1) : null,
              onRaise: resistance.canRaise ? () => controller.step(1) : null,
            )
          : null,
    );
  }
}
