import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/health/health_export.dart';
import '../../data/sessions/session_providers.dart';
import '../../l10n/l10n.dart';
import '../health/health_connect_sheet.dart';
import '../live/formatters.dart';
import 'session_actions.dart';
import 'session_summary_screen.dart';

/// All recorded sessions, newest first.
class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sessionsTitle),
        actions: [
          if (ref.watch(healthExportAvailableProvider))
            IconButton(
              key: const Key('health-connect-button'),
              tooltip: l10n.healthConnectTooltip,
              icon: const Icon(Icons.monitor_heart_outlined),
              onPressed: () => showHealthConnectSheet(context),
            ),
          IconButton(
            tooltip: l10n.actionImport,
            icon: const Icon(Icons.file_open_outlined),
            onPressed: () => importSession(context, ref),
          ),
        ],
      ),
      body: switch (sessions) {
        AsyncData(value: []) => Center(child: Text(l10n.sessionsEmpty)),
        AsyncData(:final value) => ListView.builder(
            itemCount: value.length,
            itemBuilder: (context, i) => _SessionTile(session: value[i]),
          ),
        AsyncError(:final error) => Center(child: Text(l10n.sessionsLoadFailed('$error'))),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

enum _Action { replay, export, health, delete }

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session});

  final SessionRow session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pace = session.averagePaceCs;
    final l10n = context.l10n;
    final details = [
      ?session.templateName,
      '${session.distanceDm ~/ 10} m',
      formatElapsed(Duration(milliseconds: session.durationMs)),
      '${formatPace(pace == null ? null : Duration(milliseconds: pace * 10))} /500 m',
      sessionSourceLabel(l10n, session),
    ].join(' · ');

    return ListTile(
      title: Text(formatDateTime(l10n, session.startedAt)),
      subtitle: Text(session.status == SessionStatus.incomplete ? '$details · ${l10n.sessionIncomplete}' : details),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => SessionSummaryScreen(sessionId: session.id))),
      trailing: PopupMenuButton<_Action>(
        tooltip: l10n.actionMore,
        onSelected: (action) => switch (action) {
          _Action.replay => replaySession(context, ref, session),
          _Action.export => exportSession(context, ref, session),
          _Action.health => sendSessionToHealth(context, ref, session),
          _Action.delete => deleteSession(context, ref, session),
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: _Action.replay, child: Text(l10n.actionReplay)),
          PopupMenuItem(value: _Action.export, child: Text(l10n.actionExport)),
          if (canSendToHealth(ref, session))
            PopupMenuItem(value: _Action.health, child: Text(l10n.healthSend)),
          PopupMenuItem(value: _Action.delete, child: Text(l10n.actionDelete)),
        ],
      ),
    );
  }
}
