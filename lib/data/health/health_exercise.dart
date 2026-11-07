import 'dart:math' as math;

/// The data types the app writes to Health Connect, by the names the platform channel uses.
enum HealthKind { exercise, distance, calories, heartRate, power, speed }

/// One stored measurement as the export needs it (Change health-connect, Design D3).
class HealthPoint {
  const HealthPoint({
    required this.wallMs,
    this.heartRate,
    this.watts,
    this.paceCs,
    this.calories,
  });

  /// Wall-clock time since the session started, pauses included.
  final int wallMs;
  final int? heartRate;
  final int? watts;
  final int? paceCs;
  final int? calories;
}

/// A lap on the session time, the wall clock without the pauses.
typedef HealthLapInput = ({int startMs, int endMs, int distanceDm});

/// A pause on the wall clock of the samples.
typedef HealthPauseInput = ({int startWallMs, int endWallMs});

/// What is stored of a session that the export needs.
class HealthSessionData {
  const HealthSessionData({
    required this.startedAt,
    required this.endedAt,
    required this.distanceDm,
    required this.templateName,
    this.courseName,
    this.points = const [],
    this.laps = const [],
    this.pauses = const [],
  });

  final DateTime startedAt;
  final DateTime? endedAt;
  final int distanceDm;

  /// Null for free rowing and for a course rowed without a template.
  final String? templateName;

  /// The course of a session without a template, its title then (course-rowing-free, Design D7);
  /// null for free rowing.
  final String? courseName;
  final List<HealthPoint> points;
  final List<HealthLapInput> laps;
  final List<HealthPauseInput> pauses;
}

class HealthSample {
  const HealthSample(this.time, this.value);

  final DateTime time;
  final double value;
}

/// One series record: a part of a series of at most [HealthExercise.seriesPart].
class HealthSeries {
  const HealthSeries({required this.id, required this.samples});

  final String id;
  final List<HealthSample> samples;

  DateTime get start => samples.first.time;

  /// A second after the last sample, as a series must end after its start.
  DateTime get end => samples.last.time.add(const Duration(seconds: 1));
}

class HealthLap {
  const HealthLap({
    required this.start,
    required this.end,
    required this.meters,
  });

  final DateTime start;
  final DateTime end;
  final double meters;
}

enum HealthSegmentType { rowing, pause }

class HealthSegment {
  const HealthSegment({
    required this.start,
    required this.end,
    required this.type,
  });

  final DateTime start;
  final DateTime end;
  final HealthSegmentType type;
}

/// A session as a Health Connect exercise of the type rowing machine, with its series, laps and pauses.
class HealthExercise {
  const HealthExercise({
    required this.id,
    required this.start,
    required this.end,
    required this.title,
    required this.meters,
    this.kilocalories,
    this.heartRate = const [],
    this.power = const [],
    this.speed = const [],
    this.laps = const [],
    this.segments = const [],
  });

  /// The longest part of a series in one record, well below the limits of Health Connect.
  static const seriesPart = Duration(minutes: 10);

  /// The base of every client record id, from the start of the session, so it stays the same on another
  /// device after an export and import (Design D2).
  final String id;
  final DateTime start;
  final DateTime end;
  final String title;
  final double meters;

  /// The calories of the rower; null when it reported none.
  final double? kilocalories;
  final List<HealthSeries> heartRate;
  final List<HealthSeries> power;
  final List<HealthSeries> speed;
  final List<HealthLap> laps;

  /// Rowing between the pauses and the pauses; empty without pauses.
  final List<HealthSegment> segments;
}

