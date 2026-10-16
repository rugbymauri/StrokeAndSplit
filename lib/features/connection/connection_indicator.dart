import 'package:flutter/material.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sources/erg_source.dart';
import '../../data/sources/erg_source_providers.dart';
import '../../l10n/l10n.dart';

/// Connection state and data source, always visible while rowing so that
/// simulated or replayed data is never mistaken for a live erg.
class ConnectionIndicator extends ConsumerWidget {
  const ConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(activeErgSourceProvider);
    final state = ref.watch(ergConnectionStateProvider).value ?? ErgConnectionState.disconnected;
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final (icon, label, color) = switch (state) {
      ErgConnectionState.connected => (Icons.bluetooth_connected, l10n.stateConnected, colors.primary),
      ErgConnectionState.connecting => (Icons.bluetooth_searching, l10n.stateConnecting, colors.tertiary),
      ErgConnectionState.scanning => (Icons.bluetooth_searching, l10n.stateScanning, colors.tertiary),
      ErgConnectionState.reconnecting => (Icons.sync_problem, l10n.stateReconnecting, colors.error),
      ErgConnectionState.disconnected => (Icons.bluetooth_disabled, l10n.stateDisconnected, colors.error),
    };

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (source != null) _SourceBadge(source: source),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Flexible(child: Text(label, style: TextStyle(color: color), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ],
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});

  final ErgSource source;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final (label, background, foreground) = switch (source.kind) {
      ErgSourceKind.pm5 => (source.name, colors.secondaryContainer, colors.onSecondaryContainer),
      ErgSourceKind.ftms => ('${source.name} · FTMS', colors.secondaryContainer, colors.onSecondaryContainer),
      ErgSourceKind.simulator => (
          source.protocol == ErgProtocol.ftms ? l10n.sourceSimulatorFtms : l10n.sourceSimulator,
          colors.tertiary,
          colors.onTertiary,
        ),
      ErgSourceKind.replay => (l10n.sourceReplay, colors.tertiary, colors.onTertiary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: foreground, fontWeight: FontWeight.bold)),
    );
  }
}
