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

  Zone copyWith({int? id, String? name, CourseAxis? axis, int? length}) => Zone(
        id: id ?? this.id,
        name: name ?? this.name,
        axis: axis ?? this.axis,
        length: length ?? this.length,
        paceFastCs: paceFastCs,
        paceSlowCs: paceSlowCs,
        spmMin: spmMin,
        spmMax: spmMax,
      );

  /// The zone as a part of a course, with a copy of its bands.
  CourseSegment get segment => CourseSegment(
        length: length,
        paceFastCs: paceFastCs,
        paceSlowCs: paceSlowCs,
        spmMin: spmMin,
        spmMax: spmMax,
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
      other.spmMax == spmMax;

  @override
  bool operator ==(Object other) => other is Zone && other.id == id && sameAs(other);

  @override
  int get hashCode => Object.hash(id, name, axis, length, paceFastCs, paceSlowCs, spmMin, spmMax);

  @override
  String toString() => 'Zone($id, $name, $length ${axis.name}, pace $paceFastCs–$paceSlowCs, spm $spmMin–$spmMax)';
}

/// A stored zone with the number of courses it is placed in.
@immutable
class ZoneUsage {
  const ZoneUsage(this.zone, this.courses);

  final Zone zone;
  final int courses;
}

/// What is wrong with [zone], in words for the user; empty when it can be
/// saved.
List<String> zoneErrors(Zone zone) {
  final errors = <String>[];
  if (zone.name.trim().isEmpty) errors.add('Der Name fehlt.');
  if (zone.length <= 0) errors.add('Die Länge fehlt.');
  final paceSet = zone.paceFastCs != null || zone.paceSlowCs != null;
  final spmSet = zone.spmMin != null || zone.spmMax != null;
  if (!paceSet && !spmSet) errors.add('Es fehlt ein Band: Pace, Schlagzahl oder beides.');
  if (paceSet && (zone.paceFastCs == null || zone.paceSlowCs == null)) {
    errors.add('Für das Pace-Band fehlt eine Grenze.');
  } else if (paceSet && zone.paceFastCs! > zone.paceSlowCs!) {
    errors.add('Die schnellste Pace ist langsamer als die langsamste.');
  }
  if (spmSet && (zone.spmMin == null || zone.spmMax == null)) {
    errors.add('Für das Schlagzahl-Band fehlt eine Grenze.');
  } else if (spmSet && zone.spmMin! > zone.spmMax!) {
    errors.add('Die niedrigste Schlagzahl liegt über der höchsten.');
  }
  return errors;
}
