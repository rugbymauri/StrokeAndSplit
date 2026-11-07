import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/oar_stepper.dart';
import '../../data/courses/course.dart';
import '../../data/zones/zone.dart';
import '../../data/zones/zone_providers.dart';
import '../../data/zones/zone_repository.dart';
import '../courses/course_format.dart';
import '../../l10n/l10n.dart';
import '../courses/error_card.dart';
import 'zone_error_text.dart';

/// Creates a zone, or edits [zone] when given. A new zone starts with [axis]
/// when given, e.g. when it is created for a course. Pops with the id of a
/// new zone.
class ZoneEditorScreen extends ConsumerStatefulWidget {
  const ZoneEditorScreen({super.key, this.zone, this.axis});

  final Zone? zone;
  final CourseAxis? axis;

  @override
  ConsumerState<ZoneEditorScreen> createState() => _ZoneEditorScreenState();
}

class _ZoneEditorScreenState extends ConsumerState<ZoneEditorScreen> {
  late final _zone = widget.zone;
  late var _axis = _zone?.axis ?? widget.axis ?? CourseAxis.distance;
  late final _name = TextEditingController(text: _zone?.name);
  late var _length = _zone?.length ?? _defaultLength(_axis);

  // A new zone starts with a pace band; the other band is filled in for when
  // it is switched on.
  late var _hasPace =
      _zone == null || _zone.paceFastCs != null || _zone.paceSlowCs != null;
  late var _paceFast = _zone?.paceFastCs ?? _zone?.paceSlowCs ?? 16500;
  late var _paceSlow = _zone?.paceSlowCs ?? _paceFast + _paceGap;
  late var _hasSpm = _zone?.spmMin != null || _zone?.spmMax != null;
  late var _spmMin = _zone?.spmMin ?? _zone?.spmMax ?? 24;
  late var _spmMax = _zone?.spmMax ?? _spmMin + 2;
  late var _hasResistance = _zone?.resistanceLevel != null;
  late var _resistance = _zone?.resistanceLevel ?? _resistanceStart;

  /// The courses containing the zone, by name; empty for a new zone.
  var _courses = <String>[];
  var _errors = <String>[];

  bool get _isNew => _zone == null;

  static int _defaultLength(CourseAxis axis) =>
      axis == CourseAxis.distance ? 100 : 60;

  /// Steps of design D7: 10 m or 10 s.
  static const _lengthStep = 10;

