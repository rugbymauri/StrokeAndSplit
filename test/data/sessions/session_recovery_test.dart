import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/sessions/session_accumulator.dart';
import 'package:aergrow/data/sessions/session_repository.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  test('keeps a session that ended with the app and marks it incomplete', () async {
    final db = openTestDatabase();
    final repository = SessionRepository(db);
    final packets = loadFixture('just_row').packets;

    // Recording: two batches reach the database, then the app ends.
    final id = await repository.create(startedAt: DateTime(2026, 10, 15, 18), source: ErgSourceKind.pm5);
    final accumulator = SessionAccumulator(id);
    final half = packets.length ~/ 2;
    packets.take(half).forEach(accumulator.add);
    await repository.write(accumulator.takeBatch());
    final writtenProgress = accumulator.progress;
    packets.skip(half).forEach(accumulator.add);

    // Next app start.
    final recovered = await SessionRepository(db).recoverInterrupted();

    final session = await repository.get(id);
    expect(recovered, 1);
    expect(session!.status, SessionStatus.incomplete);
    expect(session.durationMs, writtenProgress.elapsed.inMilliseconds);
    expect(session.distanceDm, (writtenProgress.distanceMeters * 10).round());
    expect(session.distanceDm, greaterThan(0));
  });

  test('leaves finished sessions alone', () async {
    final db = openTestDatabase();
    final repository = SessionRepository(db);
    final id = await repository.create(startedAt: DateTime(2026, 10, 15), source: ErgSourceKind.simulator);
    await repository.finish(id);

    expect(await repository.recoverInterrupted(), 0);
    expect((await repository.get(id))!.status, SessionStatus.complete);
  });
}
