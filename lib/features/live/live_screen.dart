import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm5_protocol/pm5_protocol.dart';

import '../../app/platform_providers.dart';
import '../../data/sources/erg_source.dart';
import '../../data/sources/erg_source_providers.dart';
import '../../data/sources/simulated_source.dart';
import '../connection/connection_indicator.dart';
import '../simulator/simulator_controls.dart';
import 'formatters.dart';

/// After this long without data the shown values are marked as outdated.
const staleAfter = Duration(seconds: 3);

/// The live rowing metrics, readable from the seat.
class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _wakelock = ref.read(wakelockProvider);
    ref.listenManual(rowingEventsProvider, (_, events) => _listen(events), fireImmediately: true);
    ref.listenManual(ergConnectionStateProvider, (_, state) => _updateWakelock(state.value), fireImmediately: true);
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
    await ref.read(activeErgSourceProvider.notifier).clear();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(activeErgSourceProvider);
    final connected = ref.watch(ergConnectionStateProvider).value == ErgConnectionState.connected;
    return Scaffold(
      appBar: AppBar(
        title: const ConnectionIndicator(),
        actions: [
          TextButton.icon(onPressed: _disconnect, icon: const Icon(Icons.link_off), label: const Text('Trennen')),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_stale && connected)
              MaterialBanner(
                content: const Text('Keine Daten seit 3 Sekunden, die Werte sind veraltet.'),
                actions: [const SizedBox.shrink()],
              ),
            Expanded(child: _Metrics(tick: _tick, outdated: _stale)),
            if (source is SimulatedSource) SimulatorControls(source: source),
          ],
        ),
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.tick, required this.outdated});

  final StatusTick? tick;
  final bool outdated;

  @override
  Widget build(BuildContext context) {
    final tick = this.tick;
    final secondary = [
      _Metric(key: const Key('metric-elapsed'), label: 'Zeit', value: formatElapsed(tick?.elapsed ?? Duration.zero)),
      _Metric(
          key: const Key('metric-distance'),
          label: 'Meter',
          value: formatDistance(tick?.distanceMeters ?? 0)),
      _Metric(key: const Key('metric-watts'), label: 'Watt', value: formatWhole(tick?.watts)),
      _Metric(key: const Key('metric-spm'), label: 'Schläge/min', value: formatWhole(tick?.strokeRate)),
      if (tick?.heartRate != null)
        _Metric(key: const Key('metric-hr'), label: 'Puls', value: formatWhole(tick!.heartRate)),
    ];
    final pace = _Metric(key: const Key('metric-pace'), label: 'Pace /500 m', value: formatPace(tick?.pace));

    return Opacity(
      opacity: outdated ? 0.4 : 1,
      child: LayoutBuilder(builder: (context, constraints) {
        final landscape = constraints.maxWidth > constraints.maxHeight;
        final grid = _Grid(columns: 2, children: secondary);
        return Padding(
          padding: const EdgeInsets.all(8),
          child: landscape
              ? Row(children: [Expanded(flex: 3, child: pace), Expanded(flex: 2, child: grid)])
              : Column(children: [Expanded(flex: 2, child: pace), Expanded(flex: 3, child: grid)]),
        );
      }),
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
            child: Row(children: [
              for (final cell in row) Expanded(child: cell),
              for (var i = row.length; i < columns; i++) const Spacer(),
            ]),
          ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(label, style: theme.textTheme.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
            Expanded(
              child: FittedBox(
                child: Text(
                  value,
                  style: theme.textTheme.displayLarge?.copyWith(
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
