import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/lap_tracker.dart';
import 'package:aergrow/data/ghost/ghost.dart';
import 'package:aergrow/data/ghost/ghost_progress.dart';
import 'package:flutter_test/flutter_test.dart';

final _seerunde = CourseDefinition.single(axis: CourseAxis.distance, length: 1000);

const _zoned = CourseDefinition(axis: CourseAxis.distance, length: 1000, segments: [
  CourseSegment(length: 200),
  CourseSegment(length: 600, zoneId: 1, paceFastCs: 12500, paceSlowCs: 13000),
  CourseSegment(length: 200),
]);

/// A ghost through the points of [seconds] and [metres].
GhostTrack _ghost(List<(num, num)> points) => GhostTrack([
      for (final (seconds, metres) in points)
        GhostPoint(wallMs: (seconds * 1000).round(), distanceDm: (metres * 10).round()),
    ]);

/// The rower at [inLap] metres or seconds of lap [lap] of [definition], with
/// the given wall-clock times in seconds and the distance in metres since the
/// start.
LapProgress _at(
  CourseDefinition definition, {
  int lap = 1,
  int? plannedLaps = 3,
  required num inLap,
  num lapSeconds = 0,
  num courseSeconds = 0,
  num segmentSeconds = 0,
  num courseMetres = 0,
}) {
  final index = definition.segmentEnds.indexWhere((end) => end > inLap);
  final segment = index < 0 ? definition.segments.length - 1 : index;
  return LapProgress(
    lap: lap,
    plannedLaps: plannedLaps,
    segmentIndex: segment,
    segment: definition.segments[segment],
    segmentStart: definition.segmentStarts[segment],
    segmentEnd: definition.segmentEnds[segment],
    remaining: (definition.segmentEnds[segment] - inLap).toDouble(),
    pace: BandStatus.none,
    strokeRate: BandStatus.none,
    lapInZoneShare: null,
    lapTime: Duration(milliseconds: (lapSeconds * 1000).round()),
    courseTime: Duration(milliseconds: (courseSeconds * 1000).round()),
    segmentTime: Duration(milliseconds: (segmentSeconds * 1000).round()),
    courseDistanceDm: courseMetres * 10.0,
  );
}

const LiveGhosts _none = (course: null, lap: null, segment: null);

