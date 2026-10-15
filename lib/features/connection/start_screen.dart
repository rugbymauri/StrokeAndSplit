import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sources/erg_source_providers.dart';
import '../../data/sources/simulated_source.dart';
import '../live/live_screen.dart';
import '../sessions/sessions_screen.dart';
import 'device_list_screen.dart';

/// Lets the user pick where the rowing data comes from.
class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('AergRow')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              _SourceOption(
                icon: Icons.bluetooth_searching,
                title: 'PM5 suchen',
                subtitle: 'Mit deinem Concept2-Erg über Bluetooth verbinden',
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const DeviceListScreen())),
              ),
              _SourceOption(
                icon: Icons.smart_toy_outlined,
                title: 'Simulator',
                subtitle: 'Ohne Erg ausprobieren, mit simuliertem Ruderer',
                onTap: () async {
                  await ref.read(activeErgSourceProvider.notifier).use(SimulatedSource());
                  if (!context.mounted) return;
                  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LiveScreen()));
                },
              ),
              _SourceOption(
                icon: Icons.replay,
                title: 'Sessions',
                subtitle: 'Aufgezeichnete Sessions ansehen und abspielen',
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
