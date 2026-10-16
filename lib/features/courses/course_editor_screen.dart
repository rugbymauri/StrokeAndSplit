import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/courses/course.dart';
import '../../data/courses/course_providers.dart';
import 'course_format.dart';

/// Creates a course, or edits [course] when given.
class CourseEditorScreen extends ConsumerStatefulWidget {
  const CourseEditorScreen({super.key, this.course});

  final Course? course;

  @override
  ConsumerState<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends ConsumerState<CourseEditorScreen> {
  late final _name = TextEditingController(text: widget.course?.name);
  late var _axis = widget.course?.axis ?? CourseAxis.distance;
  late final _length = TextEditingController(
    text: widget.course == null ? '' : _lengthText(widget.course!.definition.length),
  );
  late final _segments = [
    for (final s in widget.course?.definition.segments ?? const [CourseSegment(length: 0)])
      _SegmentFields(s, _lengthText),
  ];
  var _errors = <String>[];

  bool get _isNew => widget.course == null;

  String _lengthText(int length) =>
      length == 0 ? '' : (_axis == CourseAxis.distance ? '$length' : formatCourseLength(_axis, length));

  @override
  void dispose() {
    _name.dispose();
    _length.dispose();
    for (final s in _segments) {
      s.dispose();
    }
    super.dispose();
  }

  void _onLengthChanged(String text) {
    // A single segment always covers the whole course.
    if (_segments.length == 1) _segments.single.length.text = text;
    setState(() {});
  }

  void _split(int i) {
    final segment = _segments[i];
    final length = parseCourseLength(_axis, segment.length.text) ?? 0;
    if (length < 2) {
      setState(() => _errors = ['Segment ${i + 1} ist zu kurz zum Teilen.']);
      return;
    }
    final first = length ~/ 2;
    setState(() {
      segment.length.text = _lengthText(first);
      _segments.insert(i + 1, segment.copy(_lengthText(length - first)));
    });
  }

  void _mergeWithNext(int i) {
    final next = _segments[i + 1];
    final a = parseCourseLength(_axis, _segments[i].length.text) ?? 0;
    final b = parseCourseLength(_axis, next.length.text) ?? 0;
    setState(() {
      _segments[i].length.text = _lengthText(a + b);
      _segments.removeAt(i + 1);
    });
    next.dispose();
  }

  /// The segment boundaries as far as they can be read, for the labels.
  List<int?> get _segmentEnds {
    int? end = 0;
    return [
      for (final s in _segments)
        end = switch ((end, parseCourseLength(_axis, s.length.text))) {
          (final int e, final int l) => e + l,
          _ => null,
        },
    ];
  }

  Future<void> _save() async {
    final errors = <String>[];
    final name = _name.text.trim();
    if (name.isEmpty) errors.add('Der Name fehlt.');
    final lengthText = _length.text.trim();
    final length = lengthText.isEmpty ? 0 : parseCourseLength(_axis, lengthText);
    if (length == null) errors.add('Die Länge „$lengthText“ ist ungültig.');
    final segments = [
      for (final (i, s) in _segments.indexed) s.read(_axis, 'Segment ${i + 1}', errors),
    ];
    if (errors.isEmpty) {
      errors.addAll(courseErrors(CourseDefinition(axis: _axis, length: length!, segments: segments.nonNulls.toList())));
    }
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }

    final definition = CourseDefinition(axis: _axis, length: length!, segments: segments.nonNulls.toList());
    final repository = ref.read(courseRepositoryProvider);
    final course = widget.course;
    if (course == null) {
      await repository.create(name, definition);
    } else {
      if (name != course.name) await repository.rename(course.id, name);
      await repository.updateDefinition(course.id, definition);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final unit = _axis == CourseAxis.distance ? 'm' : 'm:ss';
    final ends = _segmentEnds;
    String position(int? value) => switch (value) {
          null => '?',
          final v when _axis == CourseAxis.distance => '$v',
          final v => formatCourseLength(_axis, v),
        };
    final rangeUnit = _axis == CourseAxis.distance ? ' m' : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Neue Strecke' : 'Strecke bearbeiten'),
        actions: [IconButton(tooltip: 'Speichern', icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_errors.isNotEmpty) _Errors(errors: _errors),
              TextField(
                key: const Key('course-name'),
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              SegmentedButton<CourseAxis>(
                segments: const [
                  ButtonSegment(value: CourseAxis.distance, label: Text('Distanz'), icon: Icon(Icons.straighten)),
                  ButtonSegment(value: CourseAxis.time, label: Text('Zeit'), icon: Icon(Icons.timer_outlined)),
                ],
                selected: {_axis},
                // The axis of a stored course stays, its laps would not compare.
                onSelectionChanged: _isNew ? (axis) => setState(() => _axis = axis.single) : null,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('course-length'),
                controller: _length,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(labelText: 'Länge ($unit)'),
                onChanged: _onLengthChanged,
              ),
              const SizedBox(height: 24),
              Text('Segmente', style: Theme.of(context).textTheme.titleMedium),
              for (final (i, segment) in _segments.indexed)
                _SegmentCard(
                  index: i,
                  fields: segment,
                  unit: unit,
                  range: '${position(i == 0 ? 0 : ends[i - 1])}–${position(ends[i])}$rangeUnit',
                  bands: switch (segment.read(_axis, '', [])) {
                    final s? => formatSegmentBands(s),
                    null => '',
                  },
                  onSplit: () => _split(i),
                  onMergeWithNext: i < _segments.length - 1 ? () => _mergeWithNext(i) : null,
                  onChanged: () => setState(() {}),
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

/// The text fields of one segment.
class _SegmentFields {
  _SegmentFields(CourseSegment segment, String Function(int) lengthText)
      : length = TextEditingController(text: lengthText(segment.length)),
        paceFast = TextEditingController(text: segment.paceFastCs == null ? '' : formatPaceBound(segment.paceFastCs!)),
        paceSlow = TextEditingController(text: segment.paceSlowCs == null ? '' : formatPaceBound(segment.paceSlowCs!)),
        spmMin = TextEditingController(text: segment.spmMin?.toString()),
        spmMax = TextEditingController(text: segment.spmMax?.toString());

  _SegmentFields._copy(_SegmentFields other, String length)
      : length = TextEditingController(text: length),
        paceFast = TextEditingController(text: other.paceFast.text),
        paceSlow = TextEditingController(text: other.paceSlow.text),
        spmMin = TextEditingController(text: other.spmMin.text),
        spmMax = TextEditingController(text: other.spmMax.text);

  final TextEditingController length;
  final TextEditingController paceFast;
  final TextEditingController paceSlow;
  final TextEditingController spmMin;
  final TextEditingController spmMax;

  /// A new segment with the same bands.
  _SegmentFields copy(String length) => _SegmentFields._copy(this, length);

  /// The segment, or null with the reasons added to [errors].
  CourseSegment? read(CourseAxis axis, String name, List<String> errors) {
    final before = errors.length;
    int? field(TextEditingController c, int? Function(String) parse, String what) {
      final text = c.text.trim();
      if (text.isEmpty) return null;
      final value = parse(text);
      if (value == null) errors.add('$name: $what „$text“ ist ungültig.');
      return value;
    }

    final length = field(this.length, (t) => parseCourseLength(axis, t), 'Die Länge') ?? 0;
    final segment = CourseSegment(
      length: length,
      paceFastCs: field(paceFast, parsePace, 'Die Pace'),
      paceSlowCs: field(paceSlow, parsePace, 'Die Pace'),
      spmMin: field(spmMin, int.tryParse, 'Die Schlagzahl'),
      spmMax: field(spmMax, int.tryParse, 'Die Schlagzahl'),
    );
    return errors.length == before ? segment : null;
  }

  void dispose() {
    for (final c in [length, paceFast, paceSlow, spmMin, spmMax]) {
      c.dispose();
    }
  }
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({
    required this.index,
    required this.fields,
    required this.unit,
    required this.range,
    required this.bands,
    required this.onSplit,
    required this.onMergeWithNext,
    required this.onChanged,
  });

  final int index;
  final _SegmentFields fields;
  final String unit;
  final String range;
  final String bands;
  final VoidCallback onSplit;
  final VoidCallback? onMergeWithNext;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    Widget field(TextEditingController controller, String key, String label, String hint) => Expanded(
          child: TextField(
            key: Key('segment-$index-$key'),
            controller: controller,
            keyboardType: TextInputType.datetime,
            decoration: InputDecoration(labelText: label, hintText: hint),
            onChanged: (_) => onChanged(),
          ),
        );

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ['Segment ${index + 1}', range, if (bands.isNotEmpty) bands].join(' · '),
                    key: Key('segment-$index-title'),
                  ),
                ),
                IconButton(tooltip: 'Segment teilen', icon: const Icon(Icons.call_split), onPressed: onSplit),
                if (onMergeWithNext != null)
                  IconButton(
                    tooltip: 'Mit nächstem zusammenlegen',
                    icon: const Icon(Icons.merge),
                    onPressed: onMergeWithNext,
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Row(children: [field(fields.length, 'length', 'Länge ($unit)', '')]),
                  Row(children: [
                    field(fields.paceFast, 'pace-fast', 'Pace schnellste', '2:05'),
                    const SizedBox(width: 12),
                    field(fields.paceSlow, 'pace-slow', 'Pace langsamste', '2:10'),
                  ]),
                  Row(children: [
                    field(fields.spmMin, 'spm-min', 'Schläge/min ab', '20'),
                    const SizedBox(width: 12),
                    field(fields.spmMax, 'spm-max', 'Schläge/min bis', '22'),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Errors extends StatelessWidget {
  const _Errors({required this.errors});

  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final e in errors) Text(e, style: TextStyle(color: colors.onErrorContainer))],
        ),
      ),
    );
  }
}
