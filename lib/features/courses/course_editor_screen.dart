import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/oar_stepper.dart';
import '../../data/courses/course.dart';
import '../../data/courses/course_layout.dart';
import '../../data/courses/course_providers.dart';
import '../../data/zones/zone.dart';
import '../../data/zones/zone_providers.dart';
import '../../l10n/l10n.dart';
import 'course_format.dart';
import 'course_strip.dart';
import 'place_zone_screen.dart';
import 'error_card.dart';
import 'placement_error_text.dart';

/// Creates a course, or edits [course] when given: its length and the zones
/// placed in it (Change zones).
class CourseEditorScreen extends ConsumerStatefulWidget {
  const CourseEditorScreen({super.key, this.course});

  final Course? course;

  @override
  ConsumerState<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends ConsumerState<CourseEditorScreen> {
  late final _name = TextEditingController(text: widget.course?.name);
  late var _axis = widget.course?.axis ?? CourseAxis.distance;
  late var _length = widget.course?.definition.length ?? _defaultLength(_axis);
  late var _placements =
      widget.course?.definition.placements ?? const <ZonePlacement>[];
  var _errors = <String>[];

  /// The index in [_placements] of the zone being moved, outlined in the
  /// strip and the list (Change course-editor-flow, D3).
  int? _moving;

  bool get _isNew => widget.course == null;

  /// 2000 m or 4:00.
  static int _defaultLength(CourseAxis axis) =>
      axis == CourseAxis.distance ? 2000 : 240;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Map<int, Zone> get _zones => _zonesById(ref.read(zonesProvider).value);

  CourseLayout _layout(Map<int, Zone> zones) => resolveCourse(
    axis: _axis,
    length: _length,
    placements: _placements,
    zones: zones,
  );

  /// Places a zone on its own screen, starting at [start].
  Future<void> _place({int start = 0}) async {
    final placement = await openPlaceZone(
      context,
      axis: _axis,
      length: _length,
      placements: _placements,
      start: start,
    );
    if (placement == null || !mounted) return;
    setState(() {
      _errors = [];
      _placements = [..._placements, placement]
        ..sort((a, b) => a.start.compareTo(b.start));
    });
  }

  void _remove(int index) {
    setState(() {
      _moving = null;
      _placements = [
        for (final (i, p) in _placements.indexed)
          if (i != index) p,
      ];
    });
  }

  /// Marks the zone at [index] for moving; a tap on the marked zone ends it.
  void _mark(int index, {bool toggle = true}) =>
      setState(() => _moving = toggle && _moving == index ? null : index);

  /// Moves the marked zone to [start], between its neighbours.
  void _moveTo(int start) => setState(() {
    _placements = [
      for (final (i, p) in _placements.indexed)
        i == _moving ? ZonePlacement(zoneId: p.zoneId, start: start) : p,
    ];
  });

  /// How far the zone at [index] may move: from the end of the zone before
  /// it, or 0, to where it touches the zone after it, or the end.
  (int, int) _moveRange(int index, Map<int, Zone> zones) {
    final length = zones[_placements[index].zoneId]?.length ?? 0;
    final before = index > 0 ? _placements[index - 1] : null;
    final after = index + 1 < _placements.length
        ? _placements[index + 1]
        : null;
    return (
      before == null ? 0 : before.start + (zones[before.zoneId]?.length ?? 0),
      (after?.start ?? _length) - length,
    );
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final errors = <String>[];
    final name = _name.text.trim();
    if (name.isEmpty) errors.add(l10n.courseNameMissing);
    final layout = _layout(_zones);
    errors.addAll([for (final e in layout.errors) placementErrorText(l10n, e)]);
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }

    final definition = layout.definition!;
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

  /// Opens segment [i] like its row: a zone is marked for moving, a free gap
  /// ends moving and places a zone there.
  Future<void> _openSegment(
    CourseDefinition definition,
    int i, {
    bool toggle = true,
  }) async {
    if (definition.segments[i].zoneId != null) {
      _mark(_indexAt(definition, i), toggle: toggle);
      return;
    }
    setState(() => _moving = null);
    await _place(start: definition.segmentStarts[i]);
  }

  @override
  Widget build(BuildContext context) {
    final zones = _zonesById(ref.watch(zonesProvider).value);
    final distance = _axis == CourseAxis.distance;
    final layout = _layout(zones);
    final rowed = widget.course == null
        ? 0
        : ref.watch(courseRowCountsProvider).value?[widget.course!.id]?.newest;
    final l10n = context.l10n;
    final moving = _moving == null ? null : _placements[_moving!].start;
    final selected = switch (layout.definition) {
      final definition? when moving != null => definition.segmentStarts.indexOf(
        moving,
      ),
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.courseNew : l10n.courseEdit),
        actions: [
          IconButton(
            tooltip: l10n.actionSave,
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePortrait,
              AppSpacing.l,
              AppSpacing.pagePortrait,
              32,
            ),
            children: [
              if (_errors.isNotEmpty) ErrorCard(errors: _errors),
              _Label(l10n.fieldName),
              TextField(
                key: const Key('course-name'),
                controller: _name,
                style: AppTextStyles.cardTitle.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Label(l10n.fieldAxis),
                        _AxisChoice(
                          axis: _axis,
                          // The axis of a stored course stays, its laps would not compare;
                          // placed zones keep it too.
                          onChanged: _isNew && _placements.isEmpty
                              ? (axis) => setState(() {
                                  _axis = axis;
                                  _length = _defaultLength(_axis);
                                })
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Label(l10n.fieldLengthPlain),
                        OarStepper(
                          key: const Key('course-length'),
                          value: _length,
                          step: _courseStep(_axis),
                          min: _courseStep(_axis),
                          stepLabel: distance
                              ? '${_courseStep(_axis)} m'
                              : l10n.stepSeconds(_courseStep(_axis)),
                          format: distance
                              ? null
                              : (v) => formatCourseLength(_axis, v),
                          unit: distance ? 'm' : 'min',
                          label: l10n.fieldLength(distance ? 'm' : 'm:ss'),
                          size: OarStepperSize.compact,
                          onChanged: (v) => setState(() => _length = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              _Label(l10n.courseSequence),
              if (layout.definition case final definition?) ...[
                CourseStrip(
                  key: const Key('course-strip'),
                  definition: definition,
                  height: CourseStrip.namedHeight,
                  showNames: true,
                  selected: selected,
                  onSegmentTap: (i) => _openSegment(definition, i),
                  onSegmentLongPress: (i) =>
                      _openSegment(definition, i, toggle: false),
                ),
                const SizedBox(height: 6),
                _Ticks(axis: _axis, length: definition.length),
                if (_moving case final moving?)
                  if (zones[_placements[moving].zoneId] case final zone?) ...[
                    const SizedBox(height: AppSpacing.m),
                    _MovePanel(
                      axis: _axis,
                      zone: zone,
                      start: _placements[moving].start,
                      range: _moveRange(moving, zones),
                      onChanged: _moveTo,
                      onDone: () => setState(() => _moving = null),
                    ),
                  ],
                const SizedBox(height: AppSpacing.m),
                _SectionCard(
                  children: [
                    for (final (i, segment) in definition.segments.indexed)
                      _SectionTile(
                        key: Key('section-$i'),
                        axis: _axis,
                        start: definition.segmentStarts[i],
                        segment: segment,
                        color: CourseStrip.segmentColors(
                          definition.segments,
                        )[i],
                        selected: i == selected,
                        onPlace: segment.zoneId == null
                            ? () => _openSegment(definition, i)
                            : null,
                        onMove: segment.zoneId == null
                            ? null
                            : () => _openSegment(definition, i),
                        onRemove: segment.zoneId == null
                            ? null
                            : () => _remove(_indexAt(definition, i)),
                      ),
                  ],
                ),
              ] else ...[
                // The length no longer fits the zones: show them as placed.
                ErrorCard(
                  errors: [
                    for (final e in layout.errors) placementErrorText(l10n, e),
                  ],
                ),
                _SectionCard(
                  children: [
                    for (final (i, p) in _placements.indexed)
                      if (zones[p.zoneId] case final zone?)
                        _SectionTile(
                          key: Key('section-$i'),
                          axis: _axis,
                          start: p.start,
                          segment: zone.segment,
                          color: AppColors.zoneIn,
                          onRemove: () => _remove(i),
                        ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.m),
              OutlinedButton.icon(
                key: const Key('place-zone'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => _place(start: _firstFree()),
                icon: const Icon(Icons.add),
                label: Text(l10n.coursePlaceZone),
              ),
              if (rowed != null && rowed > 0) ...[
                const SizedBox(height: AppSpacing.l),
                _VersionHint(rowed: rowed),
              ],
              const SizedBox(height: AppSpacing.xxl),
              FilledButton(onPressed: _save, child: Text(l10n.actionSave)),
            ],
          ),
        ),
      ),
    );
  }

  /// The end of the last placed zone, or 0; where a new zone starts.
  int _firstFree() {
    final zones = _zones;
    var end = 0;
    for (final p in _placements) {
      final length = zones[p.zoneId]?.length ?? 0;
      if (p.start + length > end) end = p.start + length;
    }
    return end < _length ? end : 0;
  }

  /// The index in [_placements] of the zone at segment [i].
  int _indexAt(CourseDefinition definition, int i) {
    final start = definition.segmentStarts[i];
    return _placements.indexWhere((p) => p.start == start);
  }
}

/// A label above a field, in capitals.
class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text.toUpperCase(), style: AppTextStyles.label),
    );
  }
}

/// Distance or time; without [onChanged] the axis is fixed and the other one dimmed.
class _AxisChoice extends StatelessWidget {
  const _AxisChoice({required this.axis, required this.onChanged});

  final CourseAxis axis;
  final ValueChanged<CourseAxis>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget option(CourseAxis value, String text) {
      final selected = axis == value;
      final enabled = onChanged != null;
      return Expanded(
        child: Semantics(
          inMutuallyExclusiveGroup: true,
          checked: selected,
          enabled: enabled,
          child: Material(
            color: selected ? AppColors.line : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: enabled ? () => onChanged!(value) : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 47),
                child: Center(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? AppColors.text
                          : AppColors.textMuted.withValues(
                              alpha: enabled ? 1 : 0.35,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            option(CourseAxis.distance, l10n.axisDistance),
            const SizedBox(width: 4),
            option(CourseAxis.time, l10n.axisTime),
          ],
        ),
      ),
    );
  }
}

/// Positions below the strip at each quarter of the course, the unit at the end.
class _Ticks extends StatelessWidget {
  const _Ticks({required this.axis, required this.length});

  final CourseAxis axis;
  final int length;

  @override
  Widget build(BuildContext context) {
    String label(int quarter) {
      final at = (length * quarter / 4).round();
      final text = axis == CourseAxis.distance
          ? '$at'
          : formatCourseLength(axis, at);
      if (quarter < 4) return text;
      return axis == CourseAxis.distance ? '$text m' : '$text min';
    }

    return SizedBox(
      height: 16,
      child: Stack(
        children: [
          for (var quarter = 0; quarter <= 4; quarter++)
            Align(
              alignment: Alignment(quarter / 2 - 1, 0),
              child: Text(
                label(quarter),
                style: AppTextStyles.caption.copyWith(
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The parts of the course on one card, divided by lines.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.cardLarge),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const Divider(height: 1),
            child,
          ],
        ],
      ),
    );
  }
}

/// A free gap or a placed zone in the course.
class _SectionTile extends StatelessWidget {
  const _SectionTile({
    super.key,
    required this.axis,
    required this.start,
    required this.segment,
    required this.color,
    this.selected = false,
    this.onPlace,
    this.onMove,
    this.onRemove,
  });

  final CourseAxis axis;
  final int start;
  final CourseSegment segment;

  /// The colour of the segment in the strip.
  final Color color;
  final bool selected;
  final VoidCallback? onPlace;
  final VoidCallback? onMove;
  final VoidCallback? onRemove;

  /// Width of the column with the position, enough for `1500–2000 m`.
  static const _positionWidth = 92.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final end = start + segment.length;
    if (segment.zoneId == null) {
      return ColoredBox(
        color: selected ? AppColors.zoneInSurface : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.l,
            right: AppSpacing.xs,
          ),
          child: Row(
            children: [
              SizedBox(
                width: _positionWidth,
                child: Text(
                  formatCourseRange(axis, start, end),
                  style: AppTextStyles.caption,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Text(l10n.segmentFree, style: AppTextStyles.caption),
              ),
              IconButton(
                tooltip: l10n.coursePlaceHere,
                color: AppColors.textMuted,
                iconSize: 20,
                icon: const Icon(Icons.add),
                onPressed: onPlace,
              ),
            ],
          ),
        ),
      );
    }
    final bands = formatSegmentBands(l10n, segment);
    return Material(
      color: selected ? AppColors.zoneInSurface : Colors.transparent,
      child: InkWell(
        onTap: onMove,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.m,
            AppSpacing.xs,
            AppSpacing.m,
          ),
          child: Row(
            children: [
              SizedBox(
                width: _positionWidth,
                child: Text(
                  l10n.courseZoneFrom(formatCourseLength(axis, start)),
                  style: AppTextStyles.caption,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Container(
                width: 10,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${segment.zoneName ?? l10n.segmentZone} · ${formatCourseLength(axis, segment.length)}',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (bands.isNotEmpty)
                      Text(bands, style: AppTextStyles.caption),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.courseRemoveZone,
                color: AppColors.textMuted,
                iconSize: 20,
                icon: const Icon(Icons.close),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Moves the marked zone with the oar buttons, within [range] (D3).
class _MovePanel extends StatelessWidget {
  const _MovePanel({
    required this.axis,
    required this.zone,
    required this.start,
    required this.range,
    required this.onChanged,
    required this.onDone,
  });

  final CourseAxis axis;
  final Zone zone;
  final int start;
  final (int, int) range;
  final ValueChanged<int> onChanged;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final distance = axis == CourseAxis.distance;
    final step = placeZoneStep(axis);
    return Container(
      key: const Key('move-panel'),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.cardLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.courseMovingZone(zone.name),
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                ),
              ),
              TextButton(
                key: const Key('move-done'),
                onPressed: onDone,
                child: Text(l10n.actionDone),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          OarStepper(
            key: const Key('move-start'),
            value: start,
            step: step,
            min: range.$1,
            max: range.$2,
            stepLabel: distance ? '$step m' : l10n.stepSeconds(step),
            format: distance ? null : (v) => formatCourseLength(axis, v),
            unit: distance ? 'm' : 'min',
            label: l10n.courseStart(distance ? 'm' : 'm:ss'),
            onChanged: onChanged,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatCourseRange(axis, start, start + zone.length),
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

/// Says that changing a course rowed in its newest version stores a new version.
class _VersionHint extends StatelessWidget {
  const _VersionHint({required this.rowed});

  final int rowed;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('course-version-hint'),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: AppSpacing.m,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.courseVersionHint(rowed),
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}

/// Steps of design D7 for the length of a course: 100 m or 30 s.
int _courseStep(CourseAxis axis) => axis == CourseAxis.distance ? 100 : 30;

Map<int, Zone> _zonesById(List<ZoneUsage>? usages) => {
  for (final u in usages ?? const <ZoneUsage>[]) u.zone.id: u.zone,
};
