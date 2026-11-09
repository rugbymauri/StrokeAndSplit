import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/platform_providers.dart';
import '../../data/sources/ble/ble_transport.dart';
import '../../data/sources/ble/heart_rate_transport.dart';
import '../../data/sources/heart_rate_choice.dart';
import '../../l10n/l10n.dart';
import 'choose_devices_screen.dart';
import 'option_card.dart';

/// The strap search of "Geräte wählen" (heart-rate, Design D8): lists the
/// heart rate straps in range, apart from the rowers. Choosing one pairs it
/// and leads back.
class HeartRateSearchScreen extends ConsumerStatefulWidget {
  const HeartRateSearchScreen({
    super.key,
    this.scanTimeout = const Duration(seconds: 15),
  });

  final Duration scanTimeout;

  @override
  ConsumerState<HeartRateSearchScreen> createState() =>
      _HeartRateSearchScreenState();
}

enum _Phase { checking, notReady, failed, scanning, done }

class _HeartRateSearchScreenState extends ConsumerState<HeartRateSearchScreen> {
  var _phase = _Phase.checking;
  var _readiness = BluetoothReadiness.ready;
  Object? _scanError;
  var _found = <FoundHeartRateMonitor>[];
  StreamSubscription<List<FoundHeartRateMonitor>>? _scan;

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
    final transport = ref.read(heartRateTransportProvider);
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
    _scan = transport
        .scanHeartRateMonitors(timeout: widget.scanTimeout)
        .listen(
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
            // Cancelling a finished scan would never complete.
            _scan = null;
            if (mounted && _phase == _Phase.scanning) {
              setState(() => _phase = _Phase.done);
            }
          },
        );
  }

  Future<void> _pair(FoundHeartRateMonitor monitor) async {
    await _scan?.cancel();
    _scan = null;
    await ref.read(chosenHeartRateMonitorProvider.notifier).pair(monitor);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final paired = ref.watch(chosenHeartRateMonitorProvider);
    final busy = _phase == _Phase.scanning || _phase == _Phase.checking;
    final message = switch (_phase) {
      _Phase.notReady when _readiness == BluetoothReadiness.off =>
        l10n.strapBluetoothOff,
      _Phase.notReady => bluetoothNotReadyText(l10n, _readiness),
      _Phase.failed => l10n.strapSearchFailed('$_scanError'),
      _Phase.done when _found.isEmpty => l10n.strapSearchNothingFound,
      _ => null,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.strapSearchTitle),
        bottom: busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePortrait),
          children: [
            SectionLabel(l10n.devicesHeartRateMonitor),
            for (final monitor in _found)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.m),
                child: OptionCard(
                  key: Key('strap-${monitor.id}'),
                  icon: Icons.favorite_border,
                  title: monitor.name,
                  subtitle: monitor == paired
                      ? '${l10n.devicesStrapPaired} · ${monitor.id.toUpperCase()}'
                      : monitor.id.toUpperCase(),
                  selected: monitor == paired,
                  onTap: () => _pair(monitor),
                ),
              ),
            if (message != null)
              ScanMessage(text: message, onRetry: _startScan),
            if (message == null && _phase == _Phase.done)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: _startScan,
                  child: Text(l10n.deviceListRetry),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
