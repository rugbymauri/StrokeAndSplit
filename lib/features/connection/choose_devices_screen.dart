import 'dart:async';

import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/platform_providers.dart';
import '../../app/widgets/language_button.dart';
import '../../data/sources/ble/ble_transport.dart';
import '../../data/sources/erg_source_providers.dart';
import '../../data/sources/rower_choice.dart';
import '../../l10n/l10n.dart';
import 'option_card.dart';
import 'rower_connection.dart';
import 'start_screen.dart';

/// "Geräte wählen": the rower from the rowers in range or a simulator
/// (Design D6). "Weiter" connects it and leads to the start screen.
class ChooseDevicesScreen extends ConsumerStatefulWidget {
  const ChooseDevicesScreen({super.key, this.scanTimeout = const Duration(seconds: 15)});

  final Duration scanTimeout;

  @override
  ConsumerState<ChooseDevicesScreen> createState() => _ChooseDevicesScreenState();
}

enum _Phase { checking, notReady, failed, scanning, done }

class _ChooseDevicesScreenState extends ConsumerState<ChooseDevicesScreen> {
  var _phase = _Phase.checking;
  var _readiness = BluetoothReadiness.ready;
  Object? _scanError;
  var _found = <FoundRower>[];
  StreamSubscription<List<FoundRower>>? _scan;

  /// Starts with the rower chosen last, also when it is not in range.
  late RowerChoice? _selected = ref.read(chosenRowerProvider);
  var _connecting = false;

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
            // Cancelling a finished scan would never complete.
            _scan = null;
            if (mounted && _phase == _Phase.scanning) setState(() => _phase = _Phase.done);
          },
        );
  }

  Future<void> _continue(RowerChoice choice) async {
    setState(() => _connecting = true);
    if (_phase == _Phase.scanning) {
      await _scan?.cancel();
      _phase = _Phase.done;
    }
    try {
      if (choice.isSimulator) {
        // The simulator starts with rowing; a rower connected so far is let go.
        if (!choice.isUsedBy(ref.read(activeErgSourceProvider))) {
          await ref.read(activeErgSourceProvider.notifier).clear();
        }
      } else {
        await connectRower(ref, choice);
      }
    } on RowerConnectException catch (e) {
      if (!mounted) return;
      setState(() => _connecting = false);
      await showConnectError(context, choice.device!.name, e);
      return;
    }
    await ref.read(chosenRowerProvider.notifier).choose(choice);
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      await navigator.pushReplacement(MaterialPageRoute<void>(builder: (_) => const StartScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = _selected;
    final busy = _connecting || _phase == _Phase.scanning || _phase == _Phase.checking;
    final missing = selected?.device;
    final message = switch (_phase) {
      _Phase.notReady => _notReadyText(l10n, _readiness),
      _Phase.failed => l10n.deviceListScanFailed('$_scanError'),
      _Phase.done when _found.isEmpty => l10n.deviceListNothingFound,
      _ => null,
    };

    Widget option(RowerChoice choice, IconData icon, String title, String subtitle, {Key? key}) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.m),
          child: OptionCard(
            key: key,
            icon: icon,
            title: title,
            subtitle: subtitle,
            selected: choice == selected,
            onTap: _connecting ? null : () => setState(() => _selected = choice),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.devicesTitle),
        actions: const [LanguageButton()],
        bottom: busy ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator()) : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.pagePortrait),
                children: [
                  SectionLabel(l10n.devicesRower),
                  for (final device in _found)
                    option(
                      RowerChoice.device(device),
                      Icons.rowing,
                      device.name,
                      '${_kind(device.protocol)} · ${device.id}',
                      key: Key('rower-${device.id}'),
                    ),
                  if (missing != null && !_found.contains(missing))
                    option(
                      selected!,
                      Icons.rowing,
                      missing.name,
                      _phase == _Phase.scanning || _phase == _Phase.checking
                          ? '${_kind(missing.protocol)} · ${l10n.stateScanning}'
                          : '${_kind(missing.protocol)} · ${l10n.devicesNotFound}',
                      key: Key('rower-${missing.id}'),
                    ),
                  if (message != null) _Message(text: message, onRetry: _connecting ? null : _startScan),
                  if (message == null && _phase == _Phase.done)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.m),
                      child: OutlinedButton(
                        onPressed: _connecting ? null : _startScan,
                        child: Text(l10n.deviceListRetry),
                      ),
                    ),
                  option(
                    const RowerChoice.simulator(),
                    Icons.smart_toy_outlined,
                    l10n.sourceSimulatorName,
                    l10n.startSimulatorHint,
                    key: const Key('rower-simulator'),
                  ),
                  option(
                    const RowerChoice.simulator(ErgProtocol.ftms),
                    Icons.smart_toy_outlined,
                    l10n.sourceSimulatorFtmsName,
                    l10n.startSimulatorFtmsHint,
                    key: const Key('rower-simulator-ftms'),
                  ),
                  // The heart rate strap gets its section here with the change heart-rate (Design D6).
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePortrait,
                AppSpacing.s,
                AppSpacing.pagePortrait,
                AppSpacing.pagePortrait,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: selected == null || _connecting ? null : () => _continue(selected),
                  child: Text(_connecting ? l10n.stateConnecting : l10n.devicesNext),
                ),
              ),
            ),
          ],
        ),
      ),
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
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.m),
          OutlinedButton(onPressed: onRetry, child: Text(context.l10n.deviceListRetry)),
        ],
      ),
    );
  }
}
