import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../data/courses/course.dart';
import '../../data/zones/zone.dart';
import '../../data/zones/zone_providers.dart';
import '../../l10n/l10n.dart';
import '../connection/option_card.dart';
import '../courses/course_strip.dart';
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
      body: SafeArea(
        top: !embedded,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePortrait,
                AppSpacing.l,
                AppSpacing.pagePortrait,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: switch (zones) {
                      AsyncData(value: []) => Center(
                          child: Text(l10n.zonesEmpty, textAlign: TextAlign.center, style: AppTextStyles.subtitle),
                        ),
                      AsyncData(:final value) => ListView(
                          children: [
                            for (final axis in CourseAxis.values)
                              if (value.where((u) => u.zone.axis == axis).toList() case final usages
                                  when usages.isNotEmpty) ...[
                                SectionLabel(axis == CourseAxis.distance ? l10n.axisDistance : l10n.axisTime),
                                _ZoneList(usages: usages),
                                const SizedBox(height: AppSpacing.l),
                              ],
                          ],
                        ),
                      AsyncError(:final error) => Center(child: Text(l10n.zonesLoadFailed('$error'))),
                      _ => const Center(child: CircularProgressIndicator()),
                    },
                  ),
                  const SizedBox(height: AppSpacing.l),
                  OutlinedButton.icon(
                    key: const Key('zone-create'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: () => openZoneEditor(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.zoneCreateShort),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the editor; returns the id of a newly created zone.
Future<int?> openZoneEditor(BuildContext context, {Zone? zone, CourseAxis? axis}) {
  return Navigator.of(context)
      .push(MaterialPageRoute<int>(builder: (_) => ZoneEditorScreen(zone: zone, axis: axis)));
}

/// The zones of one axis on a card, divided by lines, each with a swatch in
/// the shade it has in a course bar (design D4).
class _ZoneList extends StatelessWidget {
  const _ZoneList({required this.usages});

  final List<ZoneUsage> usages;

  @override
  Widget build(BuildContext context) {
    final colors = CourseStrip.segmentColors([for (final u in usages) u.zone.segment]);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.cardLarge),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, usage) in usages.indexed) ...[
            if (i > 0) const Divider(height: 1),
            _ZoneTile(usage: usage, color: colors[i]),
          ],
        ],
      ),
    );
  }
}

class _ZoneTile extends StatelessWidget {
  const _ZoneTile({required this.usage, required this.color});

  final ZoneUsage usage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final zone = usage.zone;
    return ListTile(
      minLeadingWidth: 10,
      leading: Container(
        width: 10,
        height: 30,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      ),
      title: Text(zone.name, style: AppTextStyles.cardTitle.copyWith(fontSize: 16)),
      subtitle: Text(zoneSummary(zone), style: AppTextStyles.caption),
      trailing: Text(
        context.l10n.zoneUsage(usage.courses),
        key: Key('zone-usage-${zone.id}'),
        style: AppTextStyles.caption,
      ),
      onTap: () => openZoneEditor(context, zone: zone),
    );
  }
}
