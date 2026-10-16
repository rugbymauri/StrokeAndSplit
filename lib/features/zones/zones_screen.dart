import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/courses/course.dart';
import '../../data/zones/zone.dart';
import '../../data/zones/zone_providers.dart';
import '../../l10n/l10n.dart';
import 'zone_editor_screen.dart';
import 'zone_format.dart';

/// All zones by axis, to create, edit and delete them; [embedded] in a tab
/// it has no app bar of its own.
class ZonesScreen extends ConsumerWidget {
  const ZonesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = ref.watch(zonesProvider);
    final l10n = context.l10n;
    return Scaffold(
      appBar: embedded ? null : AppBar(title: Text(l10n.zonesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'zones',
        onPressed: () => openZoneEditor(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.zoneCreateShort),
      ),
      body: switch (zones) {
        AsyncData(value: []) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.zonesEmpty, textAlign: TextAlign.center),
            ),
          ),
        AsyncData(:final value) => ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              for (final axis in CourseAxis.values)
                if (value.any((u) => u.zone.axis == axis)) ...[
                  _AxisHeader(axis: axis),
                  for (final usage in value.where((u) => u.zone.axis == axis)) _ZoneTile(usage: usage),
                ],
            ],
          ),
        AsyncError(:final error) => Center(child: Text(l10n.zonesLoadFailed('$error'))),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Opens the editor; returns the id of a newly created zone.
Future<int?> openZoneEditor(BuildContext context, {Zone? zone, CourseAxis? axis}) {
  return Navigator.of(context)
      .push(MaterialPageRoute<int>(builder: (_) => ZoneEditorScreen(zone: zone, axis: axis)));
}

class _AxisHeader extends StatelessWidget {
  const _AxisHeader({required this.axis});

  final CourseAxis axis;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        axis == CourseAxis.distance ? context.l10n.axisDistance : context.l10n.axisTime,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _ZoneTile extends StatelessWidget {
  const _ZoneTile({required this.usage});

  final ZoneUsage usage;

  @override
  Widget build(BuildContext context) {
    final zone = usage.zone;
    return ListTile(
      leading: Icon(zone.axis == CourseAxis.distance ? Icons.straighten : Icons.timer_outlined),
      title: Text(zone.name),
      subtitle: Text(zoneSummary(zone)),
      trailing: Text(context.l10n.zoneUsage(usage.courses), key: Key('zone-usage-${zone.id}')),
      onTap: () => openZoneEditor(context, zone: zone),
    );
  }
}
