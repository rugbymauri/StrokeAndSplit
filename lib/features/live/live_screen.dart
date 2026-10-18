import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../../app/platform_providers.dart';
import '../../data/courses/lap_tracker.dart';
import '../../data/ghost/ghost_progress.dart';
import '../../data/ghost/ghost_providers.dart';
import '../../data/sessions/session_providers.dart';
import '../../data/sources/erg_source.dart';
import '../../data/sources/erg_source_providers.dart';
import '../../data/sources/simulated_source.dart';
import '../../data/templates/session_template.dart';
import '../../l10n/l10n.dart';
import '../connection/connection_indicator.dart';
import '../connection/heart_rate_indicator.dart';
import '../sessions/session_summary_screen.dart';
import '../simulator/simulator_controls.dart';
import 'force_curve.dart';
import 'live_course.dart';
import 'live_free.dart';
import 'live_status.dart';
import 'progress_frame.dart';
import 'ready_hint.dart';

/// After this long without data the shown values are marked as outdated.
const staleAfter = Duration(seconds: 3);

/// The live rowing metrics, readable from the seat.
class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key, this.template});

  /// Made ready as a session as soon as the source is connected; it starts with the first stroke.
  final SessionTemplate? template;

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  StatusTick? _tick;

  /// The last RR intervals from the strap, shown while they are recent.
  HeartBeatIntervals? _beats;

  /// The force curves of the last strokes; they belong to the source, like [_beats].
  var _forceCurves = const ForceCurves();
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
    if (await SessionSummaryScreen.showAfterSession(context, id)) await _leaveToStart();
  }

  void _listen(Stream<RowingEvent> events) {
    _events?.cancel();
    // RR intervals of a previous source never belong to the next one.
    _beats = null;
    _forceCurves = const ForceCurves();
    _restartStaleTimer();
    _events = events.listen((event) {
      _restartStaleTimer();
      if (event is StatusTick) {
        setState(() {
          _tick = event;
          _stale = false;
        });
      } else if (event is HeartBeatIntervals) {
        setState(() => _beats = event);
      } else if (event is StrokeForceCurve) {
        setState(() => _forceCurves = _forceCurves.add(event));
      }
    });
  }

  /// The last RR interval in ms; null without one or once the latest tick is
  /// more than [staleAfter] past it (heart-rate, Design D8). A tick carries no
  /// packet time, so both compare by the rower's elapsed time; this works the
  /// same in a replay.
  int? get _rrIntervalMs {
    final beats = _beats;
    final tick = _tick;
    if (beats == null || tick == null || beats.intervalsMs.isEmpty) return null;
    final age = tick.elapsed - beats.elapsed;
    if (age.isNegative || age > staleAfter) return null;
    return beats.intervalsMs.last;
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

  var _leaving = false;

  /// Back or Esc: back to the start screen, the rower stays connected; a replay goes back to the sessions.
  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    // A running session is kept; it ends here like with the end session button. A ready one stores nothing.
    await ref.read(sessionRecorderProvider.notifier).stop();
    final replay = ref.read(activeErgSourceProvider)?.kind == ErgSourceKind.replay;
    await _endReplay();
    if (!mounted) return;
    replay ? Navigator.of(context).pop() : Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// A replay is no connection to keep; it ends with the live display.
  Future<void> _endReplay() async {
    if (ref.read(activeErgSourceProvider)?.kind != ErgSourceKind.replay) return;
    await ref.read(activeErgSourceProvider.notifier).clear();
  }

  Future<void> _startSession() => ref.read(sessionRecorderProvider.notifier).start();

  Future<void> _stopSession() async {
    final id = await ref.read(sessionRecorderProvider.notifier).stop();
    if (id == null || !mounted) return;
    if (await SessionSummaryScreen.showAfterSession(context, id)) await _leaveToStart();
  }

  /// "Done" in the summary: back to the start screen, the rower stays connected.
  Future<void> _leaveToStart() async {
    await _endReplay();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Starts a session, or ends the running one; [short] for the narrow column next to the pace box.
  /// The label shrinks rather than wraps where the status beside the button leaves little room.
  Widget _sessionButton(ActiveRecording? recording, bool connected, {bool short = false}) => recording == null
      ? FilledButton.icon(
          onPressed: connected ? _startSession : null,
          icon: const Icon(Icons.fiber_manual_record),
          label: _label(context.l10n.liveStartSession),
        )
      : short
          ? FilledButton.tonal(onPressed: _stopSession, child: Text(context.l10n.liveStopShort, maxLines: 1))
          : FilledButton.tonalIcon(
              onPressed: _stopSession,
              icon: const Icon(Icons.stop),
              label: _label(context.l10n.liveStopSession),
            );

  static Widget _label(String text) => FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1));

  /// Connection, strap and source, beside the session button in place of a title bar.
  Widget _status() => const LiveStatus();

  /// The live view of [template] at [lap] with its ghosts, recomputed with
  /// every tick (Change ghost, Design D2–D4).
  Widget _courseView(
    SessionTemplate template,
    LapProgress lap,
    ActiveRecording? recording,
    bool connected,
    ForceCurves? forceCurves,
  ) {
    final ghosts = ref.watch(liveGhostsProvider(liveGhostsKey(template, lap)));
    final shares = ghostShares(lap, template.course.definition, ghosts);
    return CourseLiveView(
      tick: _tick,
      rrIntervalMs: _rrIntervalMs,
      lap: lap,
      course: template.course.definition,
      outdated: _stale,
      forceCurves: forceCurves,
      ghost: FrameGhost(course: shares.course, lap: shares.lap, segment: shares.segment),
      ghostGap: ghostGap(lap, template.course.axis, ghosts.course),
      action: _sessionButton(recording, connected),
      shortAction: _sessionButton(recording, connected, short: true),
      status: _status(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(activeErgSourceProvider);
    final connected = ref.watch(ergConnectionStateProvider).value == ErgConnectionState.connected;
    final recording = ref.watch(sessionRecorderProvider);
    final forceCurves = source != null && source.providesForceCurves ? _forceCurves : null;
    return PopScope(
      canPop: false,
      // Going back leads to the start screen and keeps the rower connected.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: _escapeLeaves(Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const ConnectionNotice(),
              const HeartRateNotice(),
              if (recording?.ready ?? false) const ReadyHint(),
              if (_stale && connected)
                MaterialBanner(
                  content: Text(context.l10n.liveStale),
                  actions: [const SizedBox.shrink()],
                ),
              Expanded(
                child: switch ((recording?.lap, recording?.template)) {
                  (final lap?, final template?) => _courseView(template, lap, recording, connected, forceCurves),
                  _ => FreeLiveView(
                      tick: _tick,
                      rrIntervalMs: _rrIntervalMs,
                      session: recording?.progress,
                      outdated: _stale,
                      forceCurves: forceCurves,
                      action: _sessionButton(recording, connected),
                      status: _status(),
                    ),
                },
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
      )),
    );
  }

  /// The Linux desktop has no back gesture; Esc does the same as going back.
  Widget _escapeLeaves(Widget child) => CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): _leave},
        child: Focus(autofocus: true, child: child),
      );
}
