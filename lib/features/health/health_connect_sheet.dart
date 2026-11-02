import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/health/health_export.dart';
import '../../data/health/health_platform.dart';
import '../../data/health/health_workout.dart';
import '../../l10n/l10n.dart';
import 'health_privacy_screen.dart';

/// Opens the settings of the Health Connect export (Change health-connect, Design D5).
Future<void> showHealthConnectSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const HealthConnectSheet(),
    );

/// The switch of the export, whether Health Connect is there and allows writing, and the ways to it.
class HealthConnectSheet extends ConsumerStatefulWidget {
  const HealthConnectSheet({super.key});

  @override
  ConsumerState<HealthConnectSheet> createState() => _HealthConnectSheetState();
}

class _HealthConnectSheetState extends ConsumerState<HealthConnectSheet> {
  /// Whether the user just refused the permission, so the sheet says why the switch stays off.
  var _denied = false;

  Future<void> _switch(bool on) async {
    final enabled = ref.read(healthExportEnabledProvider.notifier);
    if (!on) return enabled.set(false);
    final result = await enabled.enable();
    ref.invalidate(healthConnectStateProvider);
    if (mounted) setState(() => _denied = result == HealthEnableResult.denied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = ref.watch(healthExportEnabledProvider);
    final health = ref.watch(healthConnectStateProvider).value;
    final platform = ref.read(healthPlatformProvider);
    final status = health?.status;
    final mayWrite = health?.granted.contains(HealthKind.exercise) ?? false;

    Widget notice(IconData icon, String text, {String? action, VoidCallback? onAction, Key? key}) => ListTile(
          key: key,
          leading: Icon(icon),
          title: Text(text),
          subtitle: action == null
              ? null
              : Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(onPressed: onAction, child: Text(action)),
                ),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n.healthConnectTooltip, style: Theme.of(context).textTheme.titleLarge),
            ),
            Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: Text(l10n.healthConnectIntro)),
            SwitchListTile(
              key: const Key('health-connect-switch'),
              title: Text(l10n.healthConnectSwitch),
              value: enabled,
              onChanged: health == null ? null : _switch,
            ),
            if (status == HealthStatus.unavailable)
              notice(Icons.error_outline, l10n.healthConnectMissing,
                  key: const Key('health-connect-missing'),
                  action: l10n.healthConnectInstall,
                  onAction: platform.openInstall)
            else if (status == HealthStatus.updateRequired)
              notice(Icons.error_outline, l10n.healthConnectOutdated,
                  key: const Key('health-connect-outdated'),
                  action: l10n.healthConnectUpdate,
                  onAction: platform.openInstall)
            else if (status == HealthStatus.available && (_denied || enabled) && !mayWrite)
              notice(Icons.lock_outline, l10n.healthConnectPermissionMissing,
                  key: const Key('health-connect-permission'),
                  action: l10n.healthConnectGrant,
                  onAction: () => _switch(true))
            else if (status == HealthStatus.available && enabled)
              notice(Icons.check_circle_outline, l10n.healthConnectActive, key: const Key('health-connect-active')),
            if (status == HealthStatus.available)
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: Text(l10n.healthConnectOpen),
                subtitle: Text(l10n.healthConnectOpenHint),
                onTap: platform.openSettings,
              ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l10n.healthPrivacyTitle),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => const HealthPrivacyScreen())),
            ),
          ],
        ),
      ),
    );
  }
}
