import 'package:flutter/material.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/courses/course.dart';
import '../../data/courses/course_providers.dart';
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
              tooltip: 'Exportieren',
              icon: const Icon(Icons.ios_share),
              onPressed: () => exportSession(context, ref, row),
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
      ErgSourceKind.ftms => '${session.deviceName ?? 'Rudergerät'} · FTMS',
      ErgSourceKind.simulator => session.protocol == ErgProtocol.ftms ? 'Simulator (FTMS)' : 'Simulator',
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
            if (session.courseVersionId case final versionId?) _Laps(session: session, versionId: versionId),
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

/// Template, course and laps of a session on a course; the best complete
/// lap is highlighted, unfinished ones are marked.
class _Laps extends ConsumerWidget {
  const _Laps({required this.session, required this.versionId});

  final SessionRow session;
  final int versionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final course = ref.watch(courseVersionProvider(versionId)).value;
    final laps = ref.watch(sessionLapsProvider(session.id)).value ?? const <LapRow>[];
    if (course == null) return const SizedBox.shrink();
    final byTime = course.axis == CourseAxis.distance;
    final complete = laps.where((l) => l.complete);
    final best = complete.isEmpty
        ? null
        : complete.reduce((a, b) {
            // Fastest lap on a distance course, the longest on a time course.
            final aBetter = byTime
                ? a.endWallMs - a.startWallMs <= b.endWallMs - b.startWallMs
                : a.endDistanceDm - a.startDistanceDm >= b.endDistanceDm - b.startDistanceDm;
            return aBetter ? a : b;
          });

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text(session.templateName ?? course.name, style: theme.textTheme.titleMedium),
                subtitle: Text('${course.name} · ${formatCourseLength(course.axis, course.definition.length)}'),
              ),
              for (final lap in laps) _LapTile(lap: lap, byTime: byTime, best: identical(lap, best)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LapTile extends StatelessWidget {
  const _LapTile({required this.lap, required this.byTime, required this.best});

  final LapRow lap;

  /// Whether laps compare by time (distance course) or by distance.
  final bool byTime;
  final bool best;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = formatLapTime(Duration(milliseconds: lap.endWallMs - lap.startWallMs));
    final distance = '${(lap.endDistanceDm - lap.startDistanceDm) ~/ 10} m';
    final share = lap.inZoneShare;
    final value = lap.complete ? (byTime ? time : distance) : 'unvollständig · $distance · $time';
    final style = theme.textTheme.titleMedium?.copyWith(
      fontWeight: best ? FontWeight.bold : null,
      color: lap.complete ? null : theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Padding(
      key: best ? const Key('lap-best') : Key('lap-${lap.lapNo}'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(best ? Icons.star : (lap.complete ? Icons.flag_outlined : Icons.timelapse)),
          const SizedBox(width: 16),
          Text('Runde ${lap.lapNo}'),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              [value, if (share != null) 'Zone ${(share * 100).round()} %'].join(' · '),
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
