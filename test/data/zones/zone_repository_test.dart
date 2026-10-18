import 'package:strokesplit/data/courses/course_layout.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/zones/zone.dart';
import 'package:strokesplit/data/zones/zone_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
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
  late AppDatabase db;
  late ZoneRepository zones;
  late CourseRepository courses;

  setUp(() {
    db = openTestDatabase();
    zones = ZoneRepository(db);
    courses = CourseRepository(db);
  });

  /// Stores a course of [length] m with the zones placed at their start.
  Future<int> course(String name, int length, List<(int, int)> placements) async {
    final layout = resolveCourse(
      axis: CourseAxis.distance,
      length: length,
      placements: [for (final (zone, start) in placements) ZonePlacement(zoneId: zone, start: start)],
      zones: {for (final z in await zones.all()) z.id: z},
    );
    return courses.create(name, layout.definition!);
  }

  Future<void> row(int courseId) async {
    await db.into(db.sessions).insert(SessionsCompanion.insert(
          startedAt: DateTime(2026, 10, 16),
          status: SessionStatus.complete,
          source: ErgSourceKind.pm5,
          courseVersionId: Value((await courses.get(courseId))!.versionId),
        ));
  }

  /// `500–600 Sprint` for each placed zone of the course.
  Future<List<String>> placed(int courseId) async {
    final definition = (await courses.get(courseId))!.definition;
    return [
      for (final (i, s) in definition.segments.indexed)
        if (s.zoneId != null) '${definition.segmentStarts[i]}–${definition.segmentEnds[i]} ${s.zoneName}',
    ];
  }

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

      expect(zoneErrors(zone), [ZoneError.bandMissing]);
      expect(
        () => zones.create(zone),
        throwsA(isA<ZoneValidationException>().having((e) => e.errors, 'errors', [ZoneError.bandMissing])),
      );
    });

    test('a stroke rate band the wrong way round', () {
      const zone = Zone(name: 'Falsch', axis: CourseAxis.distance, length: 100, spmMin: 22, spmMax: 20);

      expect(zoneErrors(zone), [ZoneError.spmReversed]);
    });

    test('a pace band the wrong way round', () {
      const zone = Zone(name: 'Falsch', axis: CourseAxis.distance, length: 100, paceFastCs: 13000, paceSlowCs: 12500);

      expect(zoneErrors(zone), [ZoneError.paceReversed]);
    });

    test('a band with only one bound', () {
      const zone = Zone(name: 'Halb', axis: CourseAxis.distance, length: 100, paceFastCs: 12500);

      expect(zoneErrors(zone), [ZoneError.paceBoundMissing]);
    });

    test('a zone without name or length', () {
      const zone = Zone(name: ' ', axis: CourseAxis.distance, length: 0, spmMin: 20, spmMax: 22);

      expect(zoneErrors(zone), [ZoneError.nameMissing, ZoneError.lengthMissing]);
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

  group('in courses', () {
    late int sprint;
    late int endurance;
    late int interval;

    setUp(() async {
      sprint = await zones.create(_sprint);
      endurance = await zones.create(const Zone(
        name: 'Ausdauer 2:30',
        axis: CourseAxis.distance,
        length: 500,
        paceFastCs: 14800,
        paceSlowCs: 15200,
      ));
      interval = await course('2 km Intervall', 2000, [(sprint, 500), (endurance, 1000)]);
      await course('Kurz', 1000, [(sprint, 100)]);
    });

    test('shows in how many courses a zone is placed', () async {
      final usage = {for (final u in await zones.allWithUsage()) u.zone.name: u.courses};

      expect(usage, {'Ausdauer 2:30': 1, 'Sprint': 2});
      expect(await zones.coursesUsing(sprint), ['2 km Intervall', 'Kurz']);
    });

    test('a longer sprint is longer in every course', () async {
      await zones.update(_sprint.copyWith(id: sprint, length: 150));

      expect(await placed(interval), ['500–650 Sprint', '1000–1500 Ausdauer 2:30']);
      expect((await courses.get(interval))!.definition.segments.map((s) => s.length), [500, 150, 350, 500, 500]);
    });

    test('rejects a change that does not fit and keeps every course', () async {
      await expectLater(
        zones.update(_sprint.copyWith(id: sprint, length: 600)),
        throwsA(isA<ZoneConflict>().having((c) => c.courses, 'courses', ['2 km Intervall'])),
      );

      expect((await zones.get(sprint))!.length, 100);
      expect(await placed(interval), ['500–600 Sprint', '1000–1500 Ausdauer 2:30']);
    });

    test('a renamed zone shows its new name in the courses', () async {
      await zones.update(_sprint.copyWith(id: sprint, name: 'Spurt'));

      expect(await placed(interval), ['500–600 Spurt', '1000–1500 Ausdauer 2:30']);
    });

    test('a changed band of a rowed course becomes a new version', () async {
      await row(interval);
      final rowed = (await courses.get(interval))!.versionId;

      await zones.update(Zone(
        id: endurance,
        name: 'Ausdauer 2:30',
        axis: CourseAxis.distance,
        length: 500,
        paceFastCs: 14500,
        paceSlowCs: 15000,
      ));

      final current = (await courses.get(interval))!;
      expect(current.versionId, isNot(rowed));
      expect(current.definition.segments[3].paceFastCs, 14500);
      expect((await courses.atVersion(rowed)).definition.segments[3].paceFastCs, 14800);
    });

    test('deleting a placed zone leaves its place free and keeps rowed versions', () async {
      await row(interval);
      final rowed = (await courses.get(interval))!.versionId;

      await zones.delete(sprint);

      expect(await placed(interval), ['1000–1500 Ausdauer 2:30']);
      expect((await courses.get(interval))!.definition.segments.map((s) => s.length), [1000, 500, 500]);
      expect((await courses.atVersion(rowed)).definition.segments[1].zoneName, 'Sprint');
    });

    test('keeps the axis of a zone that is placed', () {
      expect(
        () => zones.update(_sprint.copyWith(id: sprint, axis: CourseAxis.time)),
        throwsArgumentError,
      );
    });
  });
}
