import 'package:flutter/foundation.dart' show immutable;

import '../courses/course.dart';

/// A named band over a fixed length, to be placed in courses of the same
/// axis (Change zones).
@immutable
class Zone {
  const Zone({
    this.id = 0,
    required this.name,
    required this.axis,
    required this.length,
    this.paceFastCs,
    this.paceSlowCs,
    this.spmMin,
    this.spmMax,
    this.resistanceLevel,
  });

  /// 0 for a zone that is not stored yet.
  final int id;
  final String name;
  final CourseAxis axis;

  /// In metres or seconds, depending on [axis].
  final int length;

  /// Fastest and slowest pace per 500 m, in centiseconds.
  final int? paceFastCs;
  final int? paceSlowCs;
  final int? spmMin;
  final int? spmMax;

  /// Resistance level set while rowing the zone; null for the base level
  /// (Change resistance-control). It is no band.
  final int? resistanceLevel;

  Zone copyWith({int? id, String? name, CourseAxis? axis, int? length}) => Zone(
    id: id ?? this.id,
    name: name ?? this.name,
    axis: axis ?? this.axis,
    length: length ?? this.length,
    paceFastCs: paceFastCs,
    paceSlowCs: paceSlowCs,
    spmMin: spmMin,
    spmMax: spmMax,
    resistanceLevel: resistanceLevel,
  );

  /// The zone as a part of a course, with a copy of its bands.
  CourseSegment get segment => CourseSegment(
    length: length,
    paceFastCs: paceFastCs,
    paceSlowCs: paceSlowCs,
    spmMin: spmMin,
    spmMax: spmMax,
    resistanceLevel: resistanceLevel,
    zoneId: id,
    zoneName: name,
  );

  /// Whether both describe the same zone apart from the id.
  bool sameAs(Zone other) =>
      other.name == name &&
      other.axis == axis &&
      other.length == length &&
      other.paceFastCs == paceFastCs &&
      other.paceSlowCs == paceSlowCs &&
      other.spmMin == spmMin &&
      other.spmMax == spmMax &&
      other.resistanceLevel == resistanceLevel;

  @override
  bool operator ==(Object other) =>
      other is Zone && other.id == id && sameAs(other);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    axis,
    length,
    paceFastCs,
    paceSlowCs,
    spmMin,
    spmMax,
    resistanceLevel,
  );

  @override
  String toString() =>
      'Zone($id, $name, $length ${axis.name}, pace $paceFastCs–$paceSlowCs, spm $spmMin–$spmMax, level $resistanceLevel)';
}

/// A stored zone with the number of courses it is placed in.
@immutable
class ZoneUsage {
  const ZoneUsage(this.zone, this.courses);

  final Zone zone;
  final int courses;
}

/// Why a zone cannot be saved; the screens put it into words (Design D4).
enum ZoneError {
  nameMissing,
  lengthMissing,
  bandMissing,
  paceBoundMissing,
  paceReversed,
  spmBoundMissing,
  spmReversed,
  resistanceLevelTooLow,
}

/// Thrown when a zone with [errors] is to be stored.
class ZoneValidationException implements Exception {
  const ZoneValidationException(this.errors);

  final List<ZoneError> errors;

  @override
  String toString() =>
      'ZoneValidationException(${errors.map((e) => e.name).join(', ')})';
}

/// What is wrong with [zone]; empty when it can be saved.
List<ZoneError> zoneErrors(Zone zone) {
  final errors = <ZoneError>[];
  if (zone.name.trim().isEmpty) errors.add(ZoneError.nameMissing);
  if (zone.length <= 0) errors.add(ZoneError.lengthMissing);
  final paceSet = zone.paceFastCs != null || zone.paceSlowCs != null;
  final spmSet = zone.spmMin != null || zone.spmMax != null;
  if (!paceSet && !spmSet) errors.add(ZoneError.bandMissing);
  if (paceSet && (zone.paceFastCs == null || zone.paceSlowCs == null)) {
    errors.add(ZoneError.paceBoundMissing);
  } else if (paceSet && zone.paceFastCs! > zone.paceSlowCs!) {
    errors.add(ZoneError.paceReversed);
  }
  if (spmSet && (zone.spmMin == null || zone.spmMax == null)) {
    errors.add(ZoneError.spmBoundMissing);
  } else if (spmSet && zone.spmMin! > zone.spmMax!) {
    errors.add(ZoneError.spmReversed);
  }
  if (zone.resistanceLevel case final level? when level < 1) {
    errors.add(ZoneError.resistanceLevelTooLow);
  }
  return errors;
}
