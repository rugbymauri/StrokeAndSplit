import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/zones/zone.dart';
import 'package:aergrow/data/zones/zone_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

const _sprint = Zone(
  name: 'Sprint',
  axis: CourseAxis.distance,
  length: 100,
  paceFastCs: 10500,
  paceSlowCs: 11000,
  spmMin: 30,
  spmMax: 34,
);

void main() {
  late ZoneRepository zones;

  setUp(() => zones = ZoneRepository(openTestDatabase()));

  test('stores a zone with both bands', () async {
    final id = await zones.create(_sprint);

    final usage = (await zones.allWithUsage()).single;
    expect(usage.zone, Zone(
      id: id,
      name: 'Sprint',
      axis: CourseAxis.distance,
      length: 100,
      paceFastCs: 10500,
      paceSlowCs: 11000,
      spmMin: 30,
      spmMax: 34,
    ));
    expect(usage.courses, 0);
  });

  test('stores a zone with only a pace band', () async {
    await zones.create(const Zone(
      name: 'Ausdauer 2:30',
      axis: CourseAxis.distance,
      length: 500,
      paceFastCs: 14800,
      paceSlowCs: 15200,
    ));

    final zone = (await zones.all()).single;
    expect((zone.spmMin, zone.spmMax), (null, null));
  });

  test('lists zones by axis and name', () async {
    await zones.create(const Zone(name: 'Vier Minuten', axis: CourseAxis.time, length: 240, spmMin: 20, spmMax: 22));
    await zones.create(_sprint);
    await zones.create(const Zone(name: 'Ausdauer', axis: CourseAxis.distance, length: 500, spmMin: 18, spmMax: 20));

    expect([for (final z in await zones.all()) z.name], ['Ausdauer', 'Sprint', 'Vier Minuten']);
  });

  group('rejects', () {
    test('a zone without any band', () {
      const zone = Zone(name: 'Nichts', axis: CourseAxis.distance, length: 100);

      expect(zoneErrors(zone), ['Es fehlt ein Band: Pace, Schlagzahl oder beides.']);
      expect(() => zones.create(zone), throwsArgumentError);
    });

    test('a stroke rate band the wrong way round', () {
      const zone = Zone(name: 'Falsch', axis: CourseAxis.distance, length: 100, spmMin: 22, spmMax: 20);

      expect(zoneErrors(zone), ['Die niedrigste Schlagzahl liegt über der höchsten.']);
    });

    test('a pace band the wrong way round', () {
      const zone = Zone(name: 'Falsch', axis: CourseAxis.distance, length: 100, paceFastCs: 13000, paceSlowCs: 12500);

      expect(zoneErrors(zone), ['Die schnellste Pace ist langsamer als die langsamste.']);
    });

    test('a band with only one bound', () {
      const zone = Zone(name: 'Halb', axis: CourseAxis.distance, length: 100, paceFastCs: 12500);

      expect(zoneErrors(zone), ['Für das Pace-Band fehlt eine Grenze.']);
    });

    test('a zone without name or length', () {
      const zone = Zone(name: ' ', axis: CourseAxis.distance, length: 0, spmMin: 20, spmMax: 22);

      expect(zoneErrors(zone), ['Der Name fehlt.', 'Die Länge fehlt.']);
    });
  });

  test('renames a zone and changes its bands', () async {
    final id = await zones.create(_sprint);

    await zones.update(Zone(id: id, name: 'Spurt', axis: CourseAxis.distance, length: 150, spmMin: 32, spmMax: 36));

    final zone = (await zones.get(id))!;
    expect((zone.name, zone.length, zone.paceFastCs, zone.spmMin), ('Spurt', 150, null, 32));
  });

  test('changes the axis of a zone that is in no course', () async {
    final id = await zones.create(_sprint);

    await zones.update(Zone(id: id, name: 'Sprint', axis: CourseAxis.time, length: 30, spmMin: 30, spmMax: 34));

    expect((await zones.get(id))!.axis, CourseAxis.time);
  });

  test('deletes a zone from the list', () async {
    final id = await zones.create(_sprint);

    await zones.delete(id);

    expect(await zones.all(), isEmpty);
    expect((await zones.get(id))!.name, 'Sprint');
  });
}
