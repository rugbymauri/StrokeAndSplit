import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/lap_tracker.dart';
import 'package:strokesplit/data/courses/zone_intensity.dart';
import 'package:strokesplit/features/live/progress_frame_model.dart';
import 'package:flutter_test/flutter_test.dart';

const _tempo = CourseSegment(
  length: 600,
  paceFastCs: 12500,
  paceSlowCs: 13000,
  zoneId: 1,
  zoneName: 'Tempo',
);

/// 1000 m with the zone "Tempo" from 200 to 800 m.
const _seerunde = CourseDefinition(
  axis: CourseAxis.distance,
  length: 1000,
  segments: [CourseSegment(length: 200), _tempo, CourseSegment(length: 200)],
);

/// 4:00 with a zone from 1:00 to 3:00.
const _intervals = CourseDefinition(
  axis: CourseAxis.time,
  length: 240,
  segments: [
    CourseSegment(length: 60),
    CourseSegment(
      length: 120,
      spmMin: 24,
      spmMax: 26,
      zoneId: 2,
      zoneName: 'Druck',
    ),
    CourseSegment(length: 60),
  ],
);

/// The state after rowing evenly at 4 m/s until [meters].
LapProgress _rowed(CourseDefinition course, num meters, {int? laps}) {
  final tracker = LapTracker(course, plannedLaps: laps);
  for (var m = 0; m <= meters; m += 4) {
    tracker.add(
      TrackPoint(
        wallMs: m * 250,
        distanceDm: m * 10,
        paceCs: 12500,
        strokeRate: 24,
      ),
    );
  }
  return tracker.progress;
}

/// The state after [seconds] on a time course.
LapProgress _timed(CourseDefinition course, int seconds, {int? laps}) {
  final tracker = LapTracker(course, plannedLaps: laps);
  for (var s = 0; s <= seconds; s++) {
    tracker.add(
      TrackPoint(
        wallMs: s * 1000,
        distanceDm: s * 40,
        paceCs: 12500,
        strokeRate: 24,
      ),
    );
  }
  return tracker.progress;
}

