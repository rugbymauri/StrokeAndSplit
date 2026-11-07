import 'package:flutter_test/flutter_test.dart';
import 'package:strokesplit/data/health/health_exercise.dart';

final _start = DateTime.utc(2026, 11, 2, 18, 30);

HealthExercise _exercise({
  List<HealthPoint> points = const [],
  List<HealthLapInput> laps = const [],
  List<HealthPauseInput> pauses = const [],
  DateTime? endedAt,
  String? workout = 'Seerunde x3',
  int distanceDm = 30217,
}) => healthExerciseOf(
  HealthSessionData(
    startedAt: _start,
    endedAt: endedAt,
    distanceDm: distanceDm,
    workoutName: workout,
    points: points,
    laps: laps,
    pauses: pauses,
  ),
  freeTitle: 'Freies Rudern',
);

DateTime _at(int seconds) => _start.add(Duration(seconds: seconds));

void main() {
  test('describes the session with its time, title, distance and an id from its start', () {
    final exercise = _exercise(endedAt: _at(600));
    expect(exercise.id, 'strokesplit-${_start.millisecondsSinceEpoch}');
    expect((exercise.start, exercise.end), (_start, _at(600)));
    expect(exercise.title, 'Seerunde x3');
    expect(exercise.meters, 3021.7);
    expect(_exercise(workout: null).title, 'Freies Rudern');
  });

  test(
    'ends with the last measurement without an end, and never before it starts',
    () {
      expect(
        _exercise(
          points: const [HealthPoint(wallMs: 0), HealthPoint(wallMs: 95000)],
        ).end,
        _at(95),
      );
      expect(_exercise().end, _at(1));
    },
  );

  test('takes the highest calories of the rower, and none without or at 0', () {
    final points = [
      const HealthPoint(wallMs: 0, calories: 3),
      const HealthPoint(wallMs: 1000, calories: 7),
    ];
    expect(_exercise(points: points).kilocalories, 7);
    expect(
      _exercise(points: const [HealthPoint(wallMs: 0, calories: 0)])
          .kilocalories,
      isNull,
    );
    expect(
      _exercise(points: const [HealthPoint(wallMs: 0)]).kilocalories,
      isNull,
    );
  });

  test('keeps the last value of each second and leaves out missing values and a heart rate of 0', () {
    final exercise = _exercise(
      endedAt: _at(10),
      points: const [
        HealthPoint(wallMs: 200, heartRate: 0, watts: 150, paceCs: 12500),
        HealthPoint(wallMs: 700, heartRate: 140, watts: 160, paceCs: 0),
        HealthPoint(wallMs: 1300, watts: 170, paceCs: 10000),
      ],
    );
    final heartRate = [
      for (final s in exercise.heartRate.single.samples) (s.time, s.value),
    ];
    expect(heartRate, [(_at(0).add(const Duration(milliseconds: 700)), 140)]);
    expect(
      [for (final s in exercise.power.single.samples) s.value],
      [160, 170],
    );
    // 500 m in 1:40.0 are 5 m/s; a pace of 0 is no pace.
    expect([for (final s in exercise.speed.single.samples) s.value], [4, 5]);
    expect(exercise.heartRate.single.id, '${exercise.id}-heartRate-0');
  });

  test('splits a series into parts of 10 minutes, each ending after its last sample', () {
    final exercise = _exercise(
      endedAt: _at(1500),
      points: [
        for (var s = 0; s < 1500; s += 60)
          HealthPoint(wallMs: s * 1000, watts: 150),
      ],
    );
    expect(
      [for (final part in exercise.power) part.samples.length],
      [10, 10, 5],
    );
    expect(
      [for (final part in exercise.power) part.id.split('-').last],
      ['0', '1', '2'],
    );
    expect(exercise.power.first.end, _at(541));
  });

  test('leaves out measurements after the end', () {
    final exercise = _exercise(
      endedAt: _at(5),
      points: const [
        HealthPoint(wallMs: 4000, watts: 1),
        HealthPoint(wallMs: 6000, watts: 2),
      ],
    );
    expect([for (final s in exercise.power.single.samples) s.value], [1]);
  });

  test(
    'moves the laps from the session time to the wall clock past the pauses',
    () {
      // Lap 1 to 300 s, a pause of a minute at 400 s, lap 2 to 600 s session time.
      final exercise = _exercise(
        endedAt: _at(660),
        laps: const [
          (startMs: 0, endMs: 300000, distanceDm: 10000),
          (startMs: 300000, endMs: 600000, distanceDm: 9500),
        ],
        pauses: const [(startWallMs: 400000, endWallMs: 460000)],
      );
      expect(
        [for (final lap in exercise.laps) (lap.start, lap.end, lap.meters)],
        [(_at(0), _at(300), 1000), (_at(300), _at(660), 950)],
      );
    },
  );

  test('a lap starting when a pause begins starts after it, one ending then ends before it', () {
    final exercise = _exercise(
      endedAt: _at(200),
      laps: const [
        (startMs: 0, endMs: 100000, distanceDm: 4000),
        (startMs: 100000, endMs: 150000, distanceDm: 2000),
      ],
      pauses: const [(startWallMs: 100000, endWallMs: 150000)],
    );
    expect(
      [for (final lap in exercise.laps) (lap.start, lap.end)],
      [(_at(0), _at(100)), (_at(150), _at(200))],
    );
  });

  test(
    'marks the pauses and the rowing between them, and nothing without pauses',
    () {
      final exercise = _exercise(
        endedAt: _at(300),
        pauses: const [
          (startWallMs: 100000, endWallMs: 130000),
          (startWallMs: 200000, endWallMs: 400000),
        ],
      );
      expect(
        [for (final s in exercise.segments) (s.start, s.end, s.type)],
        [
          (_at(0), _at(100), HealthSegmentType.rowing),
          (_at(100), _at(130), HealthSegmentType.pause),
          (_at(130), _at(200), HealthSegmentType.rowing),
          (_at(200), _at(300), HealthSegmentType.pause),
        ],
      );
      expect(_exercise(endedAt: _at(300)).segments, isEmpty);
    },
  );
}
