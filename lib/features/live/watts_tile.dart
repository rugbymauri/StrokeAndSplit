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
class WattsTile extends ConsumerWidget {
  const WattsTile({super.key, required this.tick, required this.fontSize, this.compact = false});

  final StatusTick? tick;
  final double fontSize;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final resistance = ref.watch(resistanceProvider);
    final level = resistance.level ?? tick?.resistanceLevel;
    final footnote = resistance.refused ? l10n.metricResistanceRefused : formatResistanceLevel(l10n, level);
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
