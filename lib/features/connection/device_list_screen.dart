import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/platform_providers.dart';
import '../../data/sources/ble/ble_transport.dart';
import '../../data/sources/ble/ble_rower_source.dart';
import '../../data/sources/erg_source_providers.dart';
import '../../data/templates/session_template.dart';
import '../live/live_screen.dart';

/// Scans for PM5s in range and connects to the one the user picks.
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
    } on RowerConnectException {
      await notifier.clear();
      if (!mounted) return;
      setState(() => _phase = _Phase.done);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Verbindung fehlgeschlagen'),
          content: Text('AergRow konnte sich nicht mit ${device.name} verbinden.\n\n'
              'Ein PM5 erlaubt nur eine Bluetooth-Verbindung gleichzeitig. Trenne andere Apps wie '
              'ErgData und versuche es erneut.'),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
        ),
      );
      return;
    }
    if (!mounted) return;
    await Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => LiveScreen(template: widget.template)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PM5 suchen'),
        bottom: _phase == _Phase.scanning || _phase == _Phase.connecting || _phase == _Phase.checking
            ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator())
            : null,
      ),
      body: switch (_phase) {
        _Phase.notReady => _Message(text: _notReadyText(_readiness), onRetry: _startScan),
        _Phase.failed => _Message(text: 'Die Suche nach dem PM5 ist fehlgeschlagen.\n\n$_scanError', onRetry: _startScan),
        _Phase.done when _found.isEmpty => _Message(text: _nothingFoundText, onRetry: _startScan),
        _Phase.connecting => const Center(child: Text('Verbinde …')),
        _ => ListView(
            children: [
              for (final device in _found)
                ListTile(
                  leading: const Icon(Icons.rowing),
                  title: Text(device.name),
                  subtitle: Text(device.id),
                  onTap: () => _connect(device),
                ),
              if (_phase == _Phase.done)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton(onPressed: _startScan, child: const Text('Erneut suchen')),
                ),
            ],
          ),
      },
    );
  }

  static String _notReadyText(BluetoothReadiness readiness) => switch (readiness) {
        BluetoothReadiness.off => 'Bluetooth ist ausgeschaltet. Schalte Bluetooth ein, um nach deinem PM5 zu suchen.',
        BluetoothReadiness.unauthorized => 'AergRow darf Bluetooth nicht verwenden. Die Berechtigung ist nötig, '
            'um sich mit deinem PM5 zu verbinden. Erteile sie in den Systemeinstellungen unter '
            'Apps → AergRow → Berechtigungen.',
        BluetoothReadiness.unsupported => 'Dieses Gerät unterstützt kein Bluetooth LE.',
        BluetoothReadiness.ready => '',
      };

  static const _nothingFoundText = 'Kein PM5 gefunden.\n\n'
      '• Wecke den PM5 auf: Drück eine Taste, bis das Hauptmenü erscheint.\n'
      '• Trenne andere Apps wie ErgData, der PM5 erlaubt nur eine Verbindung.\n'
      '• Geh näher an den PM5.';
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
            FilledButton(onPressed: onRetry, child: const Text('Erneut suchen')),
          ],
        ),
      ),
    );
  }
}
