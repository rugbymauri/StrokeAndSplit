import 'package:flutter/material.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../data/sources/erg_source.dart';
import '../../data/sources/erg_source_providers.dart';
import '../../l10n/l10n.dart';

/// The text of a connection state, for the notice and for screen readers.
String connectionStateLabel(AppLocalizations l10n, ErgConnectionState state) => switch (state) {
      ErgConnectionState.connected => l10n.stateConnected,
      ErgConnectionState.connecting => l10n.stateConnecting,
      ErgConnectionState.scanning => l10n.stateScanning,
      ErgConnectionState.reconnecting => l10n.stateReconnecting,
      ErgConnectionState.disconnected => l10n.stateDisconnected,
    };

/// The colour of the dot for a connection state.
Color connectionStateColor(ErgConnectionState state) => switch (state) {
      ErgConnectionState.connected => AppColors.connected,
      ErgConnectionState.connecting ||
      ErgConnectionState.scanning ||
      ErgConnectionState.reconnecting =>
        AppColors.zoneOut,
      ErgConnectionState.disconnected => AppColors.textMuted,
    };

/// The connection state as a small dot: filled green when connected, orange while
/// (re)connecting and an empty grey ring when disconnected. Screen readers read the state.
class ConnectionIndicator extends ConsumerWidget {
  const ConnectionIndicator({super.key});

  static const size = 12.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ergConnectionStateProvider).value ?? ErgConnectionState.disconnected;
    final label = connectionStateLabel(context.l10n, state);
    final color = connectionStateColor(state);
    final filled = state != ErgConnectionState.disconnected;
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        label: label,
        child: Container(
          key: const Key('connection-dot'),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : null,
            border: filled ? null : Border.all(color: color, width: 2),
          ),
        ),
      ),
    );
  }
}

/// The connection state as text below the app bar, shown only while not connected,
/// so that a lost connection is noticed without telling colours apart.
class ConnectionNotice extends ConsumerWidget {
  const ConnectionNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ergConnectionStateProvider).value ?? ErgConnectionState.disconnected;
    if (state == ErgConnectionState.connected) return const SizedBox.shrink();
    return Padding(
      key: const Key('connection-notice'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.xs),
      child: Text(
        connectionStateLabel(context.l10n, state),
        style: AppTextStyles.caption.copyWith(color: connectionStateColor(state)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        // The dot already reads the state.
        semanticsLabel: '',
      ),
    );
  }
}

/// Marks simulated or replayed data so that it is never mistaken for a live erg;
/// a real erg shows nothing.
class SourceBadge extends ConsumerWidget {
  const SourceBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(activeErgSourceProvider);
    final l10n = context.l10n;
    final label = switch (source?.kind) {
      ErgSourceKind.simulator =>
        source!.protocol == ErgProtocol.ftms ? l10n.sourceSimulatorFtms : l10n.sourceSimulator,
      ErgSourceKind.replay => l10n.sourceReplay,
      _ => null,
    };
    if (label == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: colors.tertiary, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: colors.onTertiary, fontWeight: FontWeight.bold)),
    );
  }
}
