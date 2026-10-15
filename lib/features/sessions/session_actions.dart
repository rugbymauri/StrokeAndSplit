import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/sessions/session_providers.dart';
import '../../data/sources/erg_source_providers.dart';
import '../../data/sources/replay_source.dart';
import '../live/formatters.dart';
import '../live/live_screen.dart';

/// Plays [session] back from its raw notifications in the live display.
Future<void> replaySession(BuildContext context, WidgetRef ref, SessionRow session) async {
  final recording = await ref.read(sessionRepositoryProvider).rawRecording(session.id);
  if (!context.mounted) return;
  if (recording.packets.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Für diese Session gibt es keine Rohdaten zum Abspielen.')));
    return;
  }
  await ref
      .read(activeErgSourceProvider.notifier)
      .use(ReplaySource(recording, name: 'Replay ${formatDateTime(session.startedAt)}'));
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LiveScreen()));
}

/// Asks for confirmation and deletes [session] with all its data.
/// Returns whether it was deleted.
Future<bool> deleteSession(BuildContext context, WidgetRef ref, SessionRow session) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Session löschen?'),
      content: Text(
        'Die Session vom ${formatDateTime(session.startedAt)} wird mit Verlauf und Rohdaten endgültig gelöscht.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Löschen')),
      ],
    ),
  );
  if (confirmed != true) return false;
  await ref.read(sessionRepositoryProvider).delete(session.id);
  return true;
}
