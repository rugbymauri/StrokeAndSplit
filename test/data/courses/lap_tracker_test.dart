import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/lap_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

const _band = CourseSegment(length: 600, paceFastCs: 12500, paceSlowCs: 13000, spmMin: 20, spmMax: 22);

final _thousand = CourseDefinition.single(axis: CourseAxis.distance, length: 1000);

const _seerunde = CourseDefinition(axis: CourseAxis.distance, length: 1000, segments: [
  CourseSegment(length: 200),
  _band,
  CourseSegment(length: 200),
]);

/// A point at [seconds] wall-clock time and [meters].
TrackPoint _at(num seconds, num meters, {int? pace = 12700, int? spm = 21}) =>
    TrackPoint(wallMs: (seconds * 1000).round(), distanceDm: (meters * 10).round(), paceCs: pace, strokeRate: spm);

/// Rows evenly at 4 m/s from [from] to [to] seconds, starting at [meters].
Iterable<TrackPoint> _row(int from, int to, {num meters = 0, int? pace = 12700, int? spm = 21}) sync* {
  for (var s = from; s <= to; s++) {
    yield _at(s, meters + (s - from) * 4, pace: pace, spm: spm);
  }
}

void main() {
  group('laps', () {
    test('places the end of a lap between two measurements', () {
      final tracker = LapTracker(_thousand)
        ..add(_at(0, 0))
        ..add(_at(239, 998))
        ..add(_at(240, 1003));

      final lap = tracker.takeLaps().single;
      expect(lap.endWallMs, 239400);
      expect(lap.endDistanceDm, 10000);
      expect(lap.complete, isTrue);
      expect(tracker.progress.lap, 2);
      expect(tracker.progress.remaining, closeTo(997, 0.001));
      // The lap time counts from the boundary at 239.4 s.
      expect(tracker.progress.lapTime, const Duration(milliseconds: 600));
    });

    test('gives what goes beyond a lap to the next one', () {
      final tracker = LapTracker(_thousand)
        ..add(_at(0, 0))
        ..add(_at(239, 998))
        ..add(_at(240, 1003))
        ..add(_at(479, 1999))
        ..add(_at(480, 2001));

      final laps = tracker.takeLaps();
      expect([for (final l in laps) (l.startWallMs, l.endWallMs, l.startDistanceDm, l.endDistanceDm)], [
        (0, 239400, 0, 10000),
        (239400, 479500, 10000, 20000),
      ]);
    });

    test('follows on with laps until stopped when the number is open', () {
      final tracker = LapTracker(CourseDefinition.single(axis: CourseAxis.distance, length: 100));
      _row(0, 300).forEach(tracker.add);

      expect(tracker.takeLaps(), hasLength(12));
      expect(tracker.finished, isFalse);
      expect(tracker.progress.lap, 13);
    });

    test('places several boundaries between two measurements one by one', () {
      final tracker = LapTracker(CourseDefinition.single(axis: CourseAxis.distance, length: 100))
        ..add(_at(0, 0))
        ..add(_at(70, 350));

      expect([for (final l in tracker.takeLaps()) l.endWallMs], [20000, 40000, 60000]);
      expect(tracker.progress.lap, 4);
      expect(tracker.progress.remaining, closeTo(50, 0.001));
    });

    test('is finished after the last of a fixed number of laps', () {
      final tracker = LapTracker(CourseDefinition.single(axis: CourseAxis.distance, length: 100), plannedLaps: 3);
      _row(0, 100).forEach(tracker.add);

      expect([for (final l in tracker.takeLaps()) l.lap], [1, 2, 3]);
      expect(tracker.finished, isTrue);
      tracker.finish();
      expect(tracker.takeLaps(), isEmpty);
    });

    test('a pause counts in the time of a distance lap', () {
      // 1000 m in 4:00 rowing time with a pause of 30 s after 500 m.
      final tracker = LapTracker(_thousand)
        ..add(_at(0, 0))
        ..add(_at(120, 500))
        ..add(_at(150, 500, pace: null, spm: 0))
        ..add(_at(270, 1000));

      expect(tracker.takeLaps().single.durationMs, 270000);
    });

    test('a time lap ends after its wall-clock time and counts only the rowed metres', () {
      final tracker = LapTracker(CourseDefinition.single(axis: CourseAxis.time, length: 240));
      _row(0, 210).forEach(tracker.add);
      tracker
        ..add(_at(225, 840, pace: null, spm: 0))
        ..add(_at(241, 840, pace: null, spm: 0));

      final lap = tracker.takeLaps().single;
      expect(lap.endWallMs, 240000);
      expect(lap.distanceDm, 8400);
    });

    test('a time course measures the segment rest in seconds', () {
      final tracker = LapTracker(CourseDefinition.single(axis: CourseAxis.time, length: 240));
      _row(0, 100).forEach(tracker.add);

      expect(tracker.progress.remaining, closeTo(140, 0.001));
    });
  });

  group('segments', () {
    test('shows lap, segment and what is left of it', () {
      final tracker = LapTracker(_seerunde, plannedLaps: 3)
        ..add(_at(0, 0))
        ..add(_at(400, 1520));

      final progress = tracker.progress;
      expect(progress.lap, 2);
      expect(progress.plannedLaps, 3);
      expect(progress.segmentIndex, 1);
      expect((progress.segmentStart, progress.segmentEnd), (200, 800));
      expect(progress.remaining, closeTo(280, 0.001));
      expect(progress.segment, _band);
    });

    test('stores time and distance per segment', () {
      final tracker = LapTracker(_seerunde);
      _row(0, 250).forEach(tracker.add);

      final segments = tracker.takeSegments();
      expect([for (final s in segments) (s.lap, s.position, s.durationMs, s.distanceDm)], [
        (1, 0, 50000, 2000),
        (1, 1, 150000, 6000),
        (1, 2, 50000, 2000),
      ]);
    });
  });

  group('zone', () {
    const minute = CourseDefinition(axis: CourseAxis.time, length: 60, segments: [
      CourseSegment(length: 60, paceFastCs: 12500, paceSlowCs: 13000, spmMin: 20, spmMax: 22),
    ]);

    test('tells whether pace and stroke rate are in the band', () {
      final tracker = LapTracker(_seerunde)
        ..add(_at(0, 0))
        ..add(_at(100, 300, pace: 12750, spm: 21));

      expect((tracker.progress.pace, tracker.progress.strokeRate), (BandStatus.inBand, BandStatus.inBand));
    });

    test('tells in which direction a value is off', () {
      final tracker = LapTracker(_seerunde)
        ..add(_at(0, 0))
        ..add(_at(100, 300, pace: 13300, spm: 24));
      expect((tracker.progress.pace, tracker.progress.strokeRate), (BandStatus.above, BandStatus.above));

      tracker.add(_at(101, 304, pace: 12000, spm: 18));
      expect((tracker.progress.pace, tracker.progress.strokeRate), (BandStatus.below, BandStatus.below));

      tracker.add(_at(102, 304, pace: null, spm: 0));
      expect((tracker.progress.pace, tracker.progress.strokeRate), (BandStatus.missing, BandStatus.missing));
    });

    test('a free segment has no zone', () {
      final tracker = LapTracker(_seerunde)..add(_at(10, 40));

      expect((tracker.progress.pace, tracker.progress.strokeRate), (BandStatus.none, BandStatus.none));
      expect(tracker.progress.lapInZoneShare, isNull);
    });

    test('measures the share of time in the zone, weighted by time', () {
      final tracker = LapTracker(minute);
      // Each interval counts with the state of its earlier point.
      _row(0, 44).forEach(tracker.add);
      _row(45, 61, meters: 180, pace: 13500).forEach(tracker.add);

      expect(tracker.takeSegments().single.inZoneShare, closeTo(0.75, 0.001));
      expect(tracker.takeLaps().single.inZoneShare, closeTo(0.75, 0.001));
    });

    test('a pause counts as outside the zone', () {
      final tracker = LapTracker(minute);
      _row(0, 29).forEach(tracker.add);
      for (var t = 30; t < 40; t++) {
        tracker.add(_at(t, 116, pace: null, spm: 0));
      }
      _row(40, 61, meters: 116).forEach(tracker.add);

      expect(tracker.takeSegments().single.inZoneShare, closeTo(50 / 60, 0.001));
    });

    test('splits an interval at a segment boundary', () {
      const course = CourseDefinition(axis: CourseAxis.time, length: 20, segments: [
        CourseSegment(length: 10, paceFastCs: 12500, paceSlowCs: 13000),
        CourseSegment(length: 10, paceFastCs: 11000, paceSlowCs: 11500),
      ]);
      final tracker = LapTracker(course)
        ..add(_at(0, 0))
        ..add(_at(20, 80));

      final segments = tracker.takeSegments();
      expect([for (final s in segments) s.durationMs], [10000, 10000]);
      expect([for (final s in segments) s.inZoneShare], [1.0, 0.0]);
      expect(tracker.takeLaps().single.inZoneShare, closeTo(0.5, 0.001));
    });

    test('the lap share counts only segments with a band', () {
      final tracker = LapTracker(_seerunde);
      _row(0, 250).forEach(tracker.add);

      expect([for (final s in tracker.takeSegments()) s.inZoneShare], [null, 1.0, null]);
      expect(tracker.takeLaps().single.inZoneShare, 1.0);
    });

    test('shows the running share of the current lap', () {
      final tracker = LapTracker(minute);
      _row(0, 15).forEach(tracker.add);
      _row(16, 30, meters: 60, pace: 13500).forEach(tracker.add);

      expect(tracker.progress.lapInZoneShare, closeTo(16 / 30, 0.001));
    });
  });

  group('wall-clock times for the ghost', () {
    test('the course time runs on over a lap change, the lap time starts anew', () {
      final tracker = LapTracker(_thousand, plannedLaps: 3)
        ..add(_at(0, 0))
        ..add(_at(239, 998))
        ..add(_at(240, 1003));

      final progress = tracker.progress;
      expect(progress.courseTime, const Duration(seconds: 240));
      expect(progress.lapTime, const Duration(milliseconds: 600));
      expect(progress.courseDistanceDm, 10030);
    });

    test('the segment time starts anew at a segment boundary', () {
      // The band of the Seerunde starts at 200 m, reached after 50 s.
      final tracker = LapTracker(_seerunde, plannedLaps: 3);
      _row(0, 60).forEach(tracker.add);

      final progress = tracker.progress;
      expect(progress.segmentIndex, 1);
      expect(progress.segmentTime, const Duration(seconds: 10));
      expect(progress.lapTime, const Duration(seconds: 60));
      expect(progress.courseTime, const Duration(seconds: 60));
    });

    test('the segment time starts anew with the first segment of the next lap', () {
      final tracker = LapTracker(_seerunde, plannedLaps: 3);
      _row(0, 260).forEach(tracker.add);

      final progress = tracker.progress;
      expect((progress.lap, progress.segmentIndex), (2, 0));
      expect(progress.segmentTime, const Duration(seconds: 10));
      expect(progress.courseTime, const Duration(seconds: 260));
    });

    test('all times run on during a pause while the distance stands', () {
      final tracker = LapTracker(_seerunde, plannedLaps: 3)
        ..add(_at(0, 0))
        ..add(_at(100, 400))
        ..add(_at(130, 400, pace: null, spm: 0));

      final progress = tracker.progress;
      expect(progress.courseTime, const Duration(seconds: 130));
      expect(progress.lapTime, const Duration(seconds: 130));
      expect(progress.segmentTime, const Duration(seconds: 80));
      expect(progress.courseDistanceDm, 4000);
    });

    test('count from where a tracker for a later lap starts', () {
      final tracker = LapTracker(_thousand, plannedLaps: 3, startLap: 3, startWallMs: 500000, startDistanceDm: 20000)
        ..add(_at(560, 2240));

      expect(tracker.progress.courseTime, const Duration(seconds: 60));
      expect(tracker.progress.courseDistanceDm, 2400);
    });
  });

  group('an unfinished lap', () {
    test('is stored as incomplete with what was rowed', () {
      final tracker = LapTracker(_thousand, plannedLaps: 3);
      _row(0, 350).forEach(tracker.add);
      tracker.finish();

      final laps = tracker.takeLaps();
      expect([for (final l in laps) (l.lap, l.complete, l.distanceDm)], [(1, true, 10000), (2, false, 4000)]);
      expect(tracker.takeSegments().last.distanceDm, 4000);
    });

    test('is not stored when the session ends right at a lap boundary', () {
      final tracker = LapTracker(_thousand);
      _row(0, 250).forEach(tracker.add);
      tracker.finish();

      expect([for (final l in tracker.takeLaps()) l.complete], [true]);
    });

    test('is finished from a later lap on, as after a crash', () {
      final tracker = LapTracker(_thousand, plannedLaps: 3, startLap: 3, startWallMs: 500000, startDistanceDm: 20000)
        ..add(_at(500, 2000))
        ..add(_at(560, 2240))
        ..finish();

      final lap = tracker.takeLaps().single;
      expect((lap.lap, lap.complete, lap.startWallMs, lap.distanceDm), (3, false, 500000, 2400));
    });
  });
}
