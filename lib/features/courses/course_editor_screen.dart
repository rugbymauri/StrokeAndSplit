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
import '../zones/zone_format.dart';
import '../zones/zones_screen.dart';
import 'course_format.dart';
import 'course_strip.dart';
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
  late var _placements = widget.course?.definition.placements ?? const <ZonePlacement>[];
  var _errors = <String>[];

  bool get _isNew => widget.course == null;

  /// 2000 m or 4:00.
  static int _defaultLength(CourseAxis axis) => axis == CourseAxis.distance ? 2000 : 240;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Map<int, Zone> get _zones => _zonesById(ref.read(zonesProvider).value);

  CourseLayout _layout(Map<int, Zone> zones) =>
      resolveCourse(axis: _axis, length: _length, placements: _placements, zones: zones);

  /// Places a zone, or moves the placement at [index] when given.
  Future<void> _place({int? index, int? start}) async {
    final placement = await showDialog<ZonePlacement>(
      context: context,
      builder: (_) => _PlaceZoneDialog(
        axis: _axis,
        length: _length,
        others: [for (final (i, p) in _placements.indexed) if (i != index) p],
        initial: index == null ? null : _placements[index],
        start: start,
      ),
    );
    if (placement == null) return;
    setState(() {
      _errors = [];
      _placements = [
        for (final (i, p) in _placements.indexed) if (i != index) p,
        placement,
      ]..sort((a, b) => a.start.compareTo(b.start));
    });
  }

  void _remove(int index) {
    setState(() => _placements = [for (final (i, p) in _placements.indexed) if (i != index) p]);
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

  @override
  Widget build(BuildContext context) {
    final zones = _zonesById(ref.watch(zonesProvider).value);
    final distance = _axis == CourseAxis.distance;
    final layout = _layout(zones);
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.courseNew : l10n.courseEdit),
        actions: [IconButton(tooltip: l10n.actionSave, icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_errors.isNotEmpty) ErrorCard(errors: _errors),
              TextField(
                key: const Key('course-name'),
                controller: _name,
                decoration: InputDecoration(labelText: l10n.fieldName),
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
                // The axis of a stored course stays, its laps would not compare;
                // placed zones keep it too.
                onSelectionChanged: _isNew && _placements.isEmpty
                    ? (axis) => setState(() {
                          _axis = axis.single;
                          _length = _defaultLength(_axis);
                        })
                    : null,
              ),
              const SizedBox(height: 16),
              Text(l10n.fieldLength(distance ? 'm' : 'm:ss'), style: AppTextStyles.caption),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: OarStepper(
                    key: const Key('course-length'),
                    value: _length,
                    step: _courseStep(_axis),
                    min: _courseStep(_axis),
                    stepLabel: distance ? '${_courseStep(_axis)} m' : l10n.stepSeconds(_courseStep(_axis)),
                    format: distance ? null : (v) => formatCourseLength(_axis, v),
                    unit: distance ? 'm' : 'min',
                    label: l10n.fieldLength(distance ? 'm' : 'm:ss'),
                    size: OarStepperSize.compact,
                    onChanged: (v) => setState(() => _length = v),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(l10n.courseSequence, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (layout.definition case final definition?) ...[
                CourseStrip(
                  key: const Key('course-strip'),
                  definition: definition,
                  height: CourseStrip.namedHeight,
                  showNames: true,
                ),
                const SizedBox(height: 8),
                for (final (i, segment) in definition.segments.indexed)
                  _SectionTile(
                    key: Key('section-$i'),
                    axis: _axis,
                    start: definition.segmentStarts[i],
                    segment: segment,
                    onPlace: segment.zoneId == null ? () => _place(start: definition.segmentStarts[i]) : null,
                    onMove: segment.zoneId == null ? null : () => _place(index: _indexAt(definition, i)),
                    onRemove: segment.zoneId == null ? null : () => _remove(_indexAt(definition, i)),
                  ),
              ] else ...[
                // The length no longer fits the zones: show them as placed.
                ErrorCard(errors: [for (final e in layout.errors) placementErrorText(l10n, e)]),
                for (final (i, p) in _placements.indexed)
                  if (zones[p.zoneId] case final zone?)
                    _SectionTile(
                      key: Key('section-$i'),
                      axis: _axis,
                      start: p.start,
                      segment: zone.segment,
                      onMove: () => _place(index: i),
                      onRemove: () => _remove(i),
                    ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const Key('place-zone'),
                  onPressed: _place,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.coursePlaceZone),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _save, child: Text(l10n.actionSave)),
            ],
          ),
        ),
      ),
    );
  }

  /// The index in [_placements] of the zone at segment [i].
  int _indexAt(CourseDefinition definition, int i) {
    final start = definition.segmentStarts[i];
    return _placements.indexWhere((p) => p.start == start);
  }
}

/// A free gap or a placed zone in the course.
class _SectionTile extends StatelessWidget {
  const _SectionTile({
    super.key,
    required this.axis,
    required this.start,
    required this.segment,
    this.onPlace,
    this.onMove,
    this.onRemove,
  });

  final CourseAxis axis;
  final int start;
  final CourseSegment segment;
  final VoidCallback? onPlace;
  final VoidCallback? onMove;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final free = segment.zoneId == null;
    final l10n = context.l10n;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(free ? Icons.remove : Icons.flag, color: free ? colors.outline : colors.primary),
      title: Text(free ? l10n.segmentFree : segment.zoneName ?? l10n.segmentZone),
      subtitle: Text([
        formatCourseRange(axis, start, start + segment.length),
        if (!free) formatSegmentBands(segment),
      ].join(' · ')),
      onTap: onMove,
      trailing: free
          ? IconButton(tooltip: l10n.coursePlaceHere, icon: const Icon(Icons.add), onPressed: onPlace)
          : IconButton(tooltip: l10n.courseRemoveZone, icon: const Icon(Icons.close), onPressed: onRemove),
    );
  }
}

