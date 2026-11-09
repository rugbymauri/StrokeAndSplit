import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../../app/platform_providers.dart';
import '../../data/db/database.dart' show CourseAxis;
import '../../data/courses/lap_tracker.dart';
import '../../data/ghost/ghost_progress.dart';
import '../../data/ghost/ghost_providers.dart';
import '../../data/sessions/session_providers.dart';
import '../../data/sources/erg_source.dart';
import '../../data/sources/erg_source_providers.dart';
import '../../data/sources/simulated_source.dart';
import '../../data/sessions/session_plan.dart';
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
import 'pause_hint.dart';
import 'ready_hint.dart';

/// After this long without data the shown values are marked as outdated.
const staleAfter = Duration(seconds: 3);

/// The live rowing metrics, readable from the seat.
class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key, this.plan, this.ghost = true, this.backTo});

  /// Made ready as a session as soon as the source is connected; it starts with the first stroke.
  final SessionPlan? plan;

  /// Whether the ghosts of [plan] run in this session (template-screen, Design D4).
  final bool ghost;

  /// Where back and "done" lead instead of the start screen, e.g. the workout
  /// editor that started [plan] without saving (adhoc-workout, Design D2).
  final Route<dynamic>? backTo;

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  StatusTick? _tick;

  /// The last RR intervals from the strap, shown while they are recent.

  /// The force curves of the last strokes; they belong to the source.
  var _forceCurves = const ForceCurves();
  var _stale = false;
  Timer? _staleTimer;
  StreamSubscription<RowingEvent>? _events;
  Wakelock? _wakelock;
  var _wakelockOn = false;
  var _planStarted = false;

  @override
  void initState() {
    super.initState();
    _wakelock = ref.read(wakelockProvider);
    ref.listenManual(
      rowingEventsProvider,
      (_, events) => _listen(events),
      fireImmediately: true,
    );
    ref.listenManual(ergConnectionStateProvider, (_, state) {
      _updateWakelock(state.value);
      if (state.value == ErgConnectionState.connected) _startPlan();
    }, fireImmediately: true);
    ref.listenManual(finishedSessionProvider, (_, id) {
      if (id != null) _showFinished(id);
    });
  }

  void _startPlan() {
    final plan = widget.plan;
    if (plan == null || _planStarted) return;
    _planStarted = true;
    // Not within the listener that reports the connection.
    Future.microtask(
      () => ref
          .read(sessionRecorderProvider.notifier)
          .start(plan: plan, ghost: widget.ghost),
    );
  }

  /// The session ended by itself after its last lap.
  Future<void> _showFinished(int id) async {
    ref.read(finishedSessionProvider.notifier).clear();
    if (!mounted) return;
    if (await SessionSummaryScreen.showAfterSession(context, id)) {
      await _leaveToStart();
    }
  }

  void _listen(Stream<RowingEvent> events) {
    _events?.cancel();
    // RR intervals of a previous source never belong to the next one.
    _forceCurves = const ForceCurves();
    _restartStaleTimer();
    _events = events.listen((event) {
      _restartStaleTimer();
      if (event is StatusTick) {
        setState(() {
          _tick = event;
          _stale = false;
        });
      } else if (event is StrokeForceCurve) {
        setState(() => _forceCurves = _forceCurves.add(event));
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
    final on =
        state == ErgConnectionState.connected ||
        state == ErgConnectionState.reconnecting;
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

  bool _isBack(Route<dynamic> route) => route == widget.backTo || route.isFirst;

  /// Back or Esc: back to the start screen or [LiveScreen.backTo], the rower stays connected; a replay goes back to the sessions.
  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    // A running session is kept; it ends here like with the end session button. A ready one stores nothing.
    await ref.read(sessionRecorderProvider.notifier).stop();
    final replay =
        ref.read(activeErgSourceProvider)?.kind == ErgSourceKind.replay;
    await _endReplay();
    if (!mounted) return;
    replay
        ? Navigator.of(context).pop()
        : Navigator.of(context).popUntil(_isBack);
  }

  /// A replay is no connection to keep; it ends with the live display.
  Future<void> _endReplay() async {
    if (ref.read(activeErgSourceProvider)?.kind != ErgSourceKind.replay) return;
    await ref.read(activeErgSourceProvider.notifier).clear();
  }

  Future<void> _startSession() =>
      ref.read(sessionRecorderProvider.notifier).start();

  Future<void> _stopSession() async {
    final id = await ref.read(sessionRecorderProvider.notifier).stop();
    if (id == null || !mounted) return;
    if (await SessionSummaryScreen.showAfterSession(context, id)) {
      await _leaveToStart();
    }
  }

  /// "Done" in the summary: back to the start screen or [LiveScreen.backTo], the rower stays connected.
  Future<void> _leaveToStart() async {
    await _endReplay();
    if (mounted) Navigator.of(context).popUntil(_isBack);
  }

  /// Starts a session, or ends the running one; [short] for the narrow column next to the pace box.
  /// The label shrinks rather than wraps where the status beside the button leaves little room.
  Widget _sessionButton(
    ActiveRecording? recording,
    bool connected, {
    bool short = false,
  }) => recording == null
      ? FilledButton.icon(
          onPressed: connected ? _startSession : null,
          icon: const Icon(Icons.fiber_manual_record),
          label: _label(context.l10n.liveStartSession),
        )
      : short
      ? FilledButton.tonal(
          onPressed: _stopSession,
          child: Text(context.l10n.liveStopShort, maxLines: 1),
        )
      : FilledButton.tonalIcon(
          onPressed: _stopSession,
          icon: const Icon(Icons.stop),
          label: _label(context.l10n.liveStopSession),
        );

  static Widget _label(String text) =>
      FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1));

  /// Connection, strap and source, beside the session button in place of a title bar.
  Widget _status() => const LiveStatus();

  /// The live view of [plan] at [lap] with its ghosts, recomputed with
  /// every tick (Change ghost, Design D2–D4). Without [ghost] the ghosts are
  /// not even loaded (template-screen, Design D4).
  Widget _courseView(
    SessionPlan plan,
    LapProgress lap,
    ActiveRecording? recording,
    bool connected,
    ForceCurves? forceCurves, {
    required bool ghost,
  }) {
    final ghosts = ghost
        ? ref.watch(liveGhostsProvider(liveGhostsKey(plan, lap)))
        : null;
    final shares = ghosts == null
        ? null
        : ghostShares(lap, plan.definition, ghosts);
    return CourseLiveView(
      tick: _tick,
      session: recording?.progress,
      lap: lap,
      course: plan.definition,
      limit: plan.plannedDuration,
      courseName: recording?.courseName,
      outdated: _stale,
      forceCurves: forceCurves,
      // On a time course the ghost stands where the rower is; the box shows the gap in metres instead.
      ghost: shares == null || plan.axis == CourseAxis.time
          ? null
          : FrameGhost(
              course: shares.course,
              lap: shares.lap,
              segment: shares.segment,
            ),
      ghostGap: ghosts == null ? null : ghostGap(lap, plan.axis, ghosts.course),
      action: _sessionButton(recording, connected),
      shortAction: _sessionButton(recording, connected, short: true),
      status: _status(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(activeErgSourceProvider);
    final connected =
        ref.watch(ergConnectionStateProvider).value ==
        ErgConnectionState.connected;
    final recording = ref.watch(sessionRecorderProvider);
    final forceCurves = source != null && source.providesForceCurves
        ? _forceCurves
        : null;
    return PopScope(
      canPop: false,
      // Going back leads to the start screen and keeps the rower connected.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: _escapeLeaves(
        Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                const ConnectionNotice(),
                const HeartRateNotice(),
                if (recording?.ready ?? false) const ReadyHint(),
                if (recording?.paused ?? false) const PauseHint(),
                if (_stale && connected)
                  MaterialBanner(
                    content: Text(context.l10n.liveStale),
                    actions: [const SizedBox.shrink()],
                  ),
                Expanded(
                  child: switch ((recording?.lap, recording?.plan)) {
                    (final lap?, final plan?) => _courseView(
                      plan,
                      lap,
                      recording,
                      connected,
                      forceCurves,
                      ghost: recording!.ghost,
                    ),
                    _ => FreeLiveView(
                      tick: _tick,
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
                        ? (protocol) => ref
                              .read(activeErgSourceProvider.notifier)
                              .use(source.withProtocol(protocol))
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The Linux desktop has no back gesture; Esc does the same as going back.
  Widget _escapeLeaves(Widget child) => CallbackShortcuts(
    bindings: {const SingleActivator(LogicalKeyboardKey.escape): _leave},
    child: Focus(autofocus: true, child: child),
  );
}
