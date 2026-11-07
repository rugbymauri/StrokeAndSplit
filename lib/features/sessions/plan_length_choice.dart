import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/oar_stepper.dart';
import '../../app/widgets/segment_choice.dart';
import '../../data/sessions/session_plan.dart';
import '../../l10n/l10n.dart';
import '../live/formatters.dart';

/// More laps than anyone rows in one session.
const _maxLaps = 99;

/// The longest total time in minutes.
const _maxMinutes = 180;

/// How long a plan lasts: laps, a total rowing time or open, with the input
/// of the chosen option below; shared by the start screen of a course and
/// the workout editor (course-rowing-free, Design D6; workout-course-chain,
/// Design D8). The values of all options stay while switching between them.
/// The keys of its parts start with [keyPrefix], e.g. `course-start-laps`.
class PlanLengthChoice extends StatefulWidget {
  const PlanLengthChoice({
    super.key,
    required this.initial,
    required this.onChanged,
    required this.keyPrefix,
  });

  final PlanLength initial;
  final ValueChanged<PlanLength> onChanged;
  final String keyPrefix;

  @override
  State<PlanLengthChoice> createState() => _PlanLengthChoiceState();
}

enum _Kind { laps, duration, open }

class _PlanLengthChoiceState extends State<PlanLengthChoice> {
  late var _kind = switch (widget.initial) {
    LapCount() => _Kind.laps,
    TimeLimit() => _Kind.duration,
    OpenLength() => _Kind.open,
  };
  late var _laps = switch (widget.initial) {
    LapCount(:final count) => count,
    _ => 3,
  };
  late var _minutes = switch (widget.initial) {
    TimeLimit(:final time) => time.inMinutes,
    _ => 30,
  };

  PlanLength get _length => switch (_kind) {
    _Kind.laps => LapCount(_laps),
    _Kind.duration => TimeLimit(Duration(minutes: _minutes)),
    _Kind.open => const OpenLength(),
  };

  void _change(VoidCallback change) {
    setState(change);
    widget.onChanged(_length);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prefix = widget.keyPrefix;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentChoice(
          key: Key('$prefix-length'),
          options: [
            (_Kind.laps, l10n.courseStartLaps),
            (_Kind.duration, l10n.courseStartDuration),
            (_Kind.open, l10n.courseStartOpen),
          ],
          value: _kind,
          onChanged: (kind) => _change(() => _kind = kind),
        ),
        const SizedBox(height: AppSpacing.l),
        // Only the input of the chosen option.
        switch (_kind) {
          _Kind.laps => OarStepper(
            key: Key('$prefix-laps'),
            value: _laps,
            step: 1,
            min: 1,
            max: _maxLaps,
            stepLabel: l10n.lapsCount(1),
            label: l10n.courseStartLaps,
            unit: l10n.workoutLapsUnit(_laps),
            onChanged: (laps) => _change(() => _laps = laps),
          ),
          _Kind.duration => OarStepper(
            key: Key('$prefix-duration'),
            value: _minutes,
            step: 1,
            min: 1,
            max: _maxMinutes,
            stepLabel: l10n.stepMinutes(1),
            label: l10n.courseStartDuration,
            format: (minutes) => formatElapsed(Duration(minutes: minutes)),
            onChanged: (minutes) => _change(() => _minutes = minutes),
          ),
          _Kind.open => Text(
            l10n.courseStartOpenHint,
            key: Key('$prefix-open-hint'),
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        },
      ],
    );
  }
}