/// Picks one of the stored zones and its start, and shows whether it fits.
class _PlaceZoneDialog extends ConsumerStatefulWidget {
  const _PlaceZoneDialog({
    required this.axis,
    required this.length,
    required this.others,
    this.initial,
    this.start,
  });

  final CourseAxis axis;
  final int length;

  /// The zones already placed, without the one being moved.
  final List<ZonePlacement> others;
  final ZonePlacement? initial;

  /// Where to start a new zone, e.g. at a free gap.
  final int? start;

  @override
  ConsumerState<_PlaceZoneDialog> createState() => _PlaceZoneDialogState();
}

class _PlaceZoneDialogState extends ConsumerState<_PlaceZoneDialog> {
  late int? _zoneId = widget.initial?.zoneId;
  late var _start = widget.initial?.start ?? widget.start ?? _firstFree();

  /// The end of the last placed zone, or 0.
  int _firstFree() {
    final zones = _zones;
    return widget.others.fold(0, (end, p) {
      final zone = zones[p.zoneId];
      return zone == null ? end : (p.start + zone.length > end ? p.start + zone.length : end);
    });
  }

  Map<int, Zone> get _zones => _zonesById(ref.read(zonesProvider).value);

  /// The placement and why it does not fit; null without a zone.
  (ZonePlacement?, String?) _check(Map<int, Zone> zones) {
    final zone = zones[_zoneId];
    if (zone == null) return (null, null);
    final placement = ZonePlacement(zoneId: zone.id, start: _start);
    final placements = [...widget.others, placement];
    final layout = resolveCourse(axis: widget.axis, length: widget.length, placements: placements, zones: zones);
    final error = layout.errors.where((e) => e.placements.contains(placements.length - 1)).firstOrNull;
    return (placement, error == null ? null : placementErrorText(context.l10n, error));
  }

  Future<void> _createZone() async {
    final id = await openZoneEditor(context, axis: widget.axis);
    if (id != null && mounted) setState(() => _zoneId = id);
  }

  @override
  Widget build(BuildContext context) {
    final usages = ref.watch(zonesProvider).value ?? const <ZoneUsage>[];
    final zones = _zonesById(usages);
    final (placement, error) = _check(zones);
    final zone = zones[_zoneId];
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final distance = widget.axis == CourseAxis.distance;
    final step = _startStep(widget.axis);

    return AlertDialog(
      title: Text(widget.initial == null ? l10n.coursePlaceZone : l10n.courseMoveZone),
      content: SizedBox(
        width: 480,
        child: ListView(
          shrinkWrap: true,
          children: [
            if (usages.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(l10n.courseNoZones),
              ),
            for (final u in usages)
              _ZoneOption(
                zone: u.zone,
                enabled: u.zone.axis == widget.axis,
                selected: u.zone.id == _zoneId,
                onTap: () => setState(() => _zoneId = u.zone.id),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _createZone,
                icon: const Icon(Icons.add),
                label: Text(l10n.zoneCreate),
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.courseStart(distance ? 'm' : 'm:ss'), style: AppTextStyles.caption),
            const SizedBox(height: 6),
            OarStepper(
              key: const Key('place-start'),
              value: _start,
              step: step,
              min: 0,
              // The zone has to end with the course.
              max: widget.length - (zone?.length ?? 0),
              stepLabel: distance ? '$step m' : l10n.stepSeconds(step),
              format: distance ? null : (v) => formatCourseLength(widget.axis, v),
              unit: distance ? 'm' : 'min',
              label: l10n.courseStart(distance ? 'm' : 'm:ss'),
              onChanged: (v) => setState(() => _start = v),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.courseRange(formatCourseRange(widget.axis, 0, widget.length)),
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 12),
            if (zone != null && placement != null && error == null)
              Text(
                l10n.coursePlacedAt(
                  zone.name,
                  formatCourseRange(widget.axis, placement.start, placement.start + zone.length),
                ),
                key: const Key('place-preview'),
              )
            else if (error != null)
              Text(error, key: const Key('place-error'), style: TextStyle(color: theme.colorScheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
        FilledButton(
          onPressed: placement != null && error == null ? () => Navigator.of(context).pop(placement) : null,
          child: Text(widget.initial == null ? l10n.coursePlace : l10n.courseMove),
        ),
      ],
    );
  }
}

/// A zone to choose; zones of the other axis are shown but cannot be chosen.
class _ZoneOption extends StatelessWidget {
  const _ZoneOption({required this.zone, required this.enabled, required this.selected, required this.onTap});

  final Zone zone;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('zone-option-${zone.id}'),
      enabled: enabled,
      selected: selected,
      contentPadding: EdgeInsets.zero,
      leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
      title: Text(zone.name),
      subtitle: Text(enabled ? zoneSummary(zone) : '${zoneSummary(zone)} · ${context.l10n.courseOtherAxis}'),
      onTap: enabled ? onTap : null,
    );
  }
}

/// Steps of design D7 for the length of a course: 100 m or 30 s.
int _courseStep(CourseAxis axis) => axis == CourseAxis.distance ? 100 : 30;

/// Steps of design D7 for the start of a zone: 50 m or 10 s.
int _startStep(CourseAxis axis) => axis == CourseAxis.distance ? 50 : 10;

Map<int, Zone> _zonesById(List<ZoneUsage>? usages) =>
    {for (final u in usages ?? const <ZoneUsage>[]) u.zone.id: u.zone};
