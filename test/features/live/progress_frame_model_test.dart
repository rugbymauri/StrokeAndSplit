import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/lap_tracker.dart';
import 'package:aergrow/features/live/progress_frame_model.dart';
import 'package:flutter_test/flutter_test.dart';

const _tempo = CourseSegment(length: 600, paceFastCs: 12500, paceSlowCs: 13000, zoneId: 1, zoneName: 'Tempo');

/// 1000 m with the zone "Tempo" from 200 to 800 m.
const _seerunde = CourseDefinition(axis: CourseAxis.distance, length: 1000, segments: [
  CourseSegment(length: 200),
  _tempo,
  CourseSegment(length: 200),
]);

/// 4:00 with a zone from 1:00 to 3:00.
const _intervals = CourseDefinition(axis: CourseAxis.time, length: 240, segments: [
  CourseSegment(length: 60),
  CourseSegment(length: 120, spmMin: 24, spmMax: 26, zoneId: 2, zoneName: 'Druck'),
  CourseSegment(length: 60),
]);

/// The state after rowing evenly at 4 m/s until [meters].
LapProgress _rowed(CourseDefinition course, num meters, {int? laps}) {
  final tracker = LapTracker(course, plannedLaps: laps);
  for (var m = 0; m <= meters; m += 4) {
    tracker.add(TrackPoint(wallMs: m * 250, distanceDm: m * 10, paceCs: 12500, strokeRate: 24));
  }
  return tracker.progress;
}

/// The state after [seconds] on a time course.
LapProgress _timed(CourseDefinition course, int seconds, {int? laps}) {
  final tracker = LapTracker(course, plannedLaps: laps);
  for (var s = 0; s <= seconds; s++) {
    tracker.add(TrackPoint(wallMs: s * 1000, distanceDm: s * 40, paceCs: 12500, strokeRate: 24));
  }
  return tracker.progress;
}

void main() {
  test('fills the tracks at 460 m in lap 2 of 3', () {
    final frame = ProgressFrameModel.of(_rowed(_seerunde, 1460, laps: 3), _seerunde);

    expect(frame.course!.share, closeTo(0.49, 0.005));
    expect(frame.lap.share, closeTo(0.46, 0.005));
    expect(frame.segment.share, closeTo(0.43, 0.005));
    expect(frame.courseDone, closeTo(1460, 0.001));
    expect(frame.courseLength, 3000);
    expect(frame.lapRemaining, closeTo(540, 0.001));
    expect(frame.segmentRemaining, closeTo(340, 0.001));
  });

  test('places notches at the lap and zone boundaries', () {
    final frame = ProgressFrameModel.of(_rowed(_seerunde, 1460, laps: 3), _seerunde);

    expect(frame.course!.boundaries, [closeTo(1 / 3, 1e-9), closeTo(2 / 3, 1e-9)]);
    expect(frame.lap.boundaries, [0.2, 0.8]);
    expect(frame.segment.boundaries, isEmpty);
  });

  test('marks the zones on the lap track only', () {
    final frame = ProgressFrameModel.of(_rowed(_seerunde, 1460, laps: 3), _seerunde);

    expect(frame.lap.zones, [(0.2, 0.8)]);
    expect(frame.course!.zones, isEmpty);
    expect(frame.segment.zones, isEmpty);
    expect(ProgressFrameModel.of(_timed(_intervals, 30), _intervals).lap.zones, [(0.25, 0.75)]);
  });

  test('counts seconds on a time course', () {
    final frame = ProgressFrameModel.of(_timed(_intervals, 330, laps: 2), _intervals);

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
    final frame = ProgressFrameModel.of(_rowed(_seerunde, 2100, laps: null), _seerunde);

    expect(frame.course, isNull);
    expect(frame.courseDone, isNull);
    expect(frame.courseLength, isNull);
    expect(frame.lap.share, closeTo(0.1, 1e-9));
    expect(frame.segment.share, closeTo(0.5, 1e-9));
    expect(frame.lapRemaining, closeTo(900, 1e-9));
    expect(frame.segmentRemaining, closeTo(100, 1e-9));
  });

  test('starts empty', () {
    final frame = ProgressFrameModel.of(_rowed(_seerunde, 0, laps: 3), _seerunde);

    expect(frame.course!.share, 0);
    expect(frame.lap.share, 0);
    expect(frame.segment.share, 0);
    expect(frame.lapRemaining, 1000);
  });
}
