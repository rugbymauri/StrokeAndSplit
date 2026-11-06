import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../data/sources/ble/ble_rower_source.dart';
import '../../data/sources/erg_source_providers.dart';
import '../../data/sources/heart_rate_monitor.dart';
import '../../l10n/l10n.dart';
import '../live/metric_tile.dart';

/// The strap's state, as far as the live display shows it: null without a
/// paired strap or with a source that never connects one, the simulator or a
/// replay (Design D8).
HeartRateMonitorState? _shownState(WidgetRef ref) {
  // Watched first, so the strap stays connected as long as the live display is open.
  final state = ref.watch(heartRateMonitorProvider);
  if (state.phase == HeartRateMonitorPhase.notPaired) return null;
  if (ref.watch(activeErgSourceProvider) is! BleRowerSource) return null;
  return state;
}

String _phaseLabel(AppLocalizations l10n, HeartRateMonitorPhase phase) =>
    switch (phase) {
      HeartRateMonitorPhase.connected => l10n.stateConnected,
      HeartRateMonitorPhase.connecting => l10n.stateConnecting,
      HeartRateMonitorPhase.reconnecting => l10n.stateReconnecting,
      HeartRateMonitorPhase.ready => l10n.heartRateStateWaiting,
      HeartRateMonitorPhase.disconnected ||
      HeartRateMonitorPhase.notPaired => l10n.stateDisconnected,
    };

Color _phaseColor(HeartRateMonitorPhase phase) => switch (phase) {
  HeartRateMonitorPhase.connected => AppColors.connected,
  HeartRateMonitorPhase.connecting ||
  HeartRateMonitorPhase.reconnecting => AppColors.zoneOut,
  HeartRateMonitorPhase.ready ||
  HeartRateMonitorPhase.disconnected ||
  HeartRateMonitorPhase.notPaired => AppColors.textMuted,
};

/// The strap's connection state as a small heart with a dot, next to the
/// rower's `ConnectionIndicator`: green when connected, orange while
/// (re)connecting and an empty grey ring otherwise. Screen readers read the state.
class HeartRateIndicator extends ConsumerWidget {
  const HeartRateIndicator({super.key});

  static const _dot = 8.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = _shownState(ref);
    if (state == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final label = l10n.heartRateStateLabel(_phaseLabel(l10n, state.phase));
    final color = _phaseColor(state.phase);
    final filled = switch (state.phase) {
      HeartRateMonitorPhase.connected ||
      HeartRateMonitorPhase.connecting ||
      HeartRateMonitorPhase.reconnecting => true,
      _ => false,
    };
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.s),
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Semantics(
          container: true,
          label: label,
          child: Row(
            key: const Key('heart-rate-indicator'),
            mainAxisSize: MainAxisSize.min,
            children: [
              const HeartIcon(size: 14),
              const SizedBox(width: AppSpacing.xs),
              Container(
                key: const Key('heart-rate-dot'),
                width: _dot,
                height: _dot,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? color : null,
                  border: filled ? null : Border.all(color: color, width: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The strap's state as text below the app bar while it reconnects or after it
/// failed, then with the reason and a button to try again.
class HeartRateNotice extends ConsumerWidget {
  const HeartRateNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = _shownState(ref);
    final l10n = context.l10n;
    final text = switch (state) {
      HeartRateMonitorState(phase: HeartRateMonitorPhase.reconnecting) =>
        l10n.heartRateStateLabel(l10n.stateReconnecting),
      HeartRateMonitorState(
        phase: HeartRateMonitorPhase.disconnected,
        :final failure,
      ) =>
        switch (failure) {
          HeartRateMonitorFailure.noHeartRateService =>
            l10n.heartRateFailedNoService,
          HeartRateMonitorFailure.lost => l10n.heartRateFailedLost,
          HeartRateMonitorFailure.unreachable ||
          null => l10n.heartRateFailedUnreachable,
        },
      _ => null,
    };
    if (state == null || text == null) return const SizedBox.shrink();
    final failed = state.phase == HeartRateMonitorPhase.disconnected;
    return Padding(
      key: const Key('heart-rate-notice'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: failed ? AppColors.zoneOutText : AppColors.zoneOut,
              ),
              maxLines: failed ? 3 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (failed) ...[
            const SizedBox(width: AppSpacing.s),
            TextButton(
              onPressed: () =>
                  ref.read(heartRateMonitorProvider.notifier).retry(),
              child: Text(l10n.heartRateRetry),
            ),
          ],
        ],
      ),
    );
  }
}
