import 'package:flutter/material.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../data/courses/course.dart';
import '../../data/courses/course_providers.dart';
import '../../data/db/database.dart';
import '../../data/sessions/session_providers.dart';
import '../../data/sources/erg_source.dart';
import '../../l10n/l10n.dart';
import '../live/formatters.dart';
import 'session_actions.dart';

/// The summary of one stored session (screen "Zusammenfassung" of the canvas).
class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider(sessionId));
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (session.value case final row?) ...[
            IconButton(
              tooltip: l10n.actionExport,
              icon: const Icon(Icons.ios_share),
              onPressed: () => exportSession(context, ref, row),
            ),
            IconButton(
              tooltip: l10n.actionDelete,
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
        AsyncData() => Center(child: Text(l10n.sessionGone)),
        AsyncError(:final error) => Center(child: Text(l10n.sessionLoadFailed('$error'))),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Name of the source a session was recorded with.
String sessionSourceLabel(AppLocalizations l10n, SessionRow session) => switch (session.source) {
      ErgSourceKind.pm5 => session.deviceName ?? 'PM5',
      ErgSourceKind.ftms => '${session.deviceName ?? l10n.sourceRower} · FTMS',
      ErgSourceKind.simulator =>
        session.protocol == ErgProtocol.ftms ? l10n.sourceSimulatorFtmsName : l10n.sourceSimulatorName,
      ErgSourceKind.replay => l10n.sourceReplayName,
    };

/// Share of time within the bands over all [laps], each lap weighted by its
/// duration; null without bands.
double? sessionInZoneShare(List<LapRow> laps) {
  var inZoneMs = 0.0;
  var bandMs = 0;
  for (final lap in laps) {
    final share = lap.inZoneShare;
    if (share == null) continue;
    final duration = lap.endWallMs - lap.startWallMs;
    inZoneMs += share * duration;
    bandMs += duration;
  }
  return bandMs > 0 ? inZoneMs / bandMs : null;
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.session});

  final SessionRow session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final versionId = session.courseVersionId;
    final course = versionId == null ? null : ref.watch(courseVersionProvider(versionId)).value;
    final laps = versionId == null ? const <LapRow>[] : ref.watch(sessionLapsProvider(session.id)).value ?? const [];
    final inZone = sessionInZoneShare(laps);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePortrait,
                  AppSpacing.s,
                  AppSpacing.pagePortrait,
                  AppSpacing.xl,
                ),
                children: [
                  _Header(session: session, course: course, laps: laps),
                  if (session.status == SessionStatus.incomplete)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.s),
                      child: Text(l10n.sessionIncompleteNote, style: const TextStyle(color: AppColors.zoneOut)),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  _Totals(session: session, inZone: inZone),
                  if (course != null && laps.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _Laps(laps: laps, byTime: course.axis == CourseAxis.distance),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _Averages(session: session),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePortrait,
                  AppSpacing.m,
                  AppSpacing.pagePortrait,
                  AppSpacing.xxl,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: _buttonShape),
                        onPressed: () => replaySession(context, ref, session),
                        child: Text(l10n.actionReplay),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: _buttonShape),
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: Text(l10n.actionDone),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadii.cardLarge)));

/// Date and course, the title, and template and source.
class _Header extends StatelessWidget {
  const _Header({required this.session, required this.course, required this.laps});

  final SessionRow session;
  final Course? course;
  final List<LapRow> laps;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final course = this.course;
    String? plan;
    if (course != null) {
      final length = formatCourseLength(course.axis, course.definition.length);
      final lapCount = session.plannedLaps ?? (laps.isEmpty ? null : laps.length);
      plan = lapCount == null ? length : '$lapCount × $length';
    }
    final name = course == null ? null : session.templateName ?? course.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          [formatDateTime(l10n, session.startedAt), ?plan].join(' · '),
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: AppSpacing.xs),
        // Room for the place of the session in its template's ranking (change `statistics`).
        Text(l10n.summaryTitle, style: AppTextStyles.screenTitle.copyWith(fontSize: 40, height: 1.1)),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          children: [
            if (name != null) ...[
              Text(name, style: AppTextStyles.subtitle),
              const Text(' · ', style: AppTextStyles.subtitle),
            ],
            Text(sessionSourceLabel(l10n, session), style: AppTextStyles.subtitle),
          ],
        ),
      ],
    );
  }
}

/// Time, distance and, with bands, the share in the zone.
class _Totals extends StatelessWidget {
  const _Totals({required this.session, required this.inZone});

