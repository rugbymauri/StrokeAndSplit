import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../data/statistics/ranking_providers.dart';
import '../../data/zones/zone.dart';
import '../../data/zones/zone_providers.dart';
import '../../l10n/l10n.dart';
import '../statistics/ranking_sections.dart';
import 'zone_format.dart';
import 'zones_screen.dart';

Future<void> openZoneDetail(BuildContext context, Zone zone) {
  return Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ZoneDetailScreen(zoneId: zone.id)));
}

/// A zone with places 1–3 per length and the way to edit it (Change
/// statistics, Design D6). Deleting the zone in the editor closes it too.
class ZoneDetailScreen extends ConsumerWidget {
  const ZoneDetailScreen({super.key, required this.zoneId});

  final int zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.listen(zonesProvider, (_, next) {
      if (next case AsyncData(:final value) when !value.any((u) => u.zone.id == zoneId)) {
        final route = ModalRoute.of(context);
        if (route != null && route.isActive) Navigator.of(context).removeRoute(route);
      }
    });
    final zone = ref.watch(zonesProvider).value?.map((u) => u.zone).where((z) => z.id == zoneId).firstOrNull;
    final rankings = ref.watch(zoneRankingsProvider(zoneId));
    return Scaffold(
      appBar: AppBar(
        title: Text(zone?.name ?? ''),
        actions: [
          if (zone != null)
            IconButton(
              key: const Key('zone-edit'),
              tooltip: l10n.actionEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => openZoneEditor(context, zone: zone),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: zone == null
                ? const SizedBox.shrink()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePortrait,
                      AppSpacing.l,
                      AppSpacing.pagePortrait,
                      AppSpacing.xxl,
                    ),
                    children: [
                      Text(zoneSummary(context.l10n, zone), style: AppTextStyles.subtitle),
                      const SizedBox(height: AppSpacing.xxl),
                      switch (rankings) {
                        AsyncData(:final value) =>
                          RankingSections(rankings: value, axis: zone.axis, length: zone.length),
                        AsyncError(:final error) => Text(l10n.rankingLoadFailed('$error')),
                        _ => const Center(child: CircularProgressIndicator()),
                      },
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