/// The exercise of [data] (Design D3); [freeTitle] names a session without a template.
HealthExercise healthExerciseOf(
  HealthSessionData data, {
  required String freeTitle,
}) {
  final startedAt = data.startedAt.toUtc();
  final id = 'strokesplit-${startedAt.millisecondsSinceEpoch}';
  DateTime at(int ms) => startedAt.add(Duration(milliseconds: ms));
  final points = data.points;
  var end =
      data.endedAt?.toUtc() ??
      (points.isEmpty ? startedAt : at(points.last.wallMs));
  if (!end.isAfter(startedAt)) end = startedAt.add(const Duration(seconds: 1));
  final endMs = end.difference(startedAt).inMilliseconds;
  final inSession = [
    for (final p in points)
      if (p.wallMs >= 0 && p.wallMs <= endMs) p,
  ];

  List<HealthSeries> series(String kind, double? Function(HealthPoint) value) {
    // The last value of each second, as rowers report several a second.
    final perSecond = <int, (int, double)>{};
    for (final p in inSession) {
      final v = value(p);
      if (v != null) perSecond[p.wallMs ~/ 1000] = (p.wallMs, v);
    }
    final parts = <int, List<HealthSample>>{};
    for (final (ms, v) in perSecond.values) {
      parts
          .putIfAbsent(ms ~/ HealthExercise.seriesPart.inMilliseconds, () => [])
          .add(HealthSample(at(ms), v));
    }
    return [
      for (final MapEntry(key: part, value: samples) in parts.entries)
        HealthSeries(id: '$id-$kind-$part', samples: samples),
    ];
  }

  final pauses = [
    for (final p in [
      ...data.pauses,
    ]..sort((a, b) => a.startWallMs.compareTo(b.startWallMs)))
      if (p.startWallMs < endMs && p.endWallMs > p.startWallMs)
        (start: p.startWallMs, end: math.min(p.endWallMs, endMs)),
  ];

  /// A session time on the wall clock: each pause before it moves it by its length. A start in the same
  /// moment as a pause begins after the pause, an end before it.
  int wall(int sessionMs, {required bool start}) {
    var ms = sessionMs;
    for (final p in pauses) {
      if (start ? ms >= p.start : ms > p.start) ms += p.end - p.start;
    }
    return ms;
  }

  final laps = <HealthLap>[];
  for (final lap in data.laps) {
    final from = wall(lap.startMs, start: true);
    final to = math.min(wall(lap.endMs, start: false), endMs);
    final meters = (lap.endMs > lap.startMs ? lap.distanceDm : 0) / 10;
    if (to > from && (laps.isEmpty || !laps.last.end.isAfter(at(from)))) {
      laps.add(
        HealthLap(
          start: at(from),
          end: at(to),
          meters: meters.clamp(0, 1000000).toDouble(),
        ),
      );
    }
  }

  final segments = <HealthSegment>[];
  var cursor = 0;
  for (final p in pauses) {
    if (p.start < cursor) continue;
    if (p.start > cursor) {
      segments.add(
        HealthSegment(
          start: at(cursor),
          end: at(p.start),
          type: HealthSegmentType.rowing,
        ),
      );
    }
    segments.add(
      HealthSegment(
        start: at(p.start),
        end: at(p.end),
        type: HealthSegmentType.pause,
      ),
    );
    cursor = p.end;
  }
  if (segments.isNotEmpty && cursor < endMs) {
    segments.add(
      HealthSegment(
        start: at(cursor),
        end: end,
        type: HealthSegmentType.rowing,
      ),
    );
  }

  final calories = inSession.map((p) => p.calories ?? 0).fold(0, math.max);
  return HealthExercise(
    id: id,
    start: startedAt,
    end: end,
    title: data.templateName ?? data.courseName ?? freeTitle,
    meters: data.distanceDm / 10,
    kilocalories: calories > 0 ? calories.toDouble() : null,
    heartRate: series(
      'heartRate',
      (p) => switch (p.heartRate) {
        final bpm? when bpm >= 1 && bpm <= 300 => bpm.toDouble(),
        _ => null,
      },
    ),
    power: series(
      'power',
      (p) => switch (p.watts) {
        final watts? when watts >= 0 => watts.toDouble(),
        _ => null,
      },
    ),
    // 500 m in the pace.
    speed: series(
      'speed',
      (p) => switch (p.paceCs) {
        final cs? when cs > 0 => 50000 / cs,
        _ => null,
      },
    ),
    laps: laps,
    segments: segments,
  );
}
