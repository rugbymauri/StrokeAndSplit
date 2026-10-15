import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/platform_providers.dart';
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
    _notify(ScaffoldMessenger.of(context), 'Für diese Session gibt es keine Rohdaten zum Abspielen.');
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

/// File name of an exported session, e.g. `aergrow-2026-10-15-1830.aergrow`.
String sessionFileName(SessionRow session) {
  final t = session.startedAt.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return 'aergrow-${t.year}-${two(t.month)}-${two(t.day)}-${two(t.hour)}${two(t.minute)}.aergrow';
}

/// Exports [session] with its raw data as an `.aergrow` file.
Future<void> exportSession(BuildContext context, WidgetRef ref, SessionRow session) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final bytes = await ref.read(sessionRepositoryProvider).export(session.id);
    final saved = await ref.read(sessionFilesProvider).save(sessionFileName(session), bytes);
    if (saved) _notify(messenger, 'Session exportiert.');
  } on Exception catch (e) {
    _notify(messenger, 'Export fehlgeschlagen: $e');
  }
}

/// Lets the user pick an `.aergrow` file and adds it to the sessions.
Future<void> importSession(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final bytes = await ref.read(sessionFilesProvider).open();
  if (bytes == null) return;
  try {
    await ref.read(sessionRepositoryProvider).import(bytes);
    _notify(messenger, 'Session importiert.');
  } on Exception catch (e) {
    _notify(messenger, 'Die Datei ist keine lesbare AergRow-Session: $e');
  }
}

/// Shows [message] right away instead of queueing it behind the last one.
void _notify(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
