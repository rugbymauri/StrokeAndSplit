import 'dart:async';

import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/platform_providers.dart';
import '../../data/sources/ble/ble_transport.dart';
import '../../data/sources/ble/ble_rower_source.dart';
import '../../data/sources/erg_source_providers.dart';
import '../../data/templates/session_template.dart';
import '../../l10n/l10n.dart';
import '../live/live_screen.dart';
import 'connect_error_text.dart';

/// Scans for rowers in range and connects to the one the user picks.
class DeviceListScreen extends ConsumerStatefulWidget {
  const DeviceListScreen({super.key, this.scanTimeout = const Duration(seconds: 15), this.template});

  final Duration scanTimeout;

  /// Started in the live display once connected.
  final SessionTemplate? template;

  @override
  ConsumerState<DeviceListScreen> createState() => _DeviceListScreenState();
}

enum _Phase { checking, notReady, failed, scanning, done, connecting }

class _DeviceListScreenState extends ConsumerState<DeviceListScreen> {
  var _phase = _Phase.checking;
  var _readiness = BluetoothReadiness.ready;
  Object? _scanError;
  var _found = <FoundRower>[];
  StreamSubscription<List<FoundRower>>? _scan;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _scan?.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    final transport = ref.read(bleTransportProvider);
    setState(() {
      _phase = _Phase.checking;
      _found = [];
    });
    final readiness = await transport.readiness();
    if (!mounted) return;
    if (readiness != BluetoothReadiness.ready) {
      setState(() {
        _readiness = readiness;
        _phase = _Phase.notReady;
      });
      return;
    }
    setState(() => _phase = _Phase.scanning);
    await _scan?.cancel();
    _scan = transport.scan(timeout: widget.scanTimeout).listen(
          (found) => setState(() => _found = found),
          onError: (Object error) => setState(() {
            if (error is BluetoothNotReadyException) {
              _readiness = error.readiness;
              _phase = _Phase.notReady;
            } else {
              _scanError = error;
              _phase = _Phase.failed;
            }
          }),
          onDone: () {
            if (mounted && _phase == _Phase.scanning) setState(() => _phase = _Phase.done);
          },
        );
  }

  Future<void> _connect(FoundRower device) async {
    await _scan?.cancel();
    setState(() => _phase = _Phase.connecting);
    final notifier = ref.read(activeErgSourceProvider.notifier);
    try {
      await notifier.use(BleRowerSource(transport: ref.read(bleTransportProvider), device: device));
    } on RowerConnectException catch (e) {
      await notifier.clear();
      if (!mounted) return;
      setState(() => _phase = _Phase.done);
      await showDialog<void>(
        context: context,
        builder: (context) {
          final l10n = context.l10n;
          final notARower = notARowerText(l10n, e.error);
          return AlertDialog(
            title: Text(notARower == null ? l10n.connectFailedTitle : l10n.connectNotARowerTitle),
            content: Text(notARower == null
                ? l10n.connectFailedBody(l10n.appTitle, device.name)
                : '$notARower\n\n${l10n.connectNotARowerHint(l10n.appTitle)}'),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.actionOk))],
          );
        },
      );
      return;
    }
    if (!mounted) return;
    await Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => LiveScreen(template: widget.template)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deviceListTitle),
        bottom: _phase == _Phase.scanning || _phase == _Phase.connecting || _phase == _Phase.checking
            ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator())
            : null,
      ),
      body: switch (_phase) {
        _Phase.notReady => _Message(text: _notReadyText(l10n, _readiness), onRetry: _startScan),
        _Phase.failed => _Message(text: l10n.deviceListScanFailed('$_scanError'), onRetry: _startScan),
        _Phase.done when _found.isEmpty => _Message(text: l10n.deviceListNothingFound, onRetry: _startScan),
        _Phase.connecting => Center(child: Text(l10n.stateConnecting)),
        _ => ListView(
            children: [
              for (final device in _found)
                ListTile(
                  leading: const Icon(Icons.rowing),
                  title: Text(device.name),
                  subtitle: Text('${_kind(device.protocol)} · ${device.id}'),
                  onTap: () => _connect(device),
                ),
              if (_phase == _Phase.done)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton(onPressed: _startScan, child: Text(l10n.deviceListRetry)),
                ),
            ],
          ),
      },
    );
  }

  static String _notReadyText(AppLocalizations l10n, BluetoothReadiness readiness) => switch (readiness) {
        BluetoothReadiness.off => l10n.bluetoothOff,
        BluetoothReadiness.unauthorized => l10n.bluetoothUnauthorized(l10n.appTitle),
        BluetoothReadiness.unsupported => l10n.bluetoothUnsupported,
        BluetoothReadiness.ready => '',
      };

  static String _kind(ErgProtocol protocol) => switch (protocol) {
        ErgProtocol.pm5 => 'Concept2 PM5',
        ErgProtocol.ftms => 'FTMS',
      };

}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: Text(context.l10n.deviceListRetry)),
          ],
        ),
      ),
    );
  }
}
