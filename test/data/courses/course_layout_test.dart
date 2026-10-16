import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_layout.dart';
import 'package:aergrow/data/zones/zone.dart';
import 'package:flutter_test/flutter_test.dart';

const _sprint = Zone(
  id: 1,
  name: 'Sprint',
  axis: CourseAxis.distance,
  length: 100,
  paceFastCs: 10500,
  paceSlowCs: 11000,
  spmMin: 30,
  spmMax: 34,
);
const _endurance =
    Zone(id: 2, name: 'Ausdauer 2:30', axis: CourseAxis.distance, length: 500, paceFastCs: 14800, paceSlowCs: 15200);
const _minutes = Zone(id: 3, name: 'Vier Minuten', axis: CourseAxis.time, length: 240, spmMin: 20, spmMax: 22);
final _zones = {for (final z in [_sprint, _endurance, _minutes]) z.id: z};

CourseLayout _resolve(List<(int, int)> placements, {int length = 2000, CourseAxis axis = CourseAxis.distance}) =>
    resolveCourse(
      axis: axis,
      length: length,
      placements: [for (final (zone, start) in placements) ZonePlacement(zoneId: zone, start: start)],
      zones: _zones,
    );

/// `0–500 frei` or `500–600 Sprint`.
List<String> _sections(CourseDefinition definition) => [
      for (final (i, s) in definition.segments.indexed)
        '${definition.segmentStarts[i]}–${definition.segmentEnds[i]} ${s.zoneName ?? 'frei'}',
    ];

void main() {
  test('lays out the interval course with free gaps between the zones', () {
    final layout = _resolve([(2, 1000), (1, 500)]);

    expect(_sections(layout.definition!), [
      '0–500 frei',
      '500–600 Sprint',
      '600–1000 frei',
      '1000–1500 Ausdauer 2:30',
      '1500–2000 frei',
    ]);
    expect(layout.definition!.segments[1], _sprint.segment);
    expect(layout.definition!.placements, const [
      ZonePlacement(zoneId: 1, start: 500),
      ZonePlacement(zoneId: 2, start: 1000),
    ]);
  });

  test('a course without zones is one free part', () {
    expect(_sections(_resolve([], length: 5000).definition!), ['0–5000 frei']);
  });

  test('creates no empty gaps between zones that touch or at the ends', () {
    final layout = _resolve([(1, 0), (2, 100), (2, 600)], length: 1100);

    expect(_sections(layout.definition!), ['0–100 Sprint', '100–600 Ausdauer 2:30', '600–1100 Ausdauer 2:30']);
  });

  test('places the same zone twice', () {
    final layout = _resolve([(1, 500), (1, 1500)]);

    expect(layout.definition!.placements.map((p) => p.zoneId), [1, 1]);
  });

  test('rejects overlapping zones', () {
    final layout = _resolve([(2, 1000), (2, 1300)]);

    expect(layout.isValid, isFalse);
    expect(layout.errors.single.message,
        '„Ausdauer 2:30“ (1300–1800 m) überschneidet „Ausdauer 2:30“ (1000–1500 m).');
    expect(layout.errors.single.placements, {0, 1});
  });

  test('rejects a zone beyond the end of the course', () {
    final layout = _resolve([(2, 1800)]);

    expect(layout.errors.single.message, '„Ausdauer 2:30“ (1800–2300 m) ragt über das Streckenende bei 2000 m.');
  });

  test('rejects a zone before the start', () {
    expect(_resolve([(1, -50)]).errors.single.message, '„Sprint“ beginnt vor dem Start der Strecke.');
  });

  test('rejects a zone of the other axis', () {
    final layout = _resolve([(3, 0)]);

    expect(layout.errors.single.message, '„Vier Minuten“ misst Zeit, die Strecke Distanz.');
  });

  test('rejects a zone that is gone', () {
    expect(_resolve([(9, 0)]).errors.single.message, 'Eine eingebaute Zone gibt es nicht mehr.');
  });

  test('lays out a time course in m:ss', () {
    final layout = _resolve([(3, 60)], axis: CourseAxis.time, length: 600);

    expect(_sections(layout.definition!), ['0–60 frei', '60–300 Vier Minuten', '300–600 frei']);
    expect(_resolve([(3, 400)], axis: CourseAxis.time, length: 600).errors.single.message,
        '„Vier Minuten“ (6:40–10:40) ragt über das Streckenende bei 10:00.');
  });

  test('needs a length', () {
    expect(_resolve([], length: 0).errors.single.message, 'Die Länge fehlt.');
  });
}
