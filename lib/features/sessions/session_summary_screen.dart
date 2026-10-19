import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../data/courses/course.dart';
import '../../data/courses/course_providers.dart';
import '../../data/db/database.dart';
import '../../data/sessions/pace_track.dart';
import '../../data/sessions/session_providers.dart';
import '../../data/sources/erg_source.dart';
import '../../data/statistics/session_places.dart';
import '../../l10n/l10n.dart';
import '../live/formatters.dart';
import 'session_actions.dart';

/// The summary of one stored session (screen "Zusammenfassung" of the canvas).
class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({super.key, required this.sessionId});

  final int sessionId;

  /// Opens the summary right after rowing; "done" then returns true, so the
  /// live display goes back to the start screen.
  static Future<bool> showAfterSession(BuildContext context, int sessionId) async =>
      await Navigator.of(context)
          .push<bool>(MaterialPageRoute(builder: (_) => SessionSummaryScreen(sessionId: sessionId))) ??
      false;

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

class _Summary extends ConsumerWidget {
  const _Summary({required this.session});

  final SessionRow session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final versionId = session.courseVersionId;
    final course = versionId == null ? null : ref.watch(courseVersionProvider(versionId)).value;
    final laps = versionId == null ? const <LapRow>[] : ref.watch(sessionLapsProvider(session.id)).value ?? const [];
    final places = ref.watch(sessionPlacesProvider(session.id)).value ?? SessionPlaces.none;
    final rr = ref.watch(sessionRrIntervalsProvider(session.id)).value ?? const <RrIntervalRow>[];
    final pace = ref.watch(sessionPaceTrackProvider(session.id)).value ?? PaceTrack.empty;

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
                  _Header(session: session, course: course, laps: laps, place: places.session),
                  if (session.status == SessionStatus.incomplete)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.s),
                      child: Text(l10n.sessionIncompleteNote, style: const TextStyle(color: AppColors.zoneOut)),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  _Totals(session: session),
                  if (course != null && laps.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _Laps(laps: laps, course: course, places: places),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _Averages(session: session, minHeartRate: ref.watch(sessionMinHeartRateProvider(session.id)).value),
                  if (pace.steps.length >= 2) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _Pace(track: pace, averageCs: session.averagePaceCs),
                  ],
                  if (rr.length >= 2 || session.rmssdMs != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _RrIntervals(intervals: rr, rmssdMs: session.rmssdMs),
                  ],
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
                        onPressed: () => Navigator.of(context).maybePop(true),
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
  const _Header({required this.session, required this.course, required this.laps, required this.place});

  final SessionRow session;
  final Course? course;
  final List<LapRow> laps;

  /// The place of the session in its template's ranking, if 1–3.
  final int? place;

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
        Wrap(
          spacing: AppSpacing.m,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.summaryTitle, style: AppTextStyles.screenTitle.copyWith(fontSize: 40, height: 1.1)),
            if (place case final place?)
              _PlaceMark(
                key: const Key('session-place'),
                text: l10n.summaryPlace(place),
                semanticsLabel: l10n.summarySessionPlace(place),
                large: true,
              ),
          ],
        ),
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

/// Time, distance and, with pauses, their number and total time.
class _Totals extends StatelessWidget {
  const _Totals({required this.session});

