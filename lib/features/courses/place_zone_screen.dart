import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/oar_stepper.dart';
import '../../data/courses/course.dart';
import '../../data/courses/course_layout.dart';
import '../../data/courses/zone_intensity.dart';
import '../../data/zones/zone.dart';
import '../../data/zones/zone_providers.dart';
import '../../l10n/l10n.dart';
import '../connection/option_card.dart';
import '../zones/zone_format.dart';
import '../zones/zones_screen.dart';
import 'course_strip.dart';
import 'placement_error_text.dart';

/// Opens [PlaceZoneScreen] and returns the placement of the chosen zone, or
/// null when the user goes back.
Future<ZonePlacement?> openPlaceZone(
  BuildContext context, {
  required CourseAxis axis,
  required int length,
  required List<ZonePlacement> placements,
  int start = 0,
}) => Navigator.of(context).push(
  MaterialPageRoute<ZonePlacement>(
    builder: (_) => PlaceZoneScreen(
      axis: axis,
      length: length,
      placements: placements,
      start: start,
    ),
  ),
);

/// Places a zone in a course (Change course-editor-flow, D1): the start first,
/// then the zones of the course's axis grouped by intensity; a zone that does
/// not fit at the start is dimmed with the reason, a tap on one that fits
/// places it.
class PlaceZoneScreen extends ConsumerStatefulWidget {
  const PlaceZoneScreen({
    super.key,
    required this.axis,
    required this.length,
    required this.placements,
    this.start = 0,
  });

  final CourseAxis axis;
  final int length;

  /// The zones already placed.
  final List<ZonePlacement> placements;

  /// The start to begin with, e.g. the start of a free gap.
  final int start;

  @override
  ConsumerState<PlaceZoneScreen> createState() => _PlaceZoneScreenState();
}

class _PlaceZoneScreenState extends ConsumerState<PlaceZoneScreen> {
  late var _start = widget.start;

  int get _step => placeZoneStep(widget.axis);

  /// Why [zone] does not fit at the start, or null when it does.
  String? _misfit(Zone zone, Map<int, Zone> zones) {
    final placements = [
      ...widget.placements,
      ZonePlacement(zoneId: zone.id, start: _start),
    ];
    final layout = resolveCourse(
      axis: widget.axis,
      length: widget.length,
      placements: placements,
      zones: {...zones, zone.id: zone},
    );
    final error = layout.errors
        .where((e) => e.placements.contains(placements.length - 1))
        .firstOrNull;
    return error == null ? null : placementErrorText(context.l10n, error);
  }

  void _place(Zone zone) =>
      Navigator.of(context).pop(ZonePlacement(zoneId: zone.id, start: _start));

  /// Creates a zone and places it right away when it fits (D2).
  Future<void> _createZone() async {
    final id = await openZoneEditor(context, axis: widget.axis);
    if (id == null || !mounted) return;
    final zone = await ref.read(zoneRepositoryProvider).get(id);
    if (zone == null || !mounted) return;
    final zones = _zonesById(ref.read(zonesProvider).value);
    if (_misfit(zone, zones) == null) _place(zone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final usages = ref.watch(zonesProvider).value ?? const <ZoneUsage>[];
    final zones = _zonesById(usages);
    final candidates = [
      for (final u in usages)
        if (u.zone.axis == widget.axis) u.zone,
    ]..sort((a, b) => a.name.compareTo(b.name));
    final distance = widget.axis == CourseAxis.distance;
    final layout = resolveCourse(
      axis: widget.axis,
      length: widget.length,
      placements: widget.placements,
      zones: zones,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.coursePlaceZone)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePortrait,
              AppSpacing.l,
              AppSpacing.pagePortrait,
              AppSpacing.xxl,
            ),
            children: [
              SectionLabel(l10n.courseStart(distance ? 'm' : 'm:ss')),
              OarStepper(
                key: const Key('place-start'),
                value: _start,
                step: _step,
                min: 0,
                max: widget.length - _step,
                stepLabel: distance ? '$_step m' : l10n.stepSeconds(_step),
                format: distance
                    ? null
                    : (v) => formatCourseLength(widget.axis, v),
                unit: distance ? 'm' : 'min',
                label: l10n.courseStart(distance ? 'm' : 'm:ss'),
                onChanged: (v) => setState(() => _start = v),
              ),
              if (layout.definition case final definition?) ...[
                const SizedBox(height: AppSpacing.m),
                _Preview(definition: definition, share: _start / widget.length),
              ],
              const SizedBox(height: AppSpacing.xxl),
              if (candidates.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.l),
                  child: Text(l10n.courseNoZones, style: AppTextStyles.caption),
                ),
              for (final intensity in ZoneIntensity.values)
                if ([
                      for (final z in candidates)
                        if (zoneIntensity(z.segment) == intensity) z,
                    ]
                    case final group when group.isNotEmpty) ...[
                  SectionLabel(_groupName(l10n, intensity)),
                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.cardLarge),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final (i, zone) in group.indexed) ...[
                          if (i > 0) const Divider(height: 1),
                          _ZoneOption(
                            zone: zone,
                            misfit: _misfit(zone, zones),
                            onTap: () => _place(zone),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                ],
              OutlinedButton.icon(
                key: const Key('place-create-zone'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _createZone,
                icon: const Icon(Icons.add),
                label: Text(l10n.zoneCreate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _groupName(AppLocalizations l10n, ZoneIntensity intensity) =>
    switch (intensity) {
      ZoneIntensity.easy => l10n.placeZoneGroupEasy,
      ZoneIntensity.medium => l10n.placeZoneGroupMedium,
      ZoneIntensity.hard => l10n.placeZoneGroupHard,
    };

/// The course as it is, with a mark at the start.
class _Preview extends StatelessWidget {
  const _Preview({required this.definition, required this.share});

  final CourseDefinition definition;

  /// The start as a share of the course length.
  final double share;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CourseStrip.namedHeight,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Positioned.fill(
              child: CourseStrip(
                definition: definition,
                height: CourseStrip.namedHeight,
              ),
            ),
            Positioned(
              key: const Key('place-mark'),
              left: (constraints.maxWidth * share - 1.5).clamp(
                0,
                constraints.maxWidth - 3,
              ),
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: AppColors.text),
            ),
          ],
        ),
      ),
    );
  }
}

/// A zone to place; dimmed with the reason when it does not fit.
class _ZoneOption extends StatelessWidget {
  const _ZoneOption({
    required this.zone,
    required this.misfit,
    required this.onTap,
  });

  final Zone zone;

  /// Why the zone does not fit at the start, or null.
  final String? misfit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fits = misfit == null;
    return ListTile(
      key: Key('zone-option-${zone.id}'),
      enabled: fits,
      minLeadingWidth: 10,
      leading: Opacity(
        opacity: fits ? 1 : 0.4,
        child: Container(
          width: 10,
          height: 30,
          decoration: BoxDecoration(
            color: CourseStrip.segmentColors([zone.segment]).single,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
      title: Text(
        zone.name,
        style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
      ),
      subtitle: Text(
        misfit ?? zoneSummary(context.l10n, zone),
        style: AppTextStyles.caption,
      ),
      onTap: fits ? onTap : null,
    );
  }
}

/// Steps of design D7 for the start of a zone: 50 m or 10 s.
int placeZoneStep(CourseAxis axis) => axis == CourseAxis.distance ? 50 : 10;

Map<int, Zone> _zonesById(List<ZoneUsage>? usages) => {
  for (final u in usages ?? const <ZoneUsage>[]) u.zone.id: u.zone,
};
