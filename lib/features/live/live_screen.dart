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
import 'live_course.dart';
import 'live_free.dart';

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
    // A running session is kept; it ends here like with the end session button.
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

  /// Starts a session, or ends the running one; [short] for the narrow column next to the pace box.
  Widget _sessionButton(ActiveRecording? recording, bool connected, {bool short = false}) => recording == null
      ? FilledButton.icon(
          onPressed: connected ? _startSession : null,
          icon: const Icon(Icons.fiber_manual_record),
          label: Text(context.l10n.liveStartSession),
        )
      : short
          ? FilledButton.tonal(onPressed: _stopSession, child: Text(context.l10n.liveStopShort, maxLines: 1))
          : FilledButton.tonalIcon(
              onPressed: _stopSession,
              icon: const Icon(Icons.stop),
              label: Text(context.l10n.liveStopSession),
            );

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(activeErgSourceProvider);
    final connected = ref.watch(ergConnectionStateProvider).value == ErgConnectionState.connected;
    final recording = ref.watch(sessionRecorderProvider);
    return PopScope(
      canPop: false,
      // Going back ends the connection, the same as the disconnect button.
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
              Expanded(
                child: switch ((recording?.lap, recording?.template)) {
                  (final lap?, final template?) => CourseLiveView(
                      tick: _tick,
                      lap: lap,
                      course: template.course.definition,
                      outdated: _stale,
                      action: _sessionButton(recording, connected),
                      shortAction: _sessionButton(recording, connected, short: true),
                    ),
                  _ => FreeLiveView(
                      tick: _tick,
                      session: recording?.progress,
                      outdated: _stale,
                      action: _sessionButton(recording, connected),
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
      ),
    );
  }
}
