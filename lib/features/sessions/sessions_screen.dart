import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/sessions/session_providers.dart';
import '../live/formatters.dart';
import 'session_actions.dart';
import 'session_summary_screen.dart';

/// All recorded sessions, newest first.
class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions')),
      body: switch (sessions) {
        AsyncData(value: []) => const Center(child: Text('Noch keine Sessions aufgezeichnet.')),
        AsyncData(:final value) => ListView.builder(
            itemCount: value.length,
            itemBuilder: (context, i) => _SessionTile(session: value[i]),
          ),
        AsyncError(:final error) => Center(child: Text('Sessions konnten nicht geladen werden: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

enum _Action { replay, delete }

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session});

  final SessionRow session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pace = session.averagePaceCs;
    final details = [
      '${session.distanceDm ~/ 10} m',
      formatElapsed(Duration(milliseconds: session.durationMs)),
      '${formatPace(pace == null ? null : Duration(milliseconds: pace * 10))} /500 m',
      sessionSourceLabel(session),
    ].join(' · ');

    return ListTile(
      title: Text(formatDateTime(session.startedAt)),
      subtitle: Text(session.status == SessionStatus.incomplete ? '$details · unvollständig' : details),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => SessionSummaryScreen(sessionId: session.id))),
      trailing: PopupMenuButton<_Action>(
        tooltip: 'Aktionen',
        onSelected: (action) => switch (action) {
          _Action.replay => replaySession(context, ref, session),
          _Action.delete => deleteSession(context, ref, session),
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: _Action.replay, child: Text('Abspielen')),
          PopupMenuItem(value: _Action.delete, child: Text('Löschen')),
        ],
      ),
    );
  }
}
