// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/sessions/session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test(
    'keeps sessions of version 1 with summary, samples and replay data',
    () async {
      final schema = await verifier.schemaAt(1);
      final old = v1.DatabaseAtV1(schema.newConnection());
      final startedAt = DateTime.utc(2026, 10, 15, 18, 30);
      await old.batch((b) {
        b.insert(
          old.sessions,
          v1.SessionsCompanion.insert(
            startedAt: startedAt.millisecondsSinceEpoch ~/ 1000,
            status: 'complete',
            source: 'pm5',
            deviceName: const Value('PM5 Test'),
            durationMs: const Value(60000),
            distanceDm: const Value(2500),
            averagePaceCs: const Value(12000),
            strokeCount: const Value(20),
          ),
        );
        b.insertAll(old.samples, [
          v1.SamplesCompanion.insert(sessionId: 1, tMs: 0, distanceDm: 0),
          v1.SamplesCompanion.insert(
            sessionId: 1,
            tMs: 60000,
            distanceDm: 2500,
            paceCs: const Value(12000),
          ),
        ]);
        b.insert(
          old.rawPackets,
          v1.RawPacketsCompanion.insert(
            sessionId: 1,
            tMs: 0,
            characteristicId: '0031',
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
        );
      });
      await old.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 2);
      final repository = SessionRepository(db);

      final session = (await repository.get(1))!;
      expect(session.startedAt.isAtSameMomentAs(startedAt), isTrue);
      expect(session.status, SessionStatus.complete);
      expect(session.distanceDm, 2500);
      expect(session.averagePaceCs, 12000);
      expect(session.templateId, isNull);
      final samples = await db.select(db.samples).get();
      expect(samples.map((s) => (s.tMs, s.distanceDm, s.wallMs)), [
        (0, 0, null),
        (60000, 2500, null),
      ]);
      final raw = await repository.rawRecording(1);
      expect(raw.packets.single.bytes, [1, 2, 3]);
      await db.close();
    },
  );

  test(
    'turns the band segments of version 2 into zones and keeps rowed laps',
    () async {
      final schema = await verifier.schemaAt(2);
      final old = v2.DatabaseAtV2(schema.newConnection());
      await old.batch((b) {
        b.insert(
          old.courses,
          v2.CoursesCompanion.insert(name: 'Seerunde', axis: 'distance'),
        );
        // Version 1 was rowed, version 2 is the current one.
        for (final version in [1, 2]) {
          b.insert(
            old.courseVersions,
            v2.CourseVersionsCompanion.insert(
              courseId: 1,
              version: version,
              length: 1000,
              createdAt: 0,
            ),
          );
          b.insertAll(old.courseSegments, [
            v2.CourseSegmentsCompanion.insert(
              versionId: version,
              position: 0,
              length: 200,
            ),
            v2.CourseSegmentsCompanion.insert(
              versionId: version,
              position: 1,
              length: 600,
              paceFastCs: const Value(12500),
              paceSlowCs: const Value(13000),
              spmMin: const Value(20),
              spmMax: const Value(22),
            ),
            v2.CourseSegmentsCompanion.insert(
              versionId: version,
              position: 2,
              length: 200,
            ),
          ]);
        }
        b.insert(
          old.sessions,
          v2.SessionsCompanion.insert(
            startedAt: 0,
            status: 'complete',
            source: 'pm5',
            courseVersionId: const Value(1),
          ),
        );
        b.insert(
          old.laps,
          v2.LapsCompanion.insert(
            sessionId: 1,
            lapNo: 1,
            startWallMs: 0,
            endWallMs: 252000,
            startDistanceDm: 0,
            endDistanceDm: 10000,
            complete: 1,
            inZoneShare: const Value(0.75),
          ),
        );
      });
      await old.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 3);

      final zone = (await db.select(db.zones).get()).single;
      expect(
        (zone.name, zone.axis, zone.length, zone.paceFastCs, zone.paceSlowCs),
        ('Seerunde 2', CourseAxis.distance, 600, 12500, 13000),
      );
      expect((zone.spmMin, zone.spmMax), (20, 22));
      Future<List<(int, int?, String?)>> segments(int version) async => [
        for (final s in await (db.select(db.courseSegments)
              ..where((s) => s.versionId.equals(version))
              ..orderBy([(s) => OrderingTerm.asc(s.position)]))
            .get())
          (s.length, s.zoneId, s.zoneName),
      ];
      // The zone starts at 200 m in the current version.
      expect(await segments(2), [
        (200, null, null),
        (600, zone.id, 'Seerunde 2'),
        (200, null, null),
      ]);
      expect(await segments(1), [
        (200, null, null),
        (600, null, 'Seerunde 2'),
        (200, null, null),
      ]);
      final lap = (await db.select(db.laps).get()).single;
      expect((lap.endWallMs, lap.complete, lap.inZoneShare), (252000, true, 0.75));
      await db.close();
    },
  );
}