  final SessionRow session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tiles = [
      _Tile(label: l10n.sessionTime, value: formatElapsed(Duration(milliseconds: session.durationMs))),
      _Tile(label: l10n.sessionDistance, value: '${session.distanceDm ~/ 10}', unit: 'm'),
      // Only with pauses (Change auto-pause, Design D3); the time above leaves them out.
      if (session.pauseCount > 0)
        _Tile(
          key: const Key('summary-pauses'),
          label: l10n.summaryPauses(session.pauseCount),
          value: formatElapsed(Duration(milliseconds: session.pausedMs)),
        ),
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
  const _Tile({super.key, required this.label, required this.value, this.unit});

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
/// marked, unfinished ones are muted. Laps and zone runs on places 1–3 of
/// their rankings carry their place.
class _Laps extends StatelessWidget {
  const _Laps({required this.laps, required this.course, required this.places});

  final List<LapRow> laps;
  final Course course;
  final SessionPlaces places;

  /// Whether laps compare by time (distance course) or by distance.
  bool get byTime => course.axis == CourseAxis.distance;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final segments = course.definition.segments;
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
                _LapRow(
                  lap: lap,
                  byTime: byTime,
                  best: identical(lap, best),
                  marks: [
                    if (places.laps[lap.lapNo] case final place?) l10n.summaryPlace(place),
                    for (final (position, segment) in segments.indexed)
                      if (places.zones[(lap.lapNo, position)] case final place?)
                        l10n.summaryZonePlace(segment.zoneName ?? '', place),
                  ],
                ),
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
  const _LapRow({required this.lap, required this.byTime, required this.best, this.marks = const []});

  final LapRow lap;
  final bool byTime;
  final bool best;

  /// The places of the lap and its zone runs.
  final List<String> marks;

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
                if (marks.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: share == null ? 0 : AppSpacing.s),
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [for (final mark in marks) _PlaceMark(text: mark)],
                    ),
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
          // The best lap of this session; places in the rankings stand below the bar.
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

/// A place in a ranking, e.g. "Platz 2".
class _PlaceMark extends StatelessWidget {
  const _PlaceMark({super.key, required this.text, this.semanticsLabel, this.large = false});

  final String text;
  final String? semanticsLabel;

  /// For the session next to the title.
  final bool large;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.line,
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.small)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: large ? AppSpacing.m : AppSpacing.s, vertical: large ? 6 : 2),
          child: Text(
            text,
            semanticsLabel: semanticsLabel,
            style: (large ? AppTextStyles.button : AppTextStyles.caption)
                .copyWith(color: AppColors.text, fontWeight: FontWeight.w600),
          ),
        ),
      );
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
  const _Averages({required this.session, this.minHeartRate});

  final SessionRow session;

  /// The lowest heart rate, read from the samples; null without one.
  final int? minHeartRate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pace = session.averagePaceCs;
    final values = [
      (l10n.sessionAveragePace, formatPace(pace == null ? null : Duration(milliseconds: pace * 10))),
      (l10n.sessionAverageStrokeRate, formatStrokeRate(l10n, session.averageStrokeRate)),
      (l10n.sessionAverageWatts, formatWhole(session.averageWatts)),
      (l10n.sessionStrokes, '${session.strokeCount}'),
      // Only with a heart rate, from the strap or the rower.
      if (session.averageHeartRate case final average?) (l10n.sessionAverageHeartRate, '$average'),
      if (minHeartRate case final min?) (l10n.sessionMinHeartRate, '$min'),
      if (session.maxHeartRate case final max?) (l10n.sessionMaxHeartRate, '$max'),
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

/// The pace over the session as a curve, the fastest pace at the top, with its fastest, slowest and
/// average value (ui-design, Task 5.10).
class _Pace extends StatelessWidget {
  const _Pace({required this.track, required this.averageCs});

  final PaceTrack track;
  final int? averageCs;

  static String _format(int? cs) => formatPace(cs == null ? null : Duration(milliseconds: cs * 10));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fastest = _format(track.fastestCs);
    final slowest = _format(track.slowestCs);
    final average = _format(averageCs);
    final values = [
      (l10n.summaryPaceFastest, fastest, const Key('summary-pace-fastest')),
      (l10n.summaryPaceAverage, average, const Key('summary-pace-average')),
      (l10n.summaryPaceSlowest, slowest, const Key('summary-pace-slowest')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.summaryPace.toUpperCase(), style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.m),
        _Card(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: AppSpacing.l,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final (label, value, key) in values)
                    Text.rich(
                      TextSpan(
                        text: '$label ',
                        children: [
                          TextSpan(
                            text: value,
                            style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      key: key,
                      style: AppTextStyles.subtitle,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              Text(fastest, style: AppTextStyles.caption),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                container: true,
                label: l10n.summaryPaceCurve(fastest, slowest, average),
                child: SizedBox(
                  key: const Key('summary-pace-curve'),
                  height: 120,
                  child: CustomPaint(painter: PaceCurvePainter(track.steps, averageCs: averageCs)),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(slowest, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}

/// The pace as one line: rowed time across, faster upwards, scaled from the slowest to the fastest step,
/// with the average as a dashed line.
class PaceCurvePainter extends CustomPainter {
  PaceCurvePainter(this.steps, {this.averageCs});

  /// (end of the step in rowed milliseconds, pace in centiseconds), ordered by time.
  final List<(int, int)> steps;
  final int? averageCs;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    canvas
      ..drawLine(Offset.zero, Offset(size.width, 0), grid)
      ..drawLine(Offset(0, size.height), Offset(size.width, size.height), grid);
    if (steps.length < 2) return;
    final first = steps.first.$1;
    final span = math.max(1, steps.last.$1 - first);
    final fastest = steps.map((s) => s.$2).reduce(math.min);
    final range = math.max(1, steps.map((s) => s.$2).reduce(math.max) - fastest);
    double y(int paceCs) => ((paceCs - fastest) / range).clamp(0.0, 1.0) * size.height;
    if (averageCs case final average?) {
      final dash = Paint()
        ..color = AppColors.textMuted
        ..strokeWidth = 1;
      for (var x = 0.0; x < size.width; x += 8) {
        canvas.drawLine(Offset(x, y(average)), Offset(math.min(x + 4, size.width), y(average)), dash);
      }
    }
    final path = Path();
    for (final (i, (t, pace)) in steps.indexed) {
      final offset = Offset((t - first) / span * size.width, y(pace));
      i == 0 ? path.moveTo(offset.dx, offset.dy) : path.lineTo(offset.dx, offset.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.zoneIn
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(PaceCurvePainter oldDelegate) =>
      oldDelegate.steps != steps || oldDelegate.averageCs != averageCs;
}

/// The RR intervals over the session as a curve and the heart rate
/// variability as RMSSD (heart-rate, Design D8).
class _RrIntervals extends StatelessWidget {
  const _RrIntervals({required this.intervals, required this.rmssdMs});

  final List<RrIntervalRow> intervals;
  final int? rmssdMs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rmssdMs = this.rmssdMs;
    final curve = intervals.length >= 2;
    final shortest = curve ? intervals.map((i) => i.rrMs).reduce(math.min) : 0;
    final longest = curve ? intervals.map((i) => i.rrMs).reduce(math.max) : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.summaryRrIntervals.toUpperCase(), style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.m),
        _Card(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (rmssdMs != null)
                Text(
                  l10n.summaryRmssd(rmssdMs),
                  key: const Key('summary-rmssd'),
                  style: AppTextStyles.subtitle.copyWith(color: AppColors.text, fontWeight: FontWeight.w600),
                ),
              if (curve) ...[
                if (rmssdMs != null) const SizedBox(height: AppSpacing.m),
                Text('$longest ms', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xs),
                Semantics(
                  container: true,
                  label: l10n.summaryRrCurve(shortest, longest),
                  child: SizedBox(
                    key: const Key('summary-rr-curve'),
                    height: 120,
                    child: CustomPaint(painter: RrCurvePainter([for (final i in intervals) (i.tMs, i.rrMs)])),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('$shortest ms', style: AppTextStyles.caption),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// RR intervals as one line: their end time across, their length upwards,
/// scaled from the shortest to the longest.
class RrCurvePainter extends CustomPainter {
  RrCurvePainter(this.points);

  /// (end time, interval) in milliseconds, ordered by end time.
  final List<(int, int)> points;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    canvas
      ..drawLine(Offset.zero, Offset(size.width, 0), grid)
      ..drawLine(Offset(0, size.height), Offset(size.width, size.height), grid);
    if (points.length < 2) return;
    final first = points.first.$1;
    final span = math.max(1, points.last.$1 - first);
    final shortest = points.map((p) => p.$2).reduce(math.min);
    final range = math.max(1, points.map((p) => p.$2).reduce(math.max) - shortest);
    final path = Path();
    for (final (i, (t, rr)) in points.indexed) {
      final offset = Offset((t - first) / span * size.width, size.height - (rr - shortest) / range * size.height);
      i == 0 ? path.moveTo(offset.dx, offset.dy) : path.lineTo(offset.dx, offset.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.zoneOut
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(RrCurvePainter oldDelegate) => oldDelegate.points != points;
}
