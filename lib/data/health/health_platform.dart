import 'dart:async';

import 'package:flutter/services.dart';

import 'health_exercise.dart';

/// Whether Health Connect can be used on the device.
enum HealthStatus { available, updateRequired, unavailable }

/// Why writing to Health Connect failed.
enum HealthFailure { permission, unavailable, failed }

class HealthException implements Exception {
  const HealthException(this.reason, [this.message]);

  final HealthFailure reason;
  final String? message;

  @override
  String toString() =>
      'HealthException(${reason.name}${message == null ? '' : ', $message'})';
}

/// Health Connect as the app uses it (Change health-connect, Design D1); a fake in tests.
abstract interface class HealthPlatform {
  Future<HealthStatus> status();

  /// The types the app may write.
  Future<Set<HealthKind>> grantedPermissions();

  /// Asks for permission to write [kinds] and gives the types the app may write afterwards.
  Future<Set<HealthKind>> requestPermissions(Set<HealthKind> kinds);

  /// Leads to the installation of Health Connect.
  Future<void> openInstall();

  /// Opens Health Connect, where the permissions and the written data are managed.
  Future<void> openSettings();

  /// Whether Health Connect opened the app for its privacy notice, at the start or later.
  Future<bool> openedForPrivacy();
  Stream<void> get privacyRequests;

  /// Writes [exercise], replacing what an earlier write of the same session left; [version] orders the writes.
  /// Throws a [HealthException].
  Future<void> write(HealthExercise exercise, {required int version});
}

/// Health Connect through the channel of the Android app.
class ChannelHealthPlatform implements HealthPlatform {
  ChannelHealthPlatform([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(name) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'launchAction' && call.arguments == 'privacy') {
        _privacy.add(null);
      }
    });
  }

  static const name = 'ch.strokesplit/health_connect';

  final MethodChannel _channel;
  final _privacy = StreamController<void>.broadcast();

  @override
  Future<HealthStatus> status() async {
    final status = await _channel.invokeMethod<String>('status');
    return HealthStatus.values.asNameMap()[status] ?? HealthStatus.unavailable;
  }

  @override
  Future<Set<HealthKind>> grantedPermissions() =>
      _kinds(() => _channel.invokeListMethod<String>('grantedPermissions'));

  @override
  Future<Set<HealthKind>> requestPermissions(Set<HealthKind> kinds) => _kinds(
    () => _channel.invokeListMethod<String>('requestPermissions', [
      for (final k in kinds) k.name,
    ]),
  );

  @override
  Future<void> openInstall() => _channel.invokeMethod<void>('openInstall');

  @override
  Future<void> openSettings() => _channel.invokeMethod<void>('openSettings');

  @override
  Future<bool> openedForPrivacy() async =>
      await _channel.invokeMethod<String>('launchAction') == 'privacy';

  @override
  Stream<void> get privacyRequests => _privacy.stream;

  @override
  Future<void> write(HealthExercise exercise, {required int version}) async {
    try {
      await _channel.invokeMethod<void>(
        'writeSession',
        exerciseToChannel(exercise, version: version),
      );
    } on PlatformException catch (e) {
      throw HealthException(
        HealthFailure.values.asNameMap()[e.code] ?? HealthFailure.failed,
        e.message,
      );
    }
  }

  Future<Set<HealthKind>> _kinds(Future<List<String>?> Function() call) async {
    try {
      final names = await call() ?? const [];
      return {for (final name in names) ?HealthKind.values.asNameMap()[name]};
    } on PlatformException catch (e) {
      throw HealthException(
        HealthFailure.values.asNameMap()[e.code] ?? HealthFailure.failed,
        e.message,
      );
    }
  }
}

/// [exercise] as the Android app reads it: times in milliseconds since the epoch.
Map<String, Object?> exerciseToChannel(
  HealthExercise exercise, {
  required int version,
}) {
  int ms(DateTime time) => time.millisecondsSinceEpoch;
  List<Map<String, Object?>> series(List<HealthSeries> parts) => [
    for (final part in parts)
      {
        'id': part.id,
        'start': ms(part.start),
        'end': ms(part.end),
        'samples': [
          for (final sample in part.samples) [ms(sample.time), sample.value],
        ],
      },
  ];
  return {
    'id': exercise.id,
    'version': version,
    'start': ms(exercise.start),
    'end': ms(exercise.end),
    'title': exercise.title,
    'meters': exercise.meters,
    'kilocalories': exercise.kilocalories,
    'heartRate': series(exercise.heartRate),
    'power': series(exercise.power),
    'speed': series(exercise.speed),
    'laps': [
      for (final lap in exercise.laps) [ms(lap.start), ms(lap.end), lap.meters],
    ],
    'segments': [
      for (final segment in exercise.segments)
        [ms(segment.start), ms(segment.end), segment.type.name],
    ],
  };
}