void main() {
  group('ghostShares', () {
    test('Ghost liegt vorne: the lap ghost stands ahead of the rower at 460 m in lap 2', () {
      final lapGhost = _ghost([(0, 0), (115, 490), (248, 1000)]);
      final progress = _at(_seerunde, lap: 2, inLap: 460, lapSeconds: 115, courseSeconds: 365, courseMetres: 1460);

      final shares = ghostShares(progress, _seerunde, (course: null, lap: lapGhost, segment: null));

      expect(shares.lap, closeTo(0.49, 1e-9));
      expect(shares.lap, greaterThan(0.46));
    });

    test('Nur Rundendaten: only the lap track has a ghost', () {
      final progress = _at(_zoned, inLap: 300, lapSeconds: 75, segmentSeconds: 25, courseSeconds: 75);

      final shares = ghostShares(progress, _zoned, (course: null, lap: _ghost([(0, 0), (250, 1000)]), segment: null));

      expect(shares, (course: null, lap: 0.3, segment: null));
    });

    test('Runde 2: the lap ghost starts at the beginning of the lap and finishes after 4:08', () {
      final lapGhost = _ghost([(0, 0), (124, 500), (248, 1000)]);
      double? lapShare(num seconds) =>
          ghostShares(_at(_seerunde, lap: 2, inLap: 0, lapSeconds: seconds), _seerunde, (
            course: null,
            lap: lapGhost,
            segment: null,
          )).lap;

      expect(lapShare(0), 0);
      expect(lapShare(124), 0.5);
      expect(lapShare(247.9), lessThan(1));
      expect(lapShare(248), 1);
      expect(lapShare(300), 1);
    });

    test('the ghost of the template runs over all laps', () {
      final courseGhost = _ghost([(0, 0), (750, 3000)]);
      final progress = _at(_seerunde, lap: 2, inLap: 500, lapSeconds: 125, courseSeconds: 375, courseMetres: 1500);

      final shares = ghostShares(progress, _seerunde, (course: courseGhost, lap: null, segment: null));

      expect(shares.course, closeTo(0.5, 1e-9));
    });

    test('an open number of laps has no outer track and so no ghost on it', () {
      final progress = _at(_seerunde, plannedLaps: null, inLap: 500, lapSeconds: 125, courseSeconds: 125);

      final ghosts = (course: _ghost([(0, 0), (250, 1000)]), lap: null, segment: null);

      final shares = ghostShares(progress, _seerunde, ghosts);

      expect(shares.course, isNull);
    });

    test('the zone ghost starts anew with the segment', () {
      // In the 600 m zone from 200 m, 30 s after the zone began.
      final zoneGhost = _ghost([(0, 0), (150, 600)]);
      final progress = _at(_zoned, inLap: 320, lapSeconds: 80, segmentSeconds: 30, courseSeconds: 80);

      final shares = ghostShares(progress, _zoned, (course: null, lap: null, segment: zoneGhost));

      expect(shares.segment, closeTo(0.2, 1e-9));
    });

    test('on a time course a ghost stands where the rower is (Design D6)', () {
      final course = CourseDefinition.single(axis: CourseAxis.time, length: 240);
      final ghost = _ghost([(0, 0), (240, 1000)]);
      final progress = _at(course, inLap: 100, lapSeconds: 100, courseSeconds: 100, courseMetres: 380);

      final shares = ghostShares(progress, course, (course: ghost, lap: ghost, segment: null));

      expect(shares.lap, closeTo(100 / 240, 1e-9));
      expect(shares.course, closeTo(100 / 720, 1e-9));
    });

    test('without ghosts every track stays empty', () {
      expect(ghostShares(_at(_seerunde, inLap: 100), _seerunde, _none), (course: null, lap: null, segment: null));
    });
  });

  group('ghostGap', () {
    // 1000 m in 200 s at 5 m/s.
    final ghost = _ghost([(0, 0), (200, 1000)]);

    test('Rückstand auf einer Distanzachse: the ghost reached 460 m 7.6 s earlier', () {
      final progress = _at(_seerunde, inLap: 460, courseSeconds: 99.6, courseMetres: 460);

      final gap = ghostGap(progress, CourseAxis.distance, ghost)!;

      expect(gap.axis, CourseAxis.distance);
      expect(gap.amount, closeTo(7.6, 1e-9));
      expect(gap.ghostAhead, isTrue);
    });

    test('a lead on a distance axis', () {
      final progress = _at(_seerunde, inLap: 460, courseSeconds: 90, courseMetres: 460);

      final gap = ghostGap(progress, CourseAxis.distance, ghost)!;

      expect(gap.amount, closeTo(2, 1e-9));
      expect(gap.ghostAhead, isFalse);
    });

    test('Vorsprung auf einer Zeitachse: the rower is 12 m further than the ghost', () {
      final course = CourseDefinition.single(axis: CourseAxis.time, length: 240);
      final slow = _ghost([(0, 0), (240, 960)]);

      final gap = ghostGap(_at(course, inLap: 100, courseSeconds: 100, courseMetres: 412), CourseAxis.time, slow)!;

      expect(gap.axis, CourseAxis.time);
      expect(gap.amount, closeTo(12, 1e-9));
      expect(gap.ghostAhead, isFalse);
    });

    test('a tie is no lead of the ghost', () {
      final progress = _at(_seerunde, inLap: 500, courseSeconds: 100, courseMetres: 500);

      final gap = ghostGap(progress, CourseAxis.distance, ghost);

      expect(gap, const GhostGap(axis: CourseAxis.distance, amount: 0, ghostAhead: false));
    });

    test('Kein Ghost der Vorlage: no gap', () {
      expect(ghostGap(_at(_seerunde, plannedLaps: null, inLap: 500), CourseAxis.distance, null), isNull);
    });

    test('no gap once the rower is further than the ghost ever got', () {
      expect(ghostGap(_at(_seerunde, inLap: 10, courseSeconds: 210, courseMetres: 1010), CourseAxis.distance, ghost),
          isNull);
    });
  });
}
