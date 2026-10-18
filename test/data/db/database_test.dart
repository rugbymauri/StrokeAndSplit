import 'dart:typed_data';

import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  test('stores a session with its rows and reads it back', () async {
    final db = openTestDatabase();
    final startedAt = DateTime(2026, 10, 15, 18, 30);

    final id = await db.into(db.sessions).insert(SessionsCompanion.insert(
          startedAt: startedAt,
          status: SessionStatus.recording,
          source: ErgSourceKind.pm5,
        ));
    await db.into(db.samples).insert(SamplesCompanion.insert(sessionId: id, tMs: 250, distanceDm: 12));
    await db.into(db.rawPackets).insert(RawPacketsCompanion.insert(
          sessionId: id,
          tMs: 0,
          characteristicId: '0031',
          bytes: Uint8List.fromList([1, 2, 3]),
        ));

    final session = await (db.select(db.sessions)..where((s) => s.id.equals(id))).getSingle();
    expect(session.startedAt, startedAt);
    expect(session.status, SessionStatus.recording);
    expect(session.source, ErgSourceKind.pm5);
    expect((await db.select(db.samples).getSingle()).distanceDm, 12);
    expect((await db.select(db.rawPackets).getSingle()).bytes, [1, 2, 3]);
  });

  test('rejects rows of a session that does not exist', () async {
    final db = openTestDatabase();

    expect(
      () => db.into(db.samples).insert(SamplesCompanion.insert(sessionId: 42, tMs: 0, distanceDm: 0)),
      throwsA(anything),
    );
  });
}
