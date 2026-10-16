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
    int? field(TextEditingController c, int? Function(String) parse, String what) {
      final text = c.text.trim();
      if (text.isEmpty) return null;
      final value = parse(text);
      if (value == null) errors.add('$what „$text“ ist ungültig.');
      return value;
    }

    final zone = Zone(
      id: _zone?.id ?? 0,
      name: _name.text.trim(),
      axis: _axis,
      length: field(_length, (t) => parseCourseLength(_axis, t), 'Die Länge') ?? 0,
      paceFastCs: field(_paceFast, parsePace, 'Die Pace'),
      paceSlowCs: field(_paceSlow, parsePace, 'Die Pace'),
      spmMin: field(_spmMin, int.tryParse, 'Die Schlagzahl'),
      spmMax: field(_spmMax, int.tryParse, 'Die Schlagzahl'),
    );
    if (errors.isNotEmpty) return null;
    final l10n = context.l10n;
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
      builder: (context) => AlertDialog(
        title: const Text('Zone löschen?'),
        content: Text([
          '„${zone.name}“ verschwindet aus der Liste. Bereits geruderte Sessions behalten den Namen der Zone.',
          if (_courses.isNotEmpty)
            'In diesen Strecken wird ihre Stelle frei: ${_courses.map((c) => '„$c“').join(', ')}.',
        ].join('\n\n')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Löschen')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(zoneRepositoryProvider).delete(zone.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final unit = _axis == CourseAxis.distance ? 'm' : 'm:ss';
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
        title: Text(_isNew ? 'Neue Zone' : 'Zone bearbeiten'),
        actions: [
          if (!_isNew) IconButton(tooltip: 'Löschen', icon: const Icon(Icons.delete_outline), onPressed: _delete),
          IconButton(tooltip: 'Speichern', icon: const Icon(Icons.check), onPressed: _save),
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
                    title: Text('Steckt in ${_courses.map((c) => '„$c“').join(', ')}'),
                    subtitle: const Text(
                      'Änderungen gelten in allen diesen Strecken. Wurde eine schon gerudert, bekommt sie eine neue '
                      'Version, alte Sessions bleiben, wie sie waren.',
                    ),
                  ),
                ),
              TextField(
                key: const Key('zone-name'),
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name', hintText: 'z.B. Sprint'),
              ),
              const SizedBox(height: 16),
              SegmentedButton<CourseAxis>(
                segments: const [
                  ButtonSegment(value: CourseAxis.distance, label: Text('Distanz'), icon: Icon(Icons.straighten)),
                  ButtonSegment(value: CourseAxis.time, label: Text('Zeit'), icon: Icon(Icons.timer_outlined)),
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
                decoration: InputDecoration(labelText: 'Länge ($unit)'),
              ),
              const SizedBox(height: 24),
              Text('Pace pro 500 m', style: Theme.of(context).textTheme.titleSmall),
              Row(children: [
                field(_paceFast, 'pace-fast', 'schnellste', '1:45', TextInputType.datetime),
                const SizedBox(width: 12),
                field(_paceSlow, 'pace-slow', 'langsamste', '1:50', TextInputType.datetime),
              ]),
              const SizedBox(height: 24),
              Text('Schlagzahl', style: Theme.of(context).textTheme.titleSmall),
              Row(children: [
                field(_spmMin, 'spm-min', 'ab', '30', TextInputType.number),
                const SizedBox(width: 12),
                field(_spmMax, 'spm-max', 'bis', '34', TextInputType.number),
              ]),
              const SizedBox(height: 8),
              Text(
                'Mindestens ein Band ist nötig, Pace, Schlagzahl oder beides.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: const Text('Speichern')),
            ],
          ),
        ),
      ),
    );
  }
}
