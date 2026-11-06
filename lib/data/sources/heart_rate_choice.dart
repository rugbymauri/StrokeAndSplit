import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ble/heart_rate_transport.dart';

/// The paired strap as stored; null when there is none or it cannot be read.
FoundHeartRateMonitor? decodeHeartRateMonitor(String? value) {
  if (value == null) return null;
  try {
    final map = jsonDecode(value) as Map<String, Object?>;
    return FoundHeartRateMonitor(
      id: map['id']! as String,
      name: map['name']! as String,
    );
  } on Object {
    return null;
  }
}

String encodeHeartRateMonitor(FoundHeartRateMonitor monitor) =>
    jsonEncode({'id': monitor.id, 'name': monitor.name});

/// Where the paired heart rate strap is kept (heart-rate, Design D6).
abstract interface class HeartRateMonitorStore {
  String? read();

  Future<void> write(String value);

  Future<void> clear();
}

/// Keeps the paired strap in the shared preferences of the platform.
class PreferencesHeartRateMonitorStore implements HeartRateMonitorStore {
  PreferencesHeartRateMonitorStore._(this._preferences);

  static const _key = 'heartRateMonitor';

  final SharedPreferencesWithCache _preferences;

  static Future<PreferencesHeartRateMonitorStore> open() async {
    const options = SharedPreferencesWithCacheOptions(allowList: {_key});
    return PreferencesHeartRateMonitorStore._(
      await SharedPreferencesWithCache.create(cacheOptions: options),
    );
  }

  @override
  String? read() => _preferences.getString(_key);

  @override
  Future<void> write(String value) => _preferences.setString(_key, value);

  @override
  Future<void> clear() => _preferences.remove(_key);
}

/// Keeps the paired strap in memory only; used in tests and until `main` has
/// opened the preferences.
class MemoryHeartRateMonitorStore implements HeartRateMonitorStore {
  MemoryHeartRateMonitorStore([FoundHeartRateMonitor? monitor])
    : _value = monitor == null ? null : encodeHeartRateMonitor(monitor);

  String? _value;

  @override
  String? read() => _value;

  @override
  Future<void> write(String value) async => _value = value;

  @override
  Future<void> clear() async => _value = null;
}

/// Where the paired strap is kept; `main` sets the preferences.
final heartRateMonitorStoreProvider = Provider<HeartRateMonitorStore>(
  (ref) => MemoryHeartRateMonitorStore(),
);

/// The paired heart rate strap, also across restarts; null when none is paired.
final chosenHeartRateMonitorProvider =
    NotifierProvider<ChosenHeartRateMonitor, FoundHeartRateMonitor?>(
      ChosenHeartRateMonitor.new,
    );

class ChosenHeartRateMonitor extends Notifier<FoundHeartRateMonitor?> {
  @override
  FoundHeartRateMonitor? build() =>
      decodeHeartRateMonitor(ref.watch(heartRateMonitorStoreProvider).read());

  /// Pairs [monitor], replacing a strap paired before, and remembers it.
  Future<void> pair(FoundHeartRateMonitor monitor) async {
    state = monitor;
    await ref
        .read(heartRateMonitorStoreProvider)
        .write(encodeHeartRateMonitor(monitor));
  }

  /// Forgets the paired strap.
  Future<void> forget() async {
    state = null;
    await ref.read(heartRateMonitorStoreProvider).clear();
  }
}
