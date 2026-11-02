import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/health/health_workout.dart';
import 'package:strokesplit/data/sessions/session_accumulator.dart';
import 'package:strokesplit/data/sessions/session_repository.dart';
import 'package:strokesplit/data/sources/erg_source.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late SessionRepository repository;
  final startedAt = DateTime.utc(2026, 11, 2, 18, 30);

  setUp(() {
    db = openTestDatabase();
    repository = SessionRepository(db);
  });
  tearDown(() => db.close());

  test('reads the measurements on the wall clock, the laps and the pauses', () async {
    final id = await repository.create(startedAt: startedAt, source: ErgSourceKind.pm5);
    SamplesCompanion sample(int tMs, int? wallMs, {int? heartRate}) => SamplesCompanion.insert(
          sessionId: id,
          tMs: tMs,
          distanceDm: tMs ~/ 100,
          wallMs: Value(wallMs),
          heartRate: Value(heartRate),
          watts: const Value(150),
          paceCs: const Value(12500),
          calories: const Value(12),
        );
    await repository.write(SessionBatch(
      samples: [sample(1000, 1500, heartRate: 140), sample(2000, null)],
      strokes: const [],
      rawPackets: const [],
      laps: [
        LapsCompanion.insert(
          sessionId: id,
          lapNo: 1,
          startWallMs: 0,
          endWallMs: 2000,
          startDistanceDm: 0,
          endDistanceDm: 200,
          complete: true,
        ),
      ],
      pauses: [PausesCompanion.insert(sessionId: id, startWallMs: 1600, endWallMs: 1800)],
    ));
    await repository.finish(id, endedAt: startedAt.add(const Duration(seconds: 3)));

    final data = (await repository.healthData(id))!;
    expect(data.startedAt.toUtc(), startedAt);
    expect(data.endedAt!.toUtc(), startedAt.add(const Duration(seconds: 3)));
    expect(data.templateName, isNull);
    // Without a wall clock the time of the rower.
    expect([for (final p in data.points) (p.wallMs, p.heartRate, p.watts, p.paceCs, p.calories)], [
      (1500, 140, 150, 12500, 12),
      (2000, null, 150, 12500, 12),
    ]);
    expect(data.laps, [(startMs: 0, endMs: 2000, distanceDm: 200)]);
    expect(data.pauses, [(startWallMs: 1600, endWallMs: 1800)]);
  });

  test('gives a recorded session with a pause as a workout', () async {
    final id = await repository.create(startedAt: startedAt, source: ErgSourceKind.pm5);
    final accumulator = SessionAccumulator(id);
    loadFixture('pause').packets.forEach(accumulator.add);
    accumulator.finish();
    await repository.write(accumulator.takeBatch());
    await repository.finish(id);

    final workout = healthWorkoutOf((await repository.healthData(id))!, freeTitle: 'Freies Rudern');
    expect(workout.title, 'Freies Rudern');
    expect(workout.meters, greaterThan(0));
    expect(workout.power, isNotEmpty);
    expect(workout.speed, isNotEmpty);
    expect(workout.segments.where((s) => s.type == HealthSegmentType.pause), isNotEmpty);
  });

  test('knows no session that is not stored', () async {
    expect(await repository.healthData(42), isNull);
  });
}
