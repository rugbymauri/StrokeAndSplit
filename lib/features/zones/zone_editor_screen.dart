import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  late final _length = TextEditingController(text: _zone == null ? '' : _lengthText(_zone.length));
  late final _paceFast = TextEditingController(text: _pace(_zone?.paceFastCs));
  late final _paceSlow = TextEditingController(text: _pace(_zone?.paceSlowCs));
  late final _spmMin = TextEditingController(text: _zone?.spmMin?.toString());
  late final _spmMax = TextEditingController(text: _zone?.spmMax?.toString());

  /// The courses containing the zone, by name; empty for a new zone.
  var _courses = <String>[];
  var _errors = <String>[];

  bool get _isNew => _zone == null;

  static String _pace(int? cs) => cs == null ? '' : formatPaceBound(cs);

  String _lengthText(int length) => _axis == CourseAxis.distance ? '$length' : formatCourseLength(_axis, length);

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
    for (final c in [_name, _length, _paceFast, _paceSlow, _spmMin, _spmMax]) {
      c.dispose();
    }
    super.dispose();
  }

  /// The zone as entered, or null with the reasons in [errors].
  Zone? _read(List<String> errors) {
    final l10n = context.l10n;
    int? field(TextEditingController c, int? Function(String) parse, String Function(String) invalid) {
      final text = c.text.trim();
      if (text.isEmpty) return null;
      final value = parse(text);
      if (value == null) errors.add(invalid(text));
      return value;
    }

    final zone = Zone(
      id: _zone?.id ?? 0,
      name: _name.text.trim(),
      axis: _axis,
      length: field(_length, (t) => parseCourseLength(_axis, t), l10n.invalidLength) ?? 0,
      paceFastCs: field(_paceFast, parsePace, l10n.invalidPace),
      paceSlowCs: field(_paceSlow, parsePace, l10n.invalidPace),
      spmMin: field(_spmMin, int.tryParse, l10n.invalidStrokeRate),
      spmMax: field(_spmMax, int.tryParse, l10n.invalidStrokeRate),
    );
    if (errors.isNotEmpty) return null;
    errors.addAll([for (final e in zoneErrors(zone)) zoneErrorText(l10n, e)]);
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
      setState(() => _errors = [l10n.zoneConflict(l10n.quotedNames(conflict.courses))]);
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
          content: Text([
            l10n.zoneDeleteBody(zone.name),
            if (_courses.isNotEmpty) l10n.zoneDeleteCourses(l10n.quotedNames(_courses)),
          ].join('\n\n')),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.actionCancel)),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.actionDelete)),
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
    final unit = _axis == CourseAxis.distance ? 'm' : 'm:ss';
    final l10n = context.l10n;
    Widget field(TextEditingController controller, String key, String label, String hint, TextInputType keyboard) =>
        Expanded(
          child: TextField(
            key: Key('zone-$key'),
            controller: controller,
            keyboardType: keyboard,
            decoration: InputDecoration(labelText: label, hintText: hint),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.zoneNew : l10n.zoneEdit),
        actions: [
          if (!_isNew)
            IconButton(tooltip: l10n.actionDelete, icon: const Icon(Icons.delete_outline), onPressed: _delete),
          IconButton(tooltip: l10n.actionSave, icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: Center(
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
                    title: Text(l10n.zoneInCourses(l10n.quotedNames(_courses))),
                    subtitle: Text(l10n.zoneInCoursesHint),
                  ),
                ),
              TextField(
                key: const Key('zone-name'),
                controller: _name,
                decoration: InputDecoration(labelText: l10n.fieldName, hintText: l10n.zoneNameHint),
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
                onSelectionChanged: _courses.isEmpty ? (axis) => setState(() => _axis = axis.single) : null,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('zone-length'),
                controller: _length,
                keyboardType: _axis == CourseAxis.distance ? TextInputType.number : TextInputType.datetime,
                decoration: InputDecoration(labelText: l10n.fieldLength(unit)),
              ),
              const SizedBox(height: 24),
              Text(l10n.zonePaceBand, style: Theme.of(context).textTheme.titleSmall),
              Row(children: [
                field(_paceFast, 'pace-fast', l10n.zonePaceFastest, '1:45', TextInputType.datetime),
                const SizedBox(width: 12),
                field(_paceSlow, 'pace-slow', l10n.zonePaceSlowest, '1:50', TextInputType.datetime),
              ]),
              const SizedBox(height: 24),
              Text(l10n.zoneSpmBand, style: Theme.of(context).textTheme.titleSmall),
              Row(children: [
                field(_spmMin, 'spm-min', l10n.zoneSpmFrom, '30', TextInputType.number),
                const SizedBox(width: 12),
                field(_spmMax, 'spm-max', l10n.zoneSpmTo, '34', TextInputType.number),
              ]),
              const SizedBox(height: 8),
              Text(l10n.zoneBandHint, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: Text(l10n.actionSave)),
            ],
          ),
        ),
      ),
    );
  }
}
