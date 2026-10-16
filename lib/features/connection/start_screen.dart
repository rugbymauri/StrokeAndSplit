import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_language.dart';
import '../../app/design_tokens.dart';
import '../../data/sources/erg_source.dart';
import '../../data/sources/erg_source_providers.dart';
import '../../data/sources/rower_choice.dart';
import '../../l10n/l10n.dart';
import '../sessions/sessions_screen.dart';
import '../templates/templates_screen.dart';
import 'choose_devices_screen.dart';
import 'option_card.dart';
import 'rower_connection.dart';

/// The start screen after "Geräte wählen": the chosen rower, "Rudern",
/// "Frei rudern" and the sessions (Design D6).
class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: l10n.languageChoice,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => _chooseLanguage(context, ref),
          ),
        ],
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
                const SizedBox(height: AppSpacing.xl),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => navigator.push(MaterialPageRoute<void>(builder: (_) => const SessionsScreen())),
                    style: TextButton.styleFrom(minimumSize: const Size(48, 48), textStyle: AppTextStyles.button),
                    child: Text(l10n.startSessions),
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

/// The chosen rower; tapping it leads back to "Geräte wählen".
class _DeviceRow extends ConsumerWidget {
  const _DeviceRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final choice = ref.watch(chosenRowerProvider);
    final connected = choice != null &&
        choice.isUsedBy(ref.watch(activeErgSourceProvider)) &&
        ref.watch(ergConnectionStateProvider).value == ErgConnectionState.connected;
    final (icon, title, subtitle) = switch (choice) {
      null => (Icons.bluetooth_searching, l10n.startNoRower, l10n.devicesTitle),
      RowerChoice(:final device?) => (
          Icons.rowing,
          device.name,
          connected ? l10n.stateConnected : l10n.startConnectsLater,
        ),
      RowerChoice(protocol: ErgProtocol.ftms) =>
        (Icons.smart_toy_outlined, l10n.sourceSimulatorFtmsName, l10n.startSimulatorFtmsHint),
      RowerChoice() => (Icons.smart_toy_outlined, l10n.sourceSimulatorName, l10n.startSimulatorHint),
    };
    return OptionCard(
      key: const Key('device-row'),
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChooseDevicesScreen())),
    );
  }
}

/// Lets the user pick the language of the app; it applies at once (Design D3).
Future<void> _chooseLanguage(BuildContext context, WidgetRef ref) async {
  final current = ref.read(appLanguageProvider);
  final chosen = await showDialog<AppLanguage>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(context.l10n.languageChoice),
      children: [
        for (final language in AppLanguage.values)
          SimpleDialogOption(
            key: Key('language-${language.name}'),
            onPressed: () => Navigator.of(context).pop(language),
            child: ListTile(
              title: Text(language.nativeName),
              trailing: language == current ? const Icon(Icons.check) : null,
            ),
          ),
      ],
    ),
  );
  if (chosen != null) await ref.read(appLanguageProvider.notifier).choose(chosen);
}
