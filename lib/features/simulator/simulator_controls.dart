import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';

import '../../data/sources/simulated_source.dart';
import '../../l10n/l10n.dart';
import '../live/formatters.dart';

/// Target pace, stroke rate, pause and protocol for the simulated rower.
class SimulatorControls extends StatefulWidget {
  const SimulatorControls({
    super.key,
    required this.source,
    this.onProtocolChanged,
  });

  final SimulatedSource source;

  /// Switches to a simulator with another protocol; null while that is not
  /// possible, e.g. during a session.
  final ValueChanged<ErgProtocol>? onProtocolChanged;

  @override
  State<SimulatorControls> createState() => _SimulatorControlsState();
}

class _SimulatorControlsState extends State<SimulatorControls> {
  static const _paceStep = Duration(seconds: 5);
  static const _fastestPace = Duration(minutes: 1, seconds: 20);
  static const _slowestPace = Duration(minutes: 3, seconds: 30);

  SimulatedSource get _source => widget.source;

  void _changePace(Duration delta) {
    final pace = _source.targetPace + delta;
    if (pace < _fastestPace || pace > _slowestPace) return;
    setState(() => _source.targetPace = pace);
  }

  void _changeStrokeRate(int delta) {
    final strokeRate = _source.targetStrokeRate + delta;
    if (strokeRate < 14 || strokeRate > 40) return;
    setState(() => _source.targetStrokeRate = strokeRate);
  }

  void _togglePause() =>
      setState(() => _source.isPaused ? _source.resume() : _source.pause());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 24,
          runSpacing: 8,
          children: [
            _Stepper(
              label: l10n.simTargetPace,
              value: formatPace(_source.targetPace),
              onDecrease: () => _changePace(-_paceStep),
              onIncrease: () => _changePace(_paceStep),
              decreaseTooltip: l10n.simFaster,
              increaseTooltip: l10n.simSlower,
            ),
            _Stepper(
              label: l10n.simTargetStrokeRate,
              value: '${_source.targetStrokeRate}',
              onDecrease: () => _changeStrokeRate(-1),
              onIncrease: () => _changeStrokeRate(1),
              decreaseTooltip: l10n.simFewerStrokes,
              increaseTooltip: l10n.simMoreStrokes,
            ),
            SegmentedButton<ErgProtocol>(
              key: const Key('sim-protocol'),
              segments: const [
                ButtonSegment(value: ErgProtocol.pm5, label: Text('PM5')),
                ButtonSegment(value: ErgProtocol.ftms, label: Text('FTMS')),
              ],
              selected: {_source.protocol},
              showSelectedIcon: false,
              onSelectionChanged: switch (widget.onProtocolChanged) {
                final onChanged? => (selected) => onChanged(selected.single),
                null => null,
              },
            ),
            FilledButton.tonalIcon(
              onPressed: _togglePause,
              icon: Icon(_source.isPaused ? Icons.play_arrow : Icons.pause),
              label: Text(_source.isPaused ? l10n.simResume : l10n.simPause),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
    required this.decreaseTooltip,
    required this.increaseTooltip,
  });

  final String label;
  final String value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final String decreaseTooltip;
  final String increaseTooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label '),
        IconButton(
          onPressed: onDecrease,
          tooltip: decreaseTooltip,
          icon: const Icon(Icons.remove),
        ),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          onPressed: onIncrease,
          tooltip: increaseTooltip,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
