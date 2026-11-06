import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/platform_providers.dart';
import '../../data/sources/ble/ble_transport.dart';
import '../../data/sources/erg_source.dart';
import '../../data/sources/erg_source_providers.dart';
import '../../data/sources/rower_choice.dart';
import '../../data/templates/session_template.dart';
import '../../l10n/l10n.dart';
import '../live/live_screen.dart';
import 'choose_devices_screen.dart';
import 'connect_error_text.dart';

/// Makes the rower of [choice] the active source, unless it already is.
///
/// Throws [RowerConnectException] when the rower cannot be connected; there
/// is no active source then.
Future<void> connectRower(WidgetRef ref, RowerChoice choice) async {
  final active = ref.read(activeErgSourceProvider);
  if (choice.isUsedBy(active) && active!.connectionState != ErgConnectionState.disconnected) return;
  final notifier = ref.read(activeErgSourceProvider.notifier);
  try {
    await notifier.use(choice.createSource(ref.read(bleTransportProvider)));
  } on RowerConnectException {
    await notifier.clear();
    rethrow;
  }
}

/// Rows with the chosen rower, freely or [template] (Design D6). Without a
/// chosen rower it opens "Geräte wählen" instead. Without [ghost] no ghost
/// runs in the session of [template] (template-screen, Design D4).
Future<void> startRowing(BuildContext context, WidgetRef ref, {SessionTemplate? template, bool ghost = true}) async {
  final navigator = Navigator.of(context);
  final choice = ref.read(chosenRowerProvider);
  if (choice == null) {
    await navigator.push(MaterialPageRoute<void>(builder: (_) => const ChooseDevicesScreen()));
    return;
  }
  try {
    await connectRower(ref, choice);
  } on RowerConnectException catch (e) {
    if (context.mounted) await showConnectError(context, choice.device?.name ?? '', e);
    return;
  }
  await navigator.push(MaterialPageRoute<void>(builder: (_) => LiveScreen(template: template, ghost: ghost)));
}

/// Explains why the rower [deviceName] could not be connected.
Future<void> showConnectError(BuildContext context, String deviceName, RowerConnectException error) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final l10n = context.l10n;
      final notARower = notARowerText(l10n, error.error);
      return AlertDialog(
        title: Text(notARower == null ? l10n.connectFailedTitle : l10n.connectNotARowerTitle),
        content: Text(notARower == null
            ? l10n.connectFailedBody(l10n.appTitle, deviceName)
            : '$notARower\n\n${l10n.connectNotARowerHint(l10n.appTitle)}'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.actionOk))],
      );
    },
  );
}
