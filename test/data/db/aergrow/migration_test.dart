// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:strokesplit/data/sessions/session_repository.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;
import 'generated/schema_v5.dart' as v5;
import 'generated/schema_v6.dart' as v6;
import 'generated/schema_v7.dart' as v7;
import 'generated/schema_v8.dart' as v8;
import 'generated/schema_v10.dart' as v10;

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
      await verifier.migrateAndValidate(db, 7);
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
        for (final s
            in await (db.select(db.courseSegments)
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
      expect(
        (lap.endWallMs, lap.complete, lap.inZoneShare),
        (252000, true, 0.75),
      );
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
      final strokes = await (db.select(
        db.strokes,
      )..orderBy([(s) => OrderingTerm.asc(s.strokeNumber)])).get();
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

    test(
      'keeps the strokes of version 1 with all details as PM5 sessions',
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
        await verifier.migrateAndValidate(db, 7);

        final session = (await db.select(db.sessions).get()).single;
        expect(
          (session.protocol, session.deviceName, session.strokeCount),
          (ErgProtocol.pm5, 'PM5 Test', 2),
        );
        await expectFullStrokes(db);
        await db.close();
      },
    );

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
      await verifier.migrateAndValidate(db, 7);

      final session = (await db.select(db.sessions).get()).single;
      expect((session.protocol, session.courseVersionId), (ErgProtocol.pm5, 1));
      await expectFullStrokes(db);
      final lap = (await db.select(db.laps).get()).single;
      expect((lap.endWallMs, lap.inZoneShare), (252000, 0.75));
      final segment = (await (db.select(
        db.courseSegments,
      )..where((s) => s.position.equals(1))).get()).single;
      expect((segment.zoneId, segment.zoneName), (1, 'Tempo'));
      expect((await db.select(db.zones).get()).single.name, 'Tempo');
      await db.close();
    });

    test('stores strokes without details', () async {
      final db = openTestDatabase();
      final id = await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              startedAt: DateTime(2026, 10, 16),
              status: SessionStatus.complete,
              source: ErgSourceKind.pm5,
              protocol: const Value(ErgProtocol.ftms),
            ),
          );
      await db
          .into(db.strokes)
          .insert(
            StrokesCompanion.insert(
              sessionId: id,
              tMs: 2500,
              distanceDm: 100,
              strokeNumber: 1,
            ),
          );
      final stroke = (await db.select(db.strokes).get()).single;
      expect(stroke.driveLengthMeters, isNull);
      expect(stroke.peakForceNewtons, isNull);
      expect(
        (await db.select(db.sessions).get()).single.protocol,
        ErgProtocol.ftms,
      );
      await db.close();
    });
  });

  group('to version 5', () {
    test('keeps the sessions of version 4 as not imported', () async {
      final schema = await verifier.schemaAt(4);
      final old = v4.DatabaseAtV4(schema.newConnection());
      await old.batch((b) {
        b.insertAll(old.sessions, [
          v4.SessionsCompanion.insert(
            startedAt: 0,
            status: 'complete',
            source: 'pm5',
            deviceName: const Value('PM5 Test'),
          ),
          v4.SessionsCompanion.insert(
            startedAt: 0,
            status: 'complete',
            source: 'ftms',
            protocol: const Value('ftms'),
          ),
        ]);
      });
      await old.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 7);

      final sessions = await (db.select(
        db.sessions,
      )..orderBy([(s) => OrderingTerm.asc(s.id)])).get();
      expect(sessions.map((s) => (s.protocol, s.deviceName, s.imported)), [
        (ErgProtocol.pm5, 'PM5 Test', false),
        (ErgProtocol.ftms, null, false),
      ]);
      await db.close();
    });

    test('keeps the sessions of version 1 as not imported', () async {
      final schema = await verifier.schemaAt(1);
      final old = v1.DatabaseAtV1(schema.newConnection());
      await old
          .into(old.sessions)
          .insert(
            v1.SessionsCompanion.insert(
              startedAt: 0,
              status: 'complete',
              source: 'pm5',
            ),
          );
      await old.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 7);

      final session = (await db.select(db.sessions).get()).single;
      expect((session.protocol, session.imported), (ErgProtocol.pm5, false));
      await db.close();
    });

    test('marks new sessions as not imported', () async {
      final db = openTestDatabase();
      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              startedAt: DateTime(2026, 10, 16),
              status: SessionStatus.complete,
              source: ErgSourceKind.pm5,
            ),
          );
      expect((await db.select(db.sessions).get()).single.imported, isFalse);
      await db.close();
    });
  });

  group('to version 6', () {
    Future<void> expectNoPulseSummary(AppDatabase db) async {
      final sessions = await (db.select(
        db.sessions,
      )..orderBy([(s) => OrderingTerm.asc(s.id)])).get();
      expect(
        sessions.map((s) => (s.averageHeartRate, s.maxHeartRate, s.rmssdMs)),
        everyElement((null, null, null)),
      );
      expect(await db.select(db.rrIntervals).get(), isEmpty);
    }

    test('keeps the sessions of version 5 without pulse summary', () async {
      final schema = await verifier.schemaAt(5);
      final old = v5.DatabaseAtV5(schema.newConnection());
      await old.batch((b) {
        b.insertAll(old.sessions, [
          v5.SessionsCompanion.insert(
            startedAt: 0,
            status: 'complete',
            source: 'pm5',
            deviceName: const Value('PM5 Test'),
            durationMs: const Value(60000),
            distanceDm: const Value(2500),
          ),
          v5.SessionsCompanion.insert(
            startedAt: 0,
            status: 'complete',
            source: 'ftms',
            protocol: const Value('ftms'),
            imported: const Value(1),
          ),
        ]);
        b.insert(
          old.samples,
          v5.SamplesCompanion.insert(
            sessionId: 1,
            tMs: 60000,
            distanceDm: 2500,
            heartRate: const Value(142),
          ),
        );
      });
      await old.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 7);

      final sessions = await (db.select(
        db.sessions,
      )..orderBy([(s) => OrderingTerm.asc(s.id)])).get();
      expect(sessions.map((s) => (s.protocol, s.distanceDm, s.imported)), [
        (ErgProtocol.pm5, 2500, false),
        (ErgProtocol.ftms, 0, true),
      ]);
      expect((await db.select(db.samples).get()).single.heartRate, 142);
      await expectNoPulseSummary(db);
      await db.close();
    });

    test('keeps the sessions of version 1 without pulse summary', () async {
      final schema = await verifier.schemaAt(1);
      final old = v1.DatabaseAtV1(schema.newConnection());
      await old
          .into(old.sessions)
          .insert(
            v1.SessionsCompanion.insert(
              startedAt: 0,
              status: 'complete',
              source: 'pm5',
              strokeCount: const Value(20),
            ),
          );
      await old.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 7);

      final session = (await db.select(db.sessions).get()).single;
      expect((session.protocol, session.strokeCount), (ErgProtocol.pm5, 20));
      await expectNoPulseSummary(db);
      await db.close();
    });

    test('stores RR intervals and deletes them with their session', () async {
      final db = openTestDatabase();
      final id = await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              startedAt: DateTime(2026, 10, 16),
              status: SessionStatus.complete,
              source: ErgSourceKind.pm5,
            ),
          );
      await db.batch(
        (b) => b.insertAll(db.rrIntervals, [
          RrIntervalsCompanion.insert(sessionId: id, tMs: 800, rrMs: 800),
          RrIntervalsCompanion.insert(sessionId: id, tMs: 1610, rrMs: 810),
        ]),
      );
      expect(
        (await db.select(db.rrIntervals).get()).map((r) => (r.tMs, r.rrMs)),
        [(800, 800), (1610, 810)],
      );

      await (db.delete(db.sessions)..where((s) => s.id.equals(id))).go();
      expect(await db.select(db.rrIntervals).get(), isEmpty);
      await db.close();
    });
  });

  group('to version 7', () {
    test(
      'keeps the sessions of version 6 with their times and no pauses',
      () async {
        final schema = await verifier.schemaAt(6);
        final old = v6.DatabaseAtV6(schema.newConnection());
        await old.batch((b) {
          b.insert(
            old.sessions,
            v6.SessionsCompanion.insert(
              startedAt: 0,
              status: 'complete',
              source: 'pm5',
              durationMs: const Value(90000),
              distanceDm: const Value(2500),
            ),
          );
          b.insert(
            old.samples,
            v6.SamplesCompanion.insert(
              sessionId: 1,
              tMs: 60000,
              distanceDm: 2500,
              wallMs: const Value(90000),
            ),
          );
        });
        await old.close();

        final db = AppDatabase(schema.newConnection());
        await verifier.migrateAndValidate(db, 7);

        final session = (await db.select(db.sessions).get()).single;
        expect(
          (session.durationMs, session.pauseCount, session.pausedMs),
          (90000, 0, 0),
        );
        final sample = (await db.select(db.samples).get()).single;
        expect(
          (sample.tMs, sample.wallMs, sample.activeMs),
          (60000, 90000, null),
        );
        expect(await db.select(db.pauses).get(), isEmpty);
        await db.close();
      },
    );

    test('stores pauses and deletes them with their session', () async {
      final db = openTestDatabase();
      final id = await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              startedAt: DateTime(2026, 10, 18),
              status: SessionStatus.complete,
              source: ErgSourceKind.pm5,
            ),
          );
      await db
          .into(db.pauses)
          .insert(
            PausesCompanion.insert(
              sessionId: id,
              startWallMs: 60000,
              endWallMs: 90000,
            ),
          );
      expect(await db.select(db.pauses).get(), hasLength(1));

      await (db.delete(db.sessions)..where((s) => s.id.equals(id))).go();
      expect(await db.select(db.pauses).get(), isEmpty);
      await db.close();
    });
  });

  group('to version 8', () {
    test(
      'keeps the sessions of version 7 as not written to Health Connect',
      () async {
        final schema = await verifier.schemaAt(7);
        final old = v7.DatabaseAtV7(schema.newConnection());
        await old
            .into(old.sessions)
            .insert(
              v7.SessionsCompanion.insert(
                startedAt: 0,
                status: 'complete',
                source: 'pm5',
                distanceDm: const Value(2500),
              ),
            );
        await old.close();

        final db = AppDatabase(schema.newConnection());
        await verifier.migrateAndValidate(db, 8);

        final session = (await db.select(db.sessions).get()).single;
        expect((session.distanceDm, session.healthExportedAt), (2500, null));
        await db.close();
      },
    );
  });

  group('to version 9', () {
    test(
      'keeps zones and course segments of version 8 without resistance level',
      () async {
        final schema = await verifier.schemaAt(8);
        final old = v8.DatabaseAtV8(schema.newConnection());
        final zone = await old
            .into(old.zones)
            .insert(
              v8.ZonesCompanion.insert(
                name: 'Sprint',
                axis: 'distance',
                length: 100,
                spmMin: const Value(30),
                spmMax: const Value(34),
              ),
            );
        final course = await old
            .into(old.courses)
            .insert(v8.CoursesCompanion.insert(name: 'Kurz', axis: 'distance'));
        final version = await old
            .into(old.courseVersions)
            .insert(
              v8.CourseVersionsCompanion.insert(
                courseId: course,
                version: 1,
                length: 100,
                createdAt: 0,
              ),
            );
        await old
            .into(old.courseSegments)
            .insert(
              v8.CourseSegmentsCompanion.insert(
                versionId: version,
                position: 0,
                length: 100,
                spmMin: const Value(30),
                spmMax: const Value(34),
                zoneId: Value(zone),
                zoneName: const Value('Sprint'),
              ),
            );
        await old.close();

        final db = AppDatabase(schema.newConnection());
        await verifier.migrateAndValidate(db, 9);

        final zoneRow = (await db.select(db.zones).get()).single;
        final segment = (await db.select(db.courseSegments).get()).single;
        expect((zoneRow.name, zoneRow.resistanceLevel), ('Sprint', null));
        expect((segment.zoneName, segment.resistanceLevel), ('Sprint', null));
        await db.close();
      },
    );
  });
  group('to version 11', () {
    test('keeps templates, their blocks and sessions as workouts', () async {
      final schema = await verifier.schemaAt(10);
      final old = v10.DatabaseAtV10(schema.newConnection());
      final course = await old
          .into(old.courses)
          .insert(
            v10.CoursesCompanion.insert(name: 'Seerunde', axis: 'distance'),
          );
      final workout = await old
          .into(old.templates)
          .insert(
            v10.TemplatesCompanion.insert(name: 'Seerunde x3', createdAt: 0),
          );
      await old
          .into(old.templateBlocks)
          .insert(
            v10.TemplateBlocksCompanion.insert(
              templateId: workout,
              position: 0,
              courseId: course,
              laps: const Value(3),
            ),
          );
      await old
          .into(old.sessions)
          .insert(
            v10.SessionsCompanion.insert(
              startedAt: 0,
              status: 'complete',
              source: 'pm5',
              templateId: Value(workout),
              templateName: const Value('Seerunde x3'),
            ),
          );
      await old.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 11);

      final row = (await db.select(db.templates).get()).single;
      final block = (await db.select(db.templateBlocks).get()).single;
      final session = (await db.select(db.sessions).get()).single;
      expect((row.id, row.name), (workout, 'Seerunde x3'));
      expect(
        (block.templateId, block.courseId, block.laps),
        (workout, course, 3),
      );
      expect(
        (session.templateId, session.templateName),
        (workout, 'Seerunde x3'),
      );

      // The foreign keys follow the renamed table: deleting the workout
      // deletes its block and unlinks the session.
      await db.delete(db.templates).go();
      expect(await db.select(db.templateBlocks).get(), isEmpty);
      final unlinked = (await db.select(db.sessions).get()).single;
      expect(
        (unlinked.templateId, unlinked.templateName),
        (null, 'Seerunde x3'),
      );
      await db.close();
    });
  });
}
