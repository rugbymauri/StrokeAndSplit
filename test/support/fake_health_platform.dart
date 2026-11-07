import 'dart:async';

import 'package:strokesplit/data/health/health_platform.dart';
import 'package:strokesplit/data/health/health_exercise.dart';

/// Health Connect in memory: it keeps one exercise per id, as the app replaces an earlier write.
class FakeHealthPlatform implements HealthPlatform {
  FakeHealthPlatform({
    this.health = HealthStatus.available,
    Set<HealthKind>? granted,
    Set<HealthKind>? grants,
  }) : granted = granted ?? {},
       grants = grants ?? HealthKind.values.toSet();

  HealthStatus health;

  /// What the app may write now.
  Set<HealthKind> granted;

  /// What the user grants when asked.
  Set<HealthKind> grants;

  /// Fails the next writes with this reason.
  HealthFailure? failure;

  final exercises = <String, HealthExercise>{};
  var writes = 0;
  var installs = 0;
  var settings = 0;
  bool privacy = false;
  final _privacy = StreamController<void>.broadcast();

  void requestPrivacy() => _privacy.add(null);

  @override
  Future<HealthStatus> status() async => health;

  @override
  Future<Set<HealthKind>> grantedPermissions() async => {...granted};

  @override
  Future<Set<HealthKind>> requestPermissions(Set<HealthKind> kinds) async {
    granted = {...granted, ...kinds.intersection(grants)};
    return {...granted};
  }

  @override
  Future<void> openInstall() async => installs++;

  @override
  Future<void> openSettings() async => settings++;

  @override
  Future<bool> openedForPrivacy() async => privacy;

  @override
  Stream<void> get privacyRequests => _privacy.stream;

  @override
  Future<void> write(HealthExercise exercise, {required int version}) async {
    writes++;
    if (failure case final failure?) throw HealthException(failure);
    if (!granted.contains(HealthKind.exercise)) {
      throw const HealthException(HealthFailure.permission);
    }
    exercises[exercise.id] = exercise;
  }
}
