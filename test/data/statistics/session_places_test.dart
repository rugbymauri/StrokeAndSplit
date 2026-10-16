import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/statistics/session_places.dart';
import 'package:aergrow/data/templates/template_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/rowed_sessions.dart';
import '../../support/test_database.dart';

void main() {
  test('follows the rankings when later sessions overtake a session', () async {
    final db = openTestDatabase();
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    final course =
        await CourseRepository(db).create('Seerunde', CourseDefinition.single(axis: CourseAxis.distance, length: 1000));
    final templates = TemplateRepository(db);
    final template = (await templates.get(await templates.create('Seerunde x1', courseId: course, laps: 1)))!;
    final id = await storeRowedSession(db, template: template, laps: [RowedLap.single(248000, 1000)]);
    final seen = <SessionPlaces>[];
    container.listen(sessionPlacesProvider(id), (_, next) => seen.addAll([?next.value]), fireImmediately: true);
    await pumpEventQueue();
    expect(seen.last, const SessionPlaces(session: 1, laps: {1: 1}));

    await storeRowedSession(db, template: template, laps: [RowedLap.single(245000, 1000)]);
    await pumpEventQueue();
    expect(seen.last, const SessionPlaces(session: 2, laps: {1: 2}));

    for (final ms in [240000, 242000]) {
      await storeRowedSession(db, template: template, laps: [RowedLap.single(ms, 1000)]);
    }
    await pumpEventQueue();
    expect(seen.last, SessionPlaces.none);
  });

  test('gives no places to a session of the simulator', () async {
    final db = openTestDatabase();
    final course =
        await CourseRepository(db).create('Seerunde', CourseDefinition.single(axis: CourseAxis.distance, length: 1000));
    final templates = TemplateRepository(db);
    final template = (await templates.get(await templates.create('Seerunde x1', courseId: course, laps: 1)))!;
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    final id = await storeRowedSession(db,
        template: template, source: ErgSourceKind.simulator, laps: [RowedLap.single(248000, 1000)]);

    expect(await container.read(sessionPlacesRepositoryProvider).places(id), SessionPlaces.none);
  });
}
