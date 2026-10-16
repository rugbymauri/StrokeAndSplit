import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ble/heart_rate_transport.dart';

/// The paired heart rate strap; null when none is paired.
///
/// Keeps the strap in memory only for now; storing it across restarts
/// follows with task 4.3 of heart-rate (F17).
final chosenHeartRateMonitorProvider =
    NotifierProvider<ChosenHeartRateMonitor, FoundHeartRateMonitor?>(ChosenHeartRateMonitor.new);

class ChosenHeartRateMonitor extends Notifier<FoundHeartRateMonitor?> {
  @override
  FoundHeartRateMonitor? build() => null;

  /// Pairs [monitor], replacing a strap paired before.
  Future<void> pair(FoundHeartRateMonitor monitor) async => state = monitor;

  /// Forgets the paired strap.
  Future<void> forget() async => state = null;
}
