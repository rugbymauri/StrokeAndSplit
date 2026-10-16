import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/platform_providers.dart';
import '../../data/sources/ble/ble_transport.dart';
import '../../data/sources/rower_choice.dart';
import '../../l10n/l10n.dart';
import 'choose_devices_screen.dart';
import 'rower_connection.dart';
import 'start_screen.dart';

/// The first screen: skips "Geräte wählen" when the rower chosen last is a
/// simulator or is found and connected within [searchTimeout] (Design D6).
class LaunchScreen extends ConsumerStatefulWidget {
  const LaunchScreen({super.key, this.searchTimeout = const Duration(seconds: 10)});

  final Duration searchTimeout;

  @override
  ConsumerState<LaunchScreen> createState() => _LaunchScreenState();
}

enum _Outcome { searching, start, choose }

class _LaunchScreenState extends ConsumerState<LaunchScreen> {
  late final RowerChoice? _choice = ref.read(chosenRowerProvider);
  late var _outcome = switch (_choice) {
    null => _Outcome.choose,
    RowerChoice(isSimulator: true) => _Outcome.start,
    _ => _Outcome.searching,
  };
  StreamSubscription<List<FoundRower>>? _scan;
  final _found = Completer<FoundRower?>();

  @override
  void initState() {
    super.initState();
    if (_outcome == _Outcome.searching) _search();
  }

  @override
  void dispose() {
    _scan?.cancel();
    super.dispose();
  }

  Future<void> _search() async {
    final wanted = _choice!.device!;
    final transport = ref.read(bleTransportProvider);
    final ready = await transport.readiness() == BluetoothReadiness.ready;
    if (!ready || _found.isCompleted) return _finish(_Outcome.choose);
    _scan = transport.scan(timeout: widget.searchTimeout).listen(
      (rowers) {
        final match = rowers.where((r) => r == wanted).firstOrNull;
        if (match != null) _settle(match);
      },
      onError: (Object _) => _settle(null),
      onDone: () {
        // Cancelling a finished scan would never complete.
        _scan = null;
        _settle(null);
      },
    );
    final rower = await _found.future;
    await _scan?.cancel();
    if (rower == null || !mounted) return _finish(_Outcome.choose);
    try {
      await connectRower(ref, RowerChoice.device(rower));
    } on RowerConnectException {
      return _finish(_Outcome.choose);
    }
    _finish(_Outcome.start);
  }

  /// Ends the search with [rower], or with null when it was not found.
  void _settle(FoundRower? rower) {
    if (!_found.isCompleted) _found.complete(rower);
  }

  void _finish(_Outcome outcome) {
    if (mounted && _outcome == _Outcome.searching) setState(() => _outcome = outcome);
  }

  @override
  Widget build(BuildContext context) => switch (_outcome) {
        _Outcome.start => const StartScreen(),
        _Outcome.choose => const ChooseDevicesScreen(),
        _Outcome.searching => _Searching(
            name: _choice!.device!.name,
            onChoose: () => _settle(null),
          ),
      };
}

class _Searching extends StatelessWidget {
  const _Searching({required this.name, required this.onChoose});

  final String name;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePortrait),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.xxl),
              Text(l10n.launchSearching(name), style: AppTextStyles.body, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.l),
              TextButton(onPressed: onChoose, child: Text(l10n.devicesTitle)),
            ],
          ),
        ),
      ),
    );
  }
}
