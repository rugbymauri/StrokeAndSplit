// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:aergrow/data/db/database.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:aergrow/data/sessions/session_repository.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

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
      // The repository reads the current schema.
      await verifier.migrateAndValidate(db, 4);
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

  group('to version 4', () {
    v1.StrokesCompanion stroke1(int number) => v1.StrokesCompanion.insert(
          sessionId: 1,
          tMs: number * 2500,
          distanceDm: number * 100,
          strokeNumber: number,
          driveLengthMeters: 1.38,
          driveTimeMs: 820,
          recoveryTimeMs: 1640,
          peakForceNewtons: 712.5,
          averageForceNewtons: 431,
          watts: const Value(203),
        );

    Future<void> expectFullStrokes(AppDatabase db) async {
      final strokes = await (db.select(db.strokes)
            ..orderBy([(s) => OrderingTerm.asc(s.strokeNumber)]))
          .get();
      expect(
        strokes.map(
          (s) => (
            s.strokeNumber,
            s.driveLengthMeters,
            s.driveTimeMs,
            s.recoveryTimeMs,
            s.peakForceNewtons,
            s.averageForceNewtons,
            s.watts,
          ),
        ),
        [
          (1, 1.38, 820, 1640, 712.5, 431.0, 203),
          (2, 1.38, 820, 1640, 712.5, 431.0, 203),
        ],
      );
    }

    test('keeps the strokes of version 1 with all details as PM5 sessions',
        () async {
      final schema = await verifier.schemaAt(1);
      final old = v1.DatabaseAtV1(schema.newConnection());
      await old.batch((b) {
        b.insert(
          old.sessions,
          v1.SessionsCompanion.insert(
            startedAt: 0,
            status: 'complete',
            source: 'pm5',
            deviceName: const Value('PM5 Test'),
            strokeCount: const Value(2),
          ),
        );
        b.insertAll(old.strokes, [stroke1(1), stroke1(2)]);
      });
      await old.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 4);

      final session = (await db.select(db.sessions).get()).single;
      expect((session.protocol, session.deviceName, session.strokeCount),
          (ErgProtocol.pm5, 'PM5 Test', 2));
      await expectFullStrokes(db);
      await db.close();
    });

    test('keeps strokes, laps and courses with zones of version 3', () async {
      final schema = await verifier.schemaAt(3);
      final old = v3.DatabaseAtV3(schema.newConnection());
      await old.batch((b) {
        b.insert(
          old.zones,
          v3.ZonesCompanion.insert(
            name: 'Tempo',
            axis: 'distance',
            length: 600,
            paceFastCs: const Value(12500),
            paceSlowCs: const Value(13000),
          ),
        );
        b.insert(
          old.courses,
          v3.CoursesCompanion.insert(name: 'Seerunde', axis: 'distance'),
        );
        b.insert(
          old.courseVersions,
          v3.CourseVersionsCompanion.insert(
            courseId: 1,
            version: 1,
            length: 1000,
            createdAt: 0,
          ),
        );
        b.insertAll(old.courseSegments, [
          v3.CourseSegmentsCompanion.insert(
            versionId: 1,
            position: 0,
            length: 200,
          ),
          v3.CourseSegmentsCompanion.insert(
            versionId: 1,
            position: 1,
            length: 600,
            paceFastCs: const Value(12500),
            paceSlowCs: const Value(13000),
            zoneId: const Value(1),
            zoneName: const Value('Tempo'),
          ),
          v3.CourseSegmentsCompanion.insert(
            versionId: 1,
            position: 2,
            length: 200,
          ),
        ]);
        b.insert(
          old.sessions,
          v3.SessionsCompanion.insert(
            startedAt: 0,
            status: 'complete',
            source: 'pm5',
            courseVersionId: const Value(1),
            plannedLaps: const Value(1),
          ),
        );
        b.insertAll(old.strokes, [
          for (final n in [1, 2])
            v3.StrokesCompanion.insert(
              sessionId: 1,
              tMs: n * 2500,
              distanceDm: n * 100,
              strokeNumber: n,
              driveLengthMeters: 1.38,
              driveTimeMs: 820,
              recoveryTimeMs: 1640,
              peakForceNewtons: 712.5,
              averageForceNewtons: 431,
              watts: const Value(203),
            ),
        ]);
        b.insert(
          old.laps,
          v3.LapsCompanion.insert(
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
      await verifier.migrateAndValidate(db, 4);

      final session = (await db.select(db.sessions).get()).single;
      expect((session.protocol, session.courseVersionId), (ErgProtocol.pm5, 1));
      await expectFullStrokes(db);
      final lap = (await db.select(db.laps).get()).single;
      expect((lap.endWallMs, lap.inZoneShare), (252000, 0.75));
      final segment = (await (db.select(db.courseSegments)
                ..where((s) => s.position.equals(1)))
              .get())
          .single;
      expect((segment.zoneId, segment.zoneName), (1, 'Tempo'));
      expect((await db.select(db.zones).get()).single.name, 'Tempo');
      await db.close();
    });

    test('stores strokes without details', () async {
      final db = openTestDatabase();
      final id = await db.into(db.sessions).insert(SessionsCompanion.insert(
            startedAt: DateTime(2026, 10, 16),
            status: SessionStatus.complete,
            source: ErgSourceKind.pm5,
            protocol: const Value(ErgProtocol.ftms),
          ));
      await db.into(db.strokes).insert(StrokesCompanion.insert(
            sessionId: id,
            tMs: 2500,
            distanceDm: 100,
            strokeNumber: 1,
          ));
      final stroke = (await db.select(db.strokes).get()).single;
      expect(stroke.driveLengthMeters, isNull);
      expect(stroke.peakForceNewtons, isNull);
      expect((await db.select(db.sessions).get()).single.protocol, ErgProtocol.ftms);
      await db.close();
    });
  });
}
