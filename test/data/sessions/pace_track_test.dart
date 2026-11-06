import 'package:flutter_test/flutter_test.dart';
import 'package:strokesplit/data/sessions/pace_track.dart';

/// A point a second from 0 to [seconds], at [dmPerSecond] decimetres a second.
List<(int, int)> _steady(
  int seconds, {
  int dmPerSecond = 40,
  int fromMs = 0,
  int fromDm = 0,
}) => [
  for (var s = 0; s <= seconds; s++)
    (fromMs + s * 1000, fromDm + s * dmPerSecond),
];

void main() {
  test('splits a steady session into steps of ten seconds at its pace', () {
    final track = PaceTrack.of(_steady(60));

    expect(track.steps, [for (var i = 1; i <= 6; i++) (i * 10000, 12500)]);
    expect(track.fastestCs, 12500);
    expect(track.slowestCs, 12500);
  });

  test('finds the fastest and the slowest step', () {
    final track = PaceTrack.of([
      ..._steady(30),
      // 5 m/s: 1:40.
      ..._steady(30, dmPerSecond: 50, fromMs: 30000, fromDm: 1200).skip(1),
    ]);

    expect(track.fastestCs, 10000);
    expect(track.slowestCs, 12500);
  });

  test('leaves out a pause, as its rowed time does not move', () {
    final before = _steady(20);
    // Twenty samples of a pause: the same rowed time and distance.
    final pause = List.filled(20, (20000, 800));
    final after = _steady(20, fromMs: 20000, fromDm: 800).skip(1);

    expect(PaceTrack.of([...before, ...pause, ...after]).steps, [
      (10000, 12500),
      (20000, 12500),
      (30000, 12500),
      (40000, 12500),
    ]);
  });

  test('leaves out a last step shorter than half a step and steps without distance', () {
    expect(PaceTrack.of(_steady(23)).steps, [(10000, 12500), (20000, 12500)]);
    expect(PaceTrack.of(_steady(20, dmPerSecond: 0)).steps, isEmpty);
    expect(PaceTrack.of(const [(0, 0)]).steps, isEmpty);
  });

  test('takes longer steps on a long session, about sixty of them', () {
    final track = PaceTrack.of(_steady(3600));

    expect(track.steps, hasLength(60));
    expect(track.steps.first, (60000, 12500));
  });
}