  @override
  void initState() {
    super.initState();
    if (!_isNew) {
      ref.read(zoneRepositoryProvider).coursesUsing(_zone!.id).then((courses) {
        if (mounted) setState(() => _courses = courses);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// The zone as entered, or null with the reasons in [errors].
  Zone? _read(List<String> errors) {
    final zone = Zone(
      id: _zone?.id ?? 0,
      name: _name.text.trim(),
      axis: _axis,
      length: _length,
      paceFastCs: _hasPace ? _paceFast : null,
      paceSlowCs: _hasPace ? _paceSlow : null,
      spmMin: _hasSpm ? _spmMin : null,
      spmMax: _hasSpm ? _spmMax : null,
      resistanceLevel: _hasResistance ? _resistance : null,
    );
    errors.addAll([
      for (final e in zoneErrors(zone)) zoneErrorText(context.l10n, e),
    ]);
    return errors.isEmpty ? zone : null;
  }

  Future<void> _save() async {
    final errors = <String>[];
    final zone = _read(errors);
    if (zone == null) {
      setState(() => _errors = errors);
      return;
    }
    final repository = ref.read(zoneRepositoryProvider);
    try {
      if (_isNew) {
        final id = await repository.create(zone);
        if (mounted) Navigator.of(context).pop(id);
        return;
      }
      await repository.update(zone);
    } on ZoneConflict catch (conflict) {
      if (!mounted) return;
      final l10n = context.l10n;
      setState(
        () => _errors = [l10n.zoneConflict(l10n.quotedNames(conflict.courses))],
      );
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final zone = _zone!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.zoneDeleteTitle),
          content: Text(
            [
              l10n.zoneDeleteBody(zone.name),
              if (_courses.isNotEmpty)
                l10n.zoneDeleteCourses(l10n.quotedNames(_courses)),
            ].join('\n\n'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.actionDelete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await ref.read(zoneRepositoryProvider).delete(zone.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final distance = _axis == CourseAxis.distance;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.zoneNew : l10n.zoneEdit),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: l10n.actionDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          IconButton(
            tooltip: l10n.actionSave,
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_errors.isNotEmpty) ErrorCard(errors: _errors),
                if (_courses.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      key: const Key('zone-courses'),
                      leading: const Icon(Icons.info_outline),
                      title: Text(
                        l10n.zoneInCourses(l10n.quotedNames(_courses)),
                      ),
                      subtitle: Text(l10n.zoneInCoursesHint),
                    ),
                  ),
                TextField(
                  key: const Key('zone-name'),
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: l10n.fieldName,
                    hintText: l10n.zoneNameHint,
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<CourseAxis>(
                  segments: [
                    ButtonSegment(
                      value: CourseAxis.distance,
                      label: Text(l10n.axisDistance),
                      icon: const Icon(Icons.straighten),
                    ),
                    ButtonSegment(
                      value: CourseAxis.time,
                      label: Text(l10n.axisTime),
                      icon: const Icon(Icons.timer_outlined),
                    ),
                  ],
                  selected: {_axis},
                  // A zone in a course keeps the axis of the course.
                  onSelectionChanged: _courses.isEmpty
                      ? (axis) => setState(() {
                          _axis = axis.single;
                          _length = _defaultLength(_axis);
                        })
                      : null,
                ),
                const SizedBox(height: 16),
                _Field(
                  label: l10n.fieldLength(distance ? 'm' : 'm:ss'),
                  child: OarStepper(
                    key: const Key('zone-length'),
                    value: _length,
                    step: _lengthStep,
                    min: _lengthStep,
                    stepLabel: distance
                        ? '$_lengthStep m'
                        : l10n.stepSeconds(_lengthStep),
                    format: distance
                        ? null
                        : (v) => formatCourseLength(_axis, v),
                    unit: distance ? 'm' : 'min',
                    label: l10n.fieldLength(distance ? 'm' : 'm:ss'),
                    size: OarStepperSize.compact,
                    onChanged: (v) => setState(() => _length = v),
                  ),
                ),
                const SizedBox(height: 16),
                // Pace, stroke rate and level are the three targets; at least one is needed (Change zone-level-only).
                Text(
                  l10n.zoneBandHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                _BandCard(
                  switchKey: const Key('zone-pace-band'),
                  title: l10n.zonePaceBand,
                  on: _hasPace,
                  onChanged: (on) => setState(() => _hasPace = on),
                  fields: [
                    _Field(
                      label: l10n.zonePaceFastest,
                      child: _paceStepper(
                        key: 'zone-pace-fast',
                        label: l10n.zonePaceFastest,
                        value: _paceFast,
                        min: _paceMin,
                        // The slowest pace moves along and stays within the range.
                        max: _paceMax - (_paceSlow - _paceFast),
                        onChanged: _movePaceBand,
                      ),
                    ),
                    _Field(
                      label: l10n.zonePaceSlowest,
                      child: _paceStepper(
                        key: 'zone-pace-slow',
                        label: l10n.zonePaceSlowest,
                        value: _paceSlow,
                        min: _paceFast,
                        max: _paceMax,
                        onChanged: (v) => _paceSlow = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _BandCard(
                  switchKey: const Key('zone-spm-band'),
                  title: l10n.zoneSpmBand,
                  on: _hasSpm,
                  onChanged: (on) => setState(() => _hasSpm = on),
                  fields: [
                    _Field(
                      label: l10n.zoneSpmFrom,
                      child: _spmStepper(
                        key: 'zone-spm-min',
                        label: l10n.zoneSpmFrom,
                        value: _spmMin,
                        min: _spmLowest,
                        max: _spmMax,
                        onChanged: (v) => _spmMin = v,
                      ),
                    ),
                    _Field(
                      label: l10n.zoneSpmTo,
                      child: _spmStepper(
                        key: 'zone-spm-max',
                        label: l10n.zoneSpmTo,
                        value: _spmMax,
                        min: _spmMin,
                        max: _spmHighest,
                        onChanged: (v) => _spmMax = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _BandCard(
                  switchKey: const Key('zone-resistance-band'),
                  title: l10n.zoneResistance,
                  on: _hasResistance,
                  onChanged: (on) => setState(() => _hasResistance = on),
                  fields: [
                    _Field(
                      label: l10n.zoneResistanceLevel,
                      child: OarStepper(
                        key: const Key('zone-resistance-level'),
                        value: _resistance,
                        step: 1,
                        min: _resistanceLowest,
                        max: _resistanceHighest,
                        stepLabel: l10n.stepLevels(1),
                        label: l10n.zoneResistanceLevel,
                        size: OarStepperSize.compact,
                        background: AppColors.bg,
                        onChanged: (v) => setState(() => _resistance = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.zoneResistanceHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _save, child: Text(l10n.actionSave)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Moves the whole pace band with its fastest pace, keeping the gap (design D7).
  void _movePaceBand(int fast) {
    _paceSlow += fast - _paceFast;
    _paceFast = fast;
  }

  Widget _paceStepper({
    required String key,
    required String label,
    required int value,
    required int min,
    required int max,
    required void Function(int) onChanged,
  }) => OarStepper(
    key: Key(key),
    value: value,
    step: _paceStep,
    min: min,
    max: max,
    stepLabel: context.l10n.stepSeconds(_paceStep ~/ 100),
    format: formatPaceBound,
    unit: '/500 m',
    label: label,
    size: OarStepperSize.compact,
    background: AppColors.bg,
    onChanged: (v) => setState(() => onChanged(v)),
  );

  Widget _spmStepper({
    required String key,
    required String label,
    required int value,
    required int min,
    required int max,
    required void Function(int) onChanged,
  }) => OarStepper(
    key: Key(key),
    value: value,
    step: 1,
    min: min,
    max: max,
    stepLabel: context.l10n.stepStrokes(1),
    unit: 'spm',
    label: label,
    size: OarStepperSize.compact,
    background: AppColors.bg,
    onChanged: (v) => setState(() => onChanged(v)),
  );
}

/// Pace in centiseconds per 500 m: steps of 5 s (design D7) between 1:00 and 5:00.
const _paceStep = 500;
const _paceMin = 6000;
const _paceMax = 30000;

/// Gap between the bounds of the pace band of a new zone: 10 s (design D7).
const _paceGap = 1000;

/// Stroke rates a rower can hold.
const _spmLowest = 10;
const _spmHighest = 60;

/// Resistance levels; the rower clamps to its own range while rowing
/// (Change resistance-control, Design D7).
const _resistanceLowest = 1;
const _resistanceHighest = 25;
const _resistanceStart = 5;

/// A [child] with its [label] above.
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// A band that can be switched off, with its bounds side by side; also the
/// resistance level with a single field.
class _BandCard extends StatelessWidget {
  const _BandCard({
    required this.switchKey,
    required this.title,
    required this.on,
    required this.onChanged,
    required this.fields,
  });

  final Key switchKey;
  final String title;
  final bool on;
  final ValueChanged<bool> onChanged;
  final List<Widget> fields;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.cardLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MergeSemantics(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(key: switchKey, value: on, onChanged: onChanged),
                ],
              ),
            ),
            if (on) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, field) in fields.indexed) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: field),
                  ],
                  // A single field takes the width of one of two.
                  if (fields.length == 1) ...[
                    const SizedBox(width: 12),
                    const Spacer(),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
