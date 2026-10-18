import 'package:clock/clock.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/language_button.dart';
import '../../data/sources/erg_source.dart';
import '../../data/sources/erg_source_providers.dart';
import '../../data/sources/heart_rate_choice.dart';
import '../../data/sessions/session_providers.dart';
import '../../data/sources/rower_choice.dart';
import '../../data/templates/session_template.dart';
import '../../data/templates/template_providers.dart';
import '../../l10n/l10n.dart';
import '../live/metric_tile.dart' show HeartIcon;
import '../sessions/sessions_screen.dart';
import '../templates/templates_screen.dart';
import 'choose_devices_screen.dart';
import 'connection_indicator.dart';
import 'option_card.dart';
import 'rower_connection.dart';

/// The start screen after "Geräte wählen": the chosen rower, "Rudern",
/// "Frei rudern" and the button to the sessions (Design D6).
class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: const [LanguageButton()],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePortrait,
                0,
                AppSpacing.pagePortrait,
                AppSpacing.xxl,
              ),
              children: [
                Text(l10n.appTitle, style: AppTextStyles.appTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.startTagline, style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: AppSpacing.xxl),
                const _DeviceRow(),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: () => navigator.push(MaterialPageRoute<void>(builder: (_) => const TemplatesScreen())),
                    child: Text(l10n.startRow, style: AppTextStyles.primaryButton),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(onPressed: () => startRowing(context, ref), child: Text(l10n.startRowFree)),
                ),
                const _RowAgain(),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    key: const Key('start-sessions'),
                    onPressed: () => navigator.push(MaterialPageRoute<void>(builder: (_) => const SessionsScreen())),
                    icon: const Icon(Icons.history),
                    label: Text(l10n.startSessions),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The template of the newest session whose template still exists, with the
/// start of that session; null when there is none (Design D6, "Nochmal").
final rowAgainProvider = Provider<(SessionTemplate, DateTime)?>((ref) {
  final sessions = ref.watch(sessionsProvider).value;
  final templates = ref.watch(templatesProvider).value;
  if (sessions == null || templates == null) return null;
  final byId = {for (final template in templates) template.id: template};
  for (final session in sessions) {
    if (byId[session.templateId] case final template?) return (template, session.startedAt);
  }
  return null;
});

/// The tile "Nochmal": opens the templates with the template rowed last chosen.
class _RowAgain extends ConsumerWidget {
  const _RowAgain();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final again = ref.watch(rowAgainProvider);
    if (again == null) return const SizedBox.shrink();
    final (template, startedAt) = again;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(l10n.startAgain),
          OptionCard(
            key: const Key('row-again'),
            icon: Icons.replay,
            title: template.name,
            subtitle: _whenRowed(l10n, startedAt),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => TemplatesScreen(selectedTemplateId: template.id)),
            ),
          ),
        ],
      ),
    );
  }

  /// "gestern" or "vor 3 Tagen" within a week, the date after that.
  static String _whenRowed(AppLocalizations l10n, DateTime startedAt) {
    final now = clock.now();
    final local = startedAt.toLocal();
    DateTime day(DateTime t) => DateTime.utc(t.year, t.month, t.day);
    final days = day(now).difference(day(local)).inDays;
    if (days < 7) return l10n.startAgainDaysAgo(days < 0 ? 0 : days);
    return DateFormat.yMMMd(l10n.localeName).format(local);
  }
}

/// The chosen rower and the paired heart rate strap, if any (heart-rate,
/// Design D8); tapping it leads back to "Geräte wählen". While the rower is
/// connected it says so and offers to disconnect (Design D6).
class _DeviceRow extends ConsumerWidget {
  const _DeviceRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final choice = ref.watch(chosenRowerProvider);
    final state = ref.watch(ergConnectionStateProvider).value ?? ErgConnectionState.disconnected;
    // The connection stays after rowing until it is ended here or another rower is chosen.
    final active = choice != null &&
        choice.isUsedBy(ref.watch(activeErgSourceProvider)) &&
        state != ErgConnectionState.disconnected;
    final (icon, title, subtitle) = switch (choice) {
      null => (Icons.bluetooth_searching, l10n.startNoRower, l10n.devicesTitle),
      RowerChoice(:final device?) => (Icons.rowing, device.name, l10n.startConnectsLater),
      RowerChoice(protocol: ErgProtocol.ftms) =>
        (Icons.smart_toy_outlined, l10n.sourceSimulatorFtmsName, l10n.startSimulatorFtmsHint),
      RowerChoice() => (Icons.smart_toy_outlined, l10n.sourceSimulatorName, l10n.startSimulatorHint),
    };
    final strap = ref.watch(chosenHeartRateMonitorProvider);
    return OptionCard(
      key: const Key('device-row'),
      icon: icon,
      title: title,
      subtitle: active ? connectionStateLabel(l10n, state) : subtitle,
      subtitleColor: active ? connectionStateColor(state) : null,
      detail: strap == null
          ? null
          : Row(
              key: const Key('device-row-strap'),
              children: [
                const HeartIcon(size: 14),
                const SizedBox(width: AppSpacing.xs),
                Flexible(child: Text(strap.name, style: AppTextStyles.subtitle, overflow: TextOverflow.ellipsis)),
              ],
            ),
      action: active
          ? TextButton.icon(
              key: const Key('device-row-disconnect'),
              onPressed: () => ref.read(activeErgSourceProvider.notifier).clear(),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48), textStyle: AppTextStyles.button),
              icon: const Icon(Icons.link_off),
              label: Text(l10n.startDisconnect),
            )
          : null,
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChooseDevicesScreen())),
    );
  }
}
