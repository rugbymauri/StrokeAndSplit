import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/sessions/session_providers.dart';
import '../../data/sources/erg_source.dart';
import '../live/formatters.dart';
import 'session_actions.dart';

/// The summary of one stored session.
class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider(sessionId));
    return Scaffold(
      appBar: AppBar(
        title: Text(session.value == null ? 'Session' : formatDateTime(session.value!.startedAt)),
        actions: [
          if (session.value case final row?) ...[
            IconButton(
              tooltip: 'Abspielen',
              icon: const Icon(Icons.play_arrow),
              onPressed: () => replaySession(context, ref, row),
            ),
            IconButton(
              tooltip: 'Löschen',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await deleteSession(context, ref, row) && context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ],
      ),
      body: switch (session) {
        AsyncData(value: final session?) => _Summary(session: session),
        AsyncData() => const Center(child: Text('Diese Session gibt es nicht mehr.')),
        AsyncError(:final error) => Center(child: Text('Session konnte nicht geladen werden: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Name of the source a session was recorded with.
String sessionSourceLabel(SessionRow session) => switch (session.source) {
      ErgSourceKind.pm5 => session.deviceName ?? 'PM5',
      ErgSourceKind.simulator => 'Simulator',
      ErgSourceKind.replay => 'Replay',
    };

class _Summary extends StatelessWidget {
  const _Summary({required this.session});

  final SessionRow session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pace = session.averagePaceCs;
    final values = [
      ('Distanz', '${session.distanceDm ~/ 10} m'),
      ('Zeit', formatElapsed(Duration(milliseconds: session.durationMs))),
      ('⌀ Pace /500 m', formatPace(pace == null ? null : Duration(milliseconds: pace * 10))),
      ('⌀ Watt', formatWhole(session.averageWatts)),
      ('⌀ Schläge/min', formatStrokeRate(session.averageStrokeRate)),
      ('Schläge', '${session.strokeCount}'),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(sessionSourceLabel(session), style: theme.textTheme.titleMedium),
            if (session.status == SessionStatus.incomplete)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Unvollständig: Die App wurde während der Session beendet. '
                  'Gespeichert ist alles bis kurz davor.',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, value) in values)
                  SizedBox(
                    width: 180,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: theme.textTheme.labelLarge),
                            Text(
                              value,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
