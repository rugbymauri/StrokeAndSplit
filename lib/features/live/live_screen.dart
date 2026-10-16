import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../../app/platform_providers.dart';
import '../../data/sessions/session_providers.dart';
import '../../data/sources/erg_source.dart';
import '../../data/sources/erg_source_providers.dart';
import '../../data/sources/simulated_source.dart';
import '../../data/templates/session_template.dart';
import '../../l10n/l10n.dart';
import '../connection/connection_indicator.dart';
import '../sessions/session_summary_screen.dart';
import '../simulator/simulator_controls.dart';
import 'course_bar.dart';
import 'formatters.dart';

/// After this long without data the shown values are marked as outdated.
const staleAfter = Duration(seconds: 3);

/// The live rowing metrics, readable from the seat.
class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key, this.template});

  /// Started as a session as soon as the source is connected.
  final SessionTemplate? template;

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  StatusTick? _tick;
  var _stale = false;
  Timer? _staleTimer;
  StreamSubscription<RowingEvent>? _events;
  Wakelock? _wakelock;
  var _wakelockOn = false;
  var _templateStarted = false;

  @override
  void initState() {
    super.initState();
    _wakelock = ref.read(wakelockProvider);
    ref.listenManual(rowingEventsProvider, (_, events) => _listen(events), fireImmediately: true);
    ref.listenManual(ergConnectionStateProvider, (_, state) {
      _updateWakelock(state.value);
      if (state.value == ErgConnectionState.connected) _startTemplate();
    }, fireImmediately: true);
    ref.listenManual(finishedSessionProvider, (_, id) {
      if (id != null) _showFinished(id);
    });
  }

  void _startTemplate() {
    final template = widget.template;
    if (template == null || _templateStarted) return;
    _templateStarted = true;
    // Not within the listener that reports the connection.
    Future.microtask(() => ref.read(sessionRecorderProvider.notifier).start(template: template));
  }

  /// The session ended by itself after its last lap.
  Future<void> _showFinished(int id) async {
    ref.read(finishedSessionProvider.notifier).clear();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SessionSummaryScreen(sessionId: id)));
  }

  void _listen(Stream<RowingEvent> events) {
    _events?.cancel();
    _restartStaleTimer();
    _events = events.listen((event) {
      _restartStaleTimer();
      if (event is StatusTick) {
        setState(() {
          _tick = event;
          _stale = false;
        });
      }
    });
  }

  void _restartStaleTimer() {
    _staleTimer?.cancel();
    _staleTimer = Timer(staleAfter, () {
      if (mounted) setState(() => _stale = true);
    });
  }

  void _updateWakelock(ErgConnectionState? state) {
    final on = state == ErgConnectionState.connected || state == ErgConnectionState.reconnecting;
    if (on == _wakelockOn) return;
    _wakelockOn = on;
    on ? _wakelock?.enable() : _wakelock?.disable();
  }

  @override
  void dispose() {
    _events?.cancel();
    _staleTimer?.cancel();
    if (_wakelockOn) _wakelock?.disable();
    super.dispose();
  }

  Future<void> _disconnect() async {
    // A running session is kept; it ends here like with "Session beenden".
    await ref.read(sessionRecorderProvider.notifier).stop();
    await ref.read(activeErgSourceProvider.notifier).clear();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _startSession() => ref.read(sessionRecorderProvider.notifier).start();

  Future<void> _stopSession() async {
    final id = await ref.read(sessionRecorderProvider.notifier).stop();
    if (id == null || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SessionSummaryScreen(sessionId: id)));
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(activeErgSourceProvider);
    final connected = ref.watch(ergConnectionStateProvider).value == ErgConnectionState.connected;
    final recording = ref.watch(sessionRecorderProvider);
    return PopScope(
      canPop: false,
      // Going back ends the connection, the same as "Trennen".
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _disconnect();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const ConnectionIndicator(),
          actions: [
            TextButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.link_off),
              label: Text(context.l10n.liveDisconnect),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_stale && connected)
                MaterialBanner(
                  content: Text(context.l10n.liveStale),
                  actions: [const SizedBox.shrink()],
                ),
              if ((recording?.lap, recording?.template) case (final lap?, final template?))
                CourseBar(lap: lap, course: template.course.definition),
              Expanded(
                child: _Metrics(
                  tick: _tick,
                  session: recording?.progress,
                  paceZone: ZoneHint.pace(context.l10n, recording?.lap?.pace),
                  strokeRateZone: ZoneHint.strokeRate(context.l10n, recording?.lap?.strokeRate),
                  outdated: _stale,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: recording == null
                      ? FilledButton.icon(
                          onPressed: connected ? _startSession : null,
                          icon: const Icon(Icons.fiber_manual_record),
                          label: Text(context.l10n.liveStartSession),
                        )
                      : FilledButton.tonalIcon(
                          onPressed: _stopSession,
                          icon: const Icon(Icons.stop),
                          label: Text(context.l10n.liveStopSession),
                        ),
                ),
              ),
              if (source is SimulatedSource)
                SimulatorControls(
                  source: source,
                  onProtocolChanged: recording == null
                      ? (protocol) => ref.read(activeErgSourceProvider.notifier).use(source.withProtocol(protocol))
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({
    required this.tick,
    required this.session,
    required this.outdated,
    this.paceZone,
    this.strokeRateZone,
  });

  final StatusTick? tick;

  /// Time and distance of the running session, shown instead of the PM5's.
  final SessionProgress? session;
  final bool outdated;
  final ZoneHint? paceZone;
  final ZoneHint? strokeRateZone;

  @override
  Widget build(BuildContext context) {
    final tick = this.tick;
    final l10n = context.l10n;
    final secondary = [
      _Metric(
        key: const Key('metric-elapsed'),
        label: l10n.metricTime,
        value: formatElapsed(session?.elapsed ?? tick?.elapsed ?? Duration.zero),
      ),
      _Metric(
        key: const Key('metric-distance'),
        label: l10n.metricDistance,
        value: formatDistance(session?.distanceMeters ?? tick?.distanceMeters ?? 0),
      ),
      _Metric(key: const Key('metric-watts'), label: l10n.metricWatts, value: formatWhole(tick?.watts)),
      _Metric(
        key: const Key('metric-spm'),
        label: l10n.metricStrokeRate,
        value: formatWhole(tick?.strokeRate),
        zone: strokeRateZone,
      ),
      if (tick?.heartRate != null)
        _Metric(key: const Key('metric-hr'), label: l10n.metricHeartRate, value: formatWhole(tick!.heartRate)),
    ];
    final pace = _Metric(
      key: const Key('metric-pace'),
      label: l10n.metricPace,
      value: formatPace(tick?.pace),
      zone: paceZone,
    );

    return Opacity(
      opacity: outdated ? 0.4 : 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final landscape = constraints.maxWidth > constraints.maxHeight;
          final grid = _Grid(columns: 2, children: secondary);
          return Padding(
            padding: const EdgeInsets.all(8),
            child: landscape
                ? Row(
                    children: [
                      Expanded(flex: 3, child: pace),
                      Expanded(flex: 2, child: grid),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(flex: 2, child: pace),
                      Expanded(flex: 3, child: grid),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <List<Widget>>[
      for (var i = 0; i < children.length; i += columns) children.sublist(i, (i + columns).clamp(0, children.length)),
    ];
    return Column(
      children: [
        for (final row in rows)
          Expanded(
            child: Row(
              children: [
                for (final cell in row) Expanded(child: cell),
                for (var i = row.length; i < columns; i++) const Spacer(),
              ],
            ),
          ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({super.key, required this.label, required this.value, this.zone});

  final String label;
  final String value;

  /// Whether the value is in the band of the segment; null without a band.
  final ZoneHint? zone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zone = this.zone;
    final (background, foreground) = switch (zone) {
      null => (null, null),
      ZoneHint(inZone: true) => (const Color(0xFF1B5E20), Colors.white),
      ZoneHint(inZone: false) => (theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer),
    };
    final labelStyle = theme.textTheme.labelLarge?.copyWith(color: foreground);
    return Card(
      key: zone == null ? null : Key('zone-${zone.inZone ? 'in' : 'out'}'),
      color: background,
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: Text(label, style: labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
                // The direction in words and as a symbol, not only as colour.
                if (zone != null) ...[
                  const SizedBox(width: 8),
                  Icon(zone.icon, size: 16, color: foreground),
                  const SizedBox(width: 2),
                  Flexible(child: Text(zone.text, style: labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ],
            ),
            Expanded(
              child: FittedBox(
                child: Text(
                  value,
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
