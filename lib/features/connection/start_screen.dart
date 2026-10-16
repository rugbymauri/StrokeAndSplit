import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_language.dart';
import '../../data/sources/erg_source_providers.dart';
import '../../data/sources/simulated_source.dart';
import '../live/live_screen.dart';
import '../sessions/sessions_screen.dart';
import '../templates/templates_screen.dart';
import '../../l10n/l10n.dart';
import 'device_list_screen.dart';

/// Lets the user pick where the rowing data comes from.
class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: l10n.languageChoice,
            onPressed: () => _chooseLanguage(context, ref),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              _SourceOption(
                icon: Icons.bluetooth_searching,
                title: l10n.startFindRower,
                subtitle: l10n.startFindRowerHint,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const DeviceListScreen())),
              ),
              _SourceOption(
                icon: Icons.smart_toy_outlined,
                title: l10n.startSimulator,
                subtitle: l10n.startSimulatorHint,
                onTap: () async {
                  await ref.read(activeErgSourceProvider.notifier).use(SimulatedSource());
                  if (!context.mounted) return;
                  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LiveScreen()));
                },
              ),
              _SourceOption(
                icon: Icons.flag_outlined,
                title: l10n.startTemplate,
                subtitle: l10n.startTemplateHint,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const TemplatesScreen())),
              ),
              _SourceOption(
                icon: Icons.replay,
                title: l10n.startSessions,
                subtitle: l10n.startSessionsHint,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const SessionsScreen())),
              ),
            ],
          ),
        ),
      ),
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

class _SourceOption extends StatelessWidget {
  const _SourceOption({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Icon(icon, size: 36),
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