void main() {
  test('fills the tracks at 460 m in lap 2 of 3', () {
    final frame = ProgressFrameModel.of(
      _rowed(_seerunde, 1460, laps: 3),
      _seerunde,
    );

    expect(frame.course!.share, closeTo(0.49, 0.005));
    expect(frame.lap.share, closeTo(0.46, 0.005));
    expect(frame.segment.share, closeTo(0.43, 0.005));
    expect(frame.courseDone, closeTo(1460, 0.001));
    expect(frame.courseLength, 3000);
    expect(frame.lapRemaining, closeTo(540, 0.001));
    expect(frame.segmentRemaining, closeTo(340, 0.001));
  });

  test('places notches at the lap and zone boundaries', () {
    final frame = ProgressFrameModel.of(
      _rowed(_seerunde, 1460, laps: 3),
      _seerunde,
    );

    expect(frame.course!.boundaries, [
      closeTo(1 / 3, 1e-9),
      closeTo(2 / 3, 1e-9),
    ]);
    expect(frame.lap.boundaries, [0.2, 0.8]);
    expect(frame.segment.boundaries, isEmpty);
  });

  test('marks the zones of every lap on the course and lap track', () {
    final frame = ProgressFrameModel.of(
      _rowed(_seerunde, 1460, laps: 2),
      _seerunde,
    );

    // "Tempo" 2:05–2:10 is hard.
    expect(frame.lap.zones, [(0.2, 0.8, ZoneIntensity.hard)]);
    expect(frame.course!.zones, [
      (0.1, 0.4, ZoneIntensity.hard),
      (0.6, 0.9, ZoneIntensity.hard),
    ]);
    expect(
      ProgressFrameModel.of(_timed(_intervals, 30), _intervals).lap.zones,
      [(0.25, 0.75, ZoneIntensity.hard)],
    );
  });

  test('gives each zone its own hardness', () {
    const mixed = CourseDefinition(
      axis: CourseAxis.distance,
      length: 1000,
      segments: [
        CourseSegment(length: 500, spmMin: 18, spmMax: 20, zoneName: 'Leicht'),
        CourseSegment(length: 500, resistanceLevel: 12, zoneName: 'Kraft'),
      ],
    );

    final inEasy = ProgressFrameModel.of(_rowed(mixed, 300), mixed);
    final inHard = ProgressFrameModel.of(_rowed(mixed, 700), mixed);

    expect(inEasy.lap.zones, [
      (0.0, 0.5, ZoneIntensity.easy),
      (0.5, 1.0, ZoneIntensity.hard),
    ]);
    expect(inEasy.segment.zones, [(0.0, 1.0, ZoneIntensity.easy)]);
    expect(inHard.segment.zones, [(0.0, 1.0, ZoneIntensity.hard)]);
  });

  test('has no zone on the segment track in a free segment', () {
    final frame = ProgressFrameModel.of(_rowed(_seerunde, 100), _seerunde);

    expect(frame.segment.zones, isEmpty);
  });

  test('marks a zone with only a level on the lap track', () {
    const kraft = CourseDefinition(
      axis: CourseAxis.distance,
      length: 1000,
      segments: [
        CourseSegment(length: 500),
        CourseSegment(
          length: 500,
          resistanceLevel: 12,
          zoneId: 4,
          zoneName: 'Kraft',
        ),
      ],
    );
    expect(ProgressFrameModel.of(_rowed(kraft, 100), kraft).lap.zones, [
      (0.5, 1.0, ZoneIntensity.hard),
    ]);
  });

  test('counts seconds on a time course', () {
    final frame = ProgressFrameModel.of(
      _timed(_intervals, 330, laps: 2),
      _intervals,
    );

    // 1:30 into lap 2, 0:30 into the zone from 1:00 to 3:00.
    expect(frame.course!.share, closeTo(330 / 480, 1e-9));
    expect(frame.lap.share, closeTo(90 / 240, 1e-9));
    expect(frame.segment.share, closeTo(30 / 120, 1e-9));
    expect(frame.courseDone, closeTo(330, 1e-9));
    expect(frame.courseLength, 480);
    expect(frame.lapRemaining, closeTo(150, 1e-9));
    expect(frame.segmentRemaining, closeTo(90, 1e-9));
    expect(frame.lap.boundaries, [0.25, 0.75]);
  });

  test('leaves out the course track with an open number of laps', () {
    final frame = ProgressFrameModel.of(
      _rowed(_seerunde, 2100, laps: null),
      _seerunde,
    );

    expect(frame.course, isNull);
    expect(frame.courseDone, isNull);
    expect(frame.courseLength, isNull);
    expect(frame.lap.share, closeTo(0.1, 1e-9));
    expect(frame.segment.share, closeTo(0.5, 1e-9));
    expect(frame.lapRemaining, closeTo(900, 1e-9));
    expect(frame.segmentRemaining, closeTo(100, 1e-9));
  });

  test('leaves out the course track with a single lap', () {
    final frame = ProgressFrameModel.of(
      _rowed(_seerunde, 460, laps: 1),
      _seerunde,
    );

    expect(frame.course, isNull);
    expect((frame.courseDone, frame.courseLength), (null, null));
    expect(frame.lap.share, closeTo(0.46, 0.005));
    expect(frame.lap.boundaries, [0.2, 0.8]);
    expect(frame.lapRemaining, closeTo(540, 0.001));
    expect(frame.segmentRemaining, closeTo(340, 0.001));
  });

  test('keeps the course track with two laps', () {
    final frame = ProgressFrameModel.of(
      _rowed(_seerunde, 460, laps: 2),
      _seerunde,
    );

    expect(frame.course!.share, closeTo(0.23, 0.005));
    expect(frame.course!.boundaries, [0.5]);
  });

  group('with a time limit', () {
    test('fills the outer track by the rowing time, without notches', () {
      // In lap 3 of an open number of laps, after 15 of 30 minutes.
      final frame = ProgressFrameModel.of(
        _rowed(_seerunde, 2460),
        _seerunde,
        rowed: const Duration(minutes: 15),
        limit: const Duration(minutes: 30),
      );

      expect(frame.course!.share, 0.5);
      expect(frame.course!.boundaries, isEmpty);
      expect(frame.course!.zones, isEmpty);
      expect(frame.timeRemaining, const Duration(minutes: 15));
      expect((frame.courseDone, frame.courseLength), (null, null));
      expect(frame.lap.share, closeTo(0.46, 0.005));
      expect(frame.lapRemaining, closeTo(540, 0.001));
    });

    test('is full and has no time left once the limit is reached', () {
      final frame = ProgressFrameModel.of(
        _timed(_intervals, 30),
        _intervals,
        rowed: const Duration(minutes: 30, milliseconds: 600),
        limit: const Duration(minutes: 30),
      );

      expect(frame.course!.share, 1);
      expect(frame.timeRemaining, Duration.zero);
    });

    test('leaves the outer track to the laps without a limit', () {
      final frame = ProgressFrameModel.of(
        _rowed(_seerunde, 1460, laps: 3),
        _seerunde,
        rowed: const Duration(minutes: 6),
      );

      expect(frame.course!.share, closeTo(0.49, 0.005));
      expect(frame.timeRemaining, isNull);
    });
  });

  test('starts empty', () {
    final frame = ProgressFrameModel.of(
      _rowed(_seerunde, 0, laps: 3),
      _seerunde,
    );

    expect(frame.course!.share, 0);
    expect(frame.lap.share, 0);
    expect(frame.segment.share, 0);
    expect(frame.lapRemaining, 1000);
  });
}
