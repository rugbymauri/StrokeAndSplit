import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/ghost/ghost.dart';
import 'package:flutter_test/flutter_test.dart';

/// 100 m in 20 s, a pause of 10 s, then 100 m in 25 s.
final _withPause = GhostTrack(const [
  GhostPoint(wallMs: 0, distanceDm: 0),
  GhostPoint(wallMs: 20000, distanceDm: 1000),
  GhostPoint(wallMs: 30000, distanceDm: 1000),
  GhostPoint(wallMs: 55000, distanceDm: 2000),
]);

void main() {
  group('GhostTrack', () {
    final track = GhostTrack(const [
      GhostPoint(wallMs: 1000, distanceDm: 40),
      GhostPoint(wallMs: 5000, distanceDm: 240),
    ]);

    test('interpolates between two points', () {
      expect(track.distanceDmAt(3000), 140);
      expect(track.positionAt(CourseAxis.distance, 3000), 14);
      expect(track.positionAt(CourseAxis.time, 3000), 3);
    });

    test('stands at the start before the first point', () {
      expect(track.distanceDmAt(0), 40);
      expect(track.positionAt(CourseAxis.distance, -500), 4);
      expect(track.positionAt(CourseAxis.time, 0), 1);
    });

    test('stands at the finish after the last point', () {
      expect(track.distanceDmAt(9000), 240);
      expect(track.positionAt(CourseAxis.distance, 9000), 24);
      expect(track.positionAt(CourseAxis.time, 9000), 5);
    });

    test('finds the wall-clock time of a distance', () {
      expect(track.wallMsAt(140), 3000);
      expect(track.wallMsAtPosition(CourseAxis.distance, 14), 3000);
      expect(track.wallMsAt(0), 1000, reason: 'before the start');
      expect(track.wallMsAt(240), 5000);
      expect(track.wallMsAt(241), isNull, reason: 'never got that far');
    });

    test('finds the wall-clock time of a position on a time axis', () {
      expect(track.wallMsAtPosition(CourseAxis.time, 3), 3000);
      expect(track.wallMsAtPosition(CourseAxis.time, 0), 1000);
      expect(track.wallMsAtPosition(CourseAxis.time, 6), isNull);
    });

    test('keeps the distance during a pause while the clock runs', () {
      expect(_withPause.distanceDmAt(20000), 1000);
      expect(_withPause.distanceDmAt(25000), 1000);
      expect(_withPause.distanceDmAt(42500), 1500);
      expect(_withPause.wallMsAt(1000), 20000, reason: 'reached when the pause begins');
      expect(_withPause.wallMsAt(1500), 42500);
      expect(_withPause.durationMs, 55000);
      expect(_withPause.distanceDm, 2000);
    });

    test('works with a single point', () {
      final single = GhostTrack(const [GhostPoint(wallMs: 0, distanceDm: 0)]);
      expect(single.distanceDmAt(1000), 0);
      expect(single.wallMsAt(0), 0);
      expect(single.wallMsAt(1), isNull);
    });

    test('rejects no points and points going back', () {
      expect(() => GhostTrack(const []), throwsArgumentError);
      expect(
        () => GhostTrack(const [GhostPoint(wallMs: 10, distanceDm: 0), GhostPoint(wallMs: 5, distanceDm: 1)]),
        throwsArgumentError,
      );
      expect(
        () => GhostTrack(const [GhostPoint(wallMs: 0, distanceDm: 5), GhostPoint(wallMs: 5, distanceDm: 1)]),
        throwsArgumentError,
      );
    });

    test('compares by its points', () {
      expect(
        GhostTrack(const [GhostPoint(wallMs: 0, distanceDm: 0)]),
        GhostTrack(const [GhostPoint(wallMs: 0, distanceDm: 0)]),
      );
    });
  });

  test('GhostGap compares by axis, amount and side', () {
    const gap = GhostGap(axis: CourseAxis.distance, amount: 7.6, ghostAhead: true);
    expect(gap, const GhostGap(axis: CourseAxis.distance, amount: 7.6, ghostAhead: true));
    expect(gap, isNot(const GhostGap(axis: CourseAxis.distance, amount: 7.6, ghostAhead: false)));
  });
}
