import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_language.dart';
import '../../l10n/app_localizations.dart';
import '../sessions/session_providers.dart';
import '../sources/erg_source.dart';
import 'health_platform.dart';
import 'health_workout.dart';

/// Where the choice to write sessions to Health Connect is kept (Change health-connect, Design D5).
abstract interface class HealthExportStore {
  bool read();

  Future<void> write(bool enabled);
}

/// Keeps the choice in the shared preferences of the platform.
class PreferencesHealthExportStore implements HealthExportStore {
  PreferencesHealthExportStore._(this._preferences);

  static const _key = 'healthConnect';

  final SharedPreferencesWithCache _preferences;

  static Future<PreferencesHealthExportStore> open() async {
    const options = SharedPreferencesWithCacheOptions(allowList: {_key});
    return PreferencesHealthExportStore._(
      await SharedPreferencesWithCache.create(cacheOptions: options),
    );
  }

  @override
  bool read() => _preferences.getBool(_key) ?? false;

  @override
  Future<void> write(bool enabled) => _preferences.setBool(_key, enabled);
}

/// Keeps the choice in memory only; used in tests and until `main` has opened the preferences.
class MemoryHealthExportStore implements HealthExportStore {
  MemoryHealthExportStore([this._enabled = false]);

  bool _enabled;

  @override
  bool read() => _enabled;

  @override
  Future<void> write(bool enabled) async => _enabled = enabled;
}

/// Where the choice is kept; `main` sets the preferences.
final healthExportStoreProvider = Provider<HealthExportStore>(
  (ref) => MemoryHealthExportStore(),
);

/// Health Connect; replaced by a fake in tests.
final healthPlatformProvider = Provider<HealthPlatform>(
  (ref) => ChannelHealthPlatform(),
);

/// Whether the platform has Health Connect, which is only Android.
final healthExportAvailableProvider = Provider<bool>(
  (ref) => !kIsWeb && Platform.isAndroid,
);

/// Whether finished sessions are written to Health Connect.
final healthExportEnabledProvider = NotifierProvider<HealthExportEnabled, bool>(
  HealthExportEnabled.new,
);

class HealthExportEnabled extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(healthExportAvailableProvider) &&
      ref.watch(healthExportStoreProvider).read();

  Future<void> set(bool enabled) async {
    state = enabled;
    await ref.read(healthExportStoreProvider).write(enabled);
  }

  /// Asks for the permissions and switches the export on once the app may write workouts.
  Future<HealthEnableResult> enable() async {
    final platform = ref.read(healthPlatformProvider);
    try {
      switch (await platform.status()) {
        case HealthStatus.unavailable:
          return HealthEnableResult.unavailable;
        case HealthStatus.updateRequired:
          return HealthEnableResult.updateRequired;
        case HealthStatus.available:
          final granted = await platform.requestPermissions(
            HealthKind.values.toSet(),
          );
          if (!granted.contains(HealthKind.exercise)) {
            return HealthEnableResult.denied;
          }
      }
    } on HealthException catch (e) {
      return e.reason == HealthFailure.unavailable
          ? HealthEnableResult.unavailable
          : HealthEnableResult.denied;
    }
    await set(true);
    return HealthEnableResult.enabled;
  }
}

enum HealthEnableResult { enabled, denied, unavailable, updateRequired }

/// Whether Health Connect is there and what the app may write to it.
typedef HealthConnectState = ({HealthStatus status, Set<HealthKind> granted});

final healthConnectStateProvider =
    FutureProvider.autoDispose<HealthConnectState>((ref) async {
      final platform = ref.watch(healthPlatformProvider);
      final status = await platform.status();
      if (status != HealthStatus.available) {
        return (status: status, granted: const <HealthKind>{});
      }
      try {
        return (status: status, granted: await platform.grantedPermissions());
      } on HealthException {
        return (status: status, granted: const <HealthKind>{});
      }
    });

/// Whether sessions from [source] go to Health Connect: rowing on a rower, not the simulator or a replay.
bool healthExportable(ErgSourceKind source) =>
    source == ErgSourceKind.pm5 || source == ErgSourceKind.ftms;

/// A write after a session ended that failed, until the user has seen it.
typedef HealthExportFailure = ({int sessionId, HealthFailure reason});

final healthExportFailureProvider =
    NotifierProvider<HealthExportFailures, HealthExportFailure?>(
      HealthExportFailures.new,
    );

class HealthExportFailures extends Notifier<HealthExportFailure?> {
  @override
  HealthExportFailure? build() => null;

  void report(int sessionId, HealthFailure reason) =>
      state = (sessionId: sessionId, reason: reason);

  void clear() => state = null;
}

final healthExporterProvider = Provider<HealthExporter>(HealthExporter.new);

/// Writes stored sessions to Health Connect and keeps their status (Design D4).
class HealthExporter {
  HealthExporter(this._ref);

  final Ref _ref;

  /// Writes session [id], replacing an earlier write of it; null when it worked, otherwise why not.
  Future<HealthFailure?> export(int id) async {
    final repository = _ref.read(sessionRepositoryProvider);
    final data = await repository.healthData(id);
    if (data == null) return HealthFailure.failed;
    final texts = lookupAppLocalizations(_ref.read(appLanguageProvider).locale);
    final workout = healthWorkoutOf(data, freeTitle: texts.healthFreeTitle);
    try {
      await _ref
          .read(healthPlatformProvider)
          .write(workout, version: clock.now().millisecondsSinceEpoch);
    } on Object catch (e) {
      await repository.clearHealthExported(id);
      return e is HealthException ? e.reason : HealthFailure.failed;
    }
    await repository.markHealthExported(id, clock.now());
    return null;
  }

  /// Writes session [id] after it ended, when the export is on and it was rowed on a rower; a failure is
  /// reported through [healthExportFailureProvider].
  Future<void> sessionFinished(int id) async {
    if (!_ref.read(healthExportEnabledProvider)) return;
    final session = await _ref.read(sessionRepositoryProvider).get(id);
    if (session == null || !healthExportable(session.source)) return;
    final failure = await export(id);
    if (failure != null) {
      _ref.read(healthExportFailureProvider.notifier).report(id, failure);
    }
  }
}