  final SessionRow session;
  final double? inZone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inZone = this.inZone;
    final tiles = [
      _Tile(label: l10n.sessionTime, value: formatElapsed(Duration(milliseconds: session.durationMs))),
      _Tile(label: l10n.sessionDistance, value: '${session.distanceDm ~/ 10}', unit: 'm'),
      if (inZone != null) _Tile(label: l10n.summaryInZone, value: '${(inZone * 100).round()}', unit: '%'),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, tile) in tiles.indexed) ...[
            if (i > 0) const SizedBox(width: AppSpacing.m),
            Expanded(child: tile),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, this.unit});

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) => _Card(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: _ValueText(value: value, unit: unit, size: 30),
            ),
          ],
        ),
      );
}

/// A value in Barlow Condensed 700 with its unit in 500.
class _ValueText extends StatelessWidget {
  const _ValueText({super.key, required this.value, this.unit, required this.size, this.color = AppColors.text});

  final String value;
  final String? unit;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: AppFonts.display,
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.1,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Text.rich(
      TextSpan(
        text: value,
        children: [
          if (unit case final unit?) TextSpan(text: ' $unit', style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
      style: style,
      maxLines: 1,
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
        ),
        child: Padding(padding: padding, child: child),
      );
}

/// The laps with a bar for their share in the zone; the best complete lap is
/// marked, unfinished ones are muted.
class _Laps extends StatelessWidget {
  const _Laps({required this.laps, required this.byTime});

  final List<LapRow> laps;

  /// Whether laps compare by time (distance course) or by distance.
  final bool byTime;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.summaryLaps.toUpperCase(), style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.m),
        _Card(
          child: Column(
            children: [
              for (final (i, lap) in laps.indexed) ...[
                if (i > 0) const Divider(),
                _LapRow(lap: lap, byTime: byTime, best: identical(lap, best)),
              ],
            ],
          ),
        ),
        if (laps.any((l) => l.inZoneShare != null)) ...[
          const SizedBox(height: AppSpacing.m),
          Text(l10n.summaryLapBarHint, style: AppTextStyles.caption),
        ],
      ],
    );
  }
}

class _LapRow extends StatelessWidget {
  const _LapRow({required this.lap, required this.byTime, required this.best});

  final LapRow lap;
  final bool byTime;
  final bool best;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final time = formatLapTime(Duration(milliseconds: lap.endWallMs - lap.startWallMs));
    final meters = '${(lap.endDistanceDm - lap.startDistanceDm) ~/ 10}';
    final showTime = lap.complete && byTime;
    final share = lap.inZoneShare;
    return Padding(
      key: best ? const Key('lap-best') : Key('lap-${lap.lapNo}'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${lap.lapNo}',
              semanticsLabel: l10n.sessionLap(lap.lapNo),
              style: AppTextStyles.subtitle,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (share != null) _ShareBar(share: share, label: l10n.courseInZoneShare((share * 100).round())),
                if (!lap.complete)
                  Padding(
                    padding: EdgeInsets.only(top: share == null ? 0 : AppSpacing.xs),
                    child: Text('${l10n.sessionIncomplete} · $time', style: AppTextStyles.caption),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          SizedBox(
            width: 76,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: _ValueText(
                key: const Key('lap-value'),
                value: showTime ? time : meters,
                unit: showTime ? null : 'm',
                size: 24,
                color: lap.complete ? AppColors.text : AppColors.textMuted,
              ),
            ),
          ),
          // Slot for marks of the lap: the best lap here, places 1–3 with `statistics`.
          SizedBox(
            width: 28,
            child: best
                ? Icon(Icons.star, size: 18, color: AppColors.text, semanticLabel: l10n.summaryBestLap)
                : null,
          ),
        ],
      ),
    );
  }
}

/// The share of a lap in the zone as a bar.
class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.share, required this.label});

  final double share;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          child: Container(
            height: 8,
            color: AppColors.line,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: share.clamp(0.0, 1.0),
              heightFactor: 1,
              child: const ColoredBox(color: AppColors.zoneIn),
            ),
          ),
        ),
      );
}

/// Averages and the number of strokes in one line.
class _Averages extends StatelessWidget {
  const _Averages({required this.session});

  final SessionRow session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pace = session.averagePaceCs;
    final values = [
      (l10n.sessionAveragePace, formatPace(pace == null ? null : Duration(milliseconds: pace * 10))),
      (l10n.sessionAverageStrokeRate, formatStrokeRate(l10n, session.averageStrokeRate)),
      (l10n.sessionAverageWatts, formatWhole(session.averageWatts)),
      (l10n.sessionStrokes, '${session.strokeCount}'),
    ];
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: AppSpacing.l,
        runSpacing: AppSpacing.xs,
        children: [
          for (final (label, value) in values)
            Text.rich(
              TextSpan(
                text: '$label ',
                children: [
                  TextSpan(text: value, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                ],
              ),
              style: AppTextStyles.subtitle,
            ),
        ],
      ),
    );
  }
}
