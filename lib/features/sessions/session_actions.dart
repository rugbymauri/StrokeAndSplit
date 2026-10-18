import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/platform_providers.dart';
import '../../data/db/database.dart';
import '../../data/sessions/session_providers.dart';
import '../../data/sources/erg_source_providers.dart';
import '../../data/sources/replay_source.dart';
import '../../l10n/l10n.dart';
import '../live/formatters.dart';
import '../live/live_screen.dart';

/// Plays [session] back from its raw notifications in the live display.
Future<void> replaySession(BuildContext context, WidgetRef ref, SessionRow session) async {
  final recording = await ref.read(sessionRepositoryProvider).rawRecording(session.id);
  if (!context.mounted) return;
  if (recording.packets.isEmpty) {
    _notify(ScaffoldMessenger.of(context), context.l10n.replayNoData);
    return;
  }
  final name = context.l10n.replayName(formatDateTime(context.l10n, session.startedAt));
  await ref.read(activeErgSourceProvider.notifier).use(ReplaySource(recording, name: name));
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LiveScreen()));
}

/// Asks for confirmation and deletes [session] with all its data.
/// Returns whether it was deleted.
Future<bool> deleteSession(BuildContext context, WidgetRef ref, SessionRow session) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = context.l10n;
      return AlertDialog(
        title: Text(l10n.sessionDeleteTitle),
        content: Text(l10n.sessionDeleteBody(formatDateTime(l10n, session.startedAt))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.actionCancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.actionDelete)),
        ],
      );
    },
  );
  if (confirmed != true) return false;
  await ref.read(sessionRepositoryProvider).delete(session.id);
  return true;
}

/// File name of an exported session, e.g. `strokesplit-2026-10-15-1830.strokesplit`.
String sessionFileName(SessionRow session) {
  final t = session.startedAt.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return 'strokesplit-${t.year}-${two(t.month)}-${two(t.day)}-${two(t.hour)}${two(t.minute)}.strokesplit';
}

/// Exports [session] with its raw data as a `.strokesplit` file.
Future<void> exportSession(BuildContext context, WidgetRef ref, SessionRow session) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  try {
    final bytes = await ref.read(sessionRepositoryProvider).export(session.id);
    final saved = await ref.read(sessionFilesProvider).save(sessionFileName(session), bytes);
    if (saved) _notify(messenger, l10n.sessionExported);
  } on Exception catch (e) {
    _notify(messenger, l10n.sessionExportFailed('$e'));
  }
}

/// Lets the user pick a `.strokesplit` or older `.aergrow` file and adds it to the sessions.
Future<void> importSession(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final bytes = await ref.read(sessionFilesProvider).open();
  if (bytes == null) return;
  try {
    await ref.read(sessionRepositoryProvider).import(bytes);
    _notify(messenger, l10n.sessionImported);
  } on Exception catch (e) {
    _notify(messenger, l10n.sessionImportFailed(l10n.appTitle, '$e'));
  }
}

/// Shows [message] right away instead of queueing it behind the last one.
void _notify(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
