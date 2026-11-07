import 'package:flutter_test/flutter_test.dart';
import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/zone_intensity.dart';

/// Pace in hundredths of a second per 500 m.
int _cs(int minutes, int seconds) => (minutes * 60 + seconds) * 100;

CourseSegment _pace(int fast, int slow) =>
    CourseSegment(length: 100, paceFastCs: fast, paceSlowCs: slow);

CourseSegment _spm(int min, int max) =>
    CourseSegment(length: 100, spmMin: min, spmMax: max);

CourseSegment _level(int level) =>
    CourseSegment(length: 100, resistanceLevel: level);

void main() {
  test('a pace band counts with its middle', () {
    expect(zoneIntensity(_pace(_cs(3, 5), _cs(3, 15))), ZoneIntensity.easy);
    expect(zoneIntensity(_pace(_cs(2, 55), _cs(3, 5))), ZoneIntensity.easy);
    expect(zoneIntensity(_pace(_cs(2, 28), _cs(2, 32))), ZoneIntensity.medium);
    expect(zoneIntensity(_pace(_cs(2, 20), _cs(2, 30))), ZoneIntensity.hard);
    expect(zoneIntensity(_pace(_cs(1, 45), _cs(1, 50))), ZoneIntensity.hard);
  });

  test('a stroke-rate band counts with its middle', () {
    expect(zoneIntensity(_spm(20, 22)), ZoneIntensity.easy);
    expect(zoneIntensity(_spm(21, 22)), ZoneIntensity.medium);
    expect(zoneIntensity(_spm(22, 24)), ZoneIntensity.medium);
    expect(zoneIntensity(_spm(22, 26)), ZoneIntensity.hard);
  });

  test('a resistance level is easy up to 5, medium up to 10, then hard', () {
    expect(
      [
        for (final l in [1, 5, 6, 10, 11, 20]) zoneIntensity(_level(l)),
      ],
      [
        ZoneIntensity.easy,
        ZoneIntensity.easy,
        ZoneIntensity.medium,
        ZoneIntensity.medium,
        ZoneIntensity.hard,
        ZoneIntensity.hard,
      ],
    );
  });

  test('the hardest target wins', () {
    expect(
      zoneIntensity(
        CourseSegment(
          length: 100,
          paceFastCs: _cs(2, 50),
          paceSlowCs: _cs(3, 0),
          spmMin: 18,
          spmMax: 20,
          resistanceLevel: 11,
        ),
      ),
      ZoneIntensity.hard,
    );
    expect(
      zoneIntensity(
        CourseSegment(
          length: 100,
          paceFastCs: _cs(3, 10),
          paceSlowCs: _cs(3, 20),
          spmMin: 22,
          spmMax: 23,
        ),
      ),
      ZoneIntensity.medium,
    );
  });

  test('a free segment has no intensity', () {
    expect(zoneIntensity(const CourseSegment(length: 100)), isNull);
  });
}
