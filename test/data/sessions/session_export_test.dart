import 'dart:convert';
import 'dart:io';

import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_layout.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/sessions/session_accumulator.dart';
import 'package:aergrow/data/sessions/session_repository.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/templates/template_repository.dart';
import 'package:aergrow/data/zones/zone.dart';
import 'package:aergrow/data/zones/zone_repository.dart';
import 'package:aergrow/spike/raw_log_writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

/// The summary without the fields that differ between two copies.
Map<String, Object?> _summary(SessionRow s) => {
      'startedAt': s.startedAt,
      'endedAt': s.endedAt,
      'status': s.status,
      'source': s.source,
      'protocol': s.protocol,
      'deviceName': s.deviceName,
      'durationMs': s.durationMs,
      'distanceDm': s.distanceDm,
      'averagePaceCs': s.averagePaceCs,
      'averageWatts': s.averageWatts,
      'averageStrokeRate': s.averageStrokeRate,
      'strokeCount': s.strokeCount,
      'averageHeartRate': s.averageHeartRate,
      'maxHeartRate': s.maxHeartRate,
      'rmssdMs': s.rmssdMs,
    };

Future<int> _record(SessionRepository repository, String fixture) async {
  final id = await repository.create(
    startedAt: DateTime.utc(2026, 10, 15, 18, 30),
    source: ErgSourceKind.pm5,
    deviceName: 'PM5 430000001 Row',
  );
  final accumulator = SessionAccumulator(id);
  for (final p in loadFixture(fixture).packets) {
    // Live packets carry sub-millisecond times; only milliseconds are stored.
    accumulator.add(RawPacket(
      time: p.time + const Duration(microseconds: 1234),
      characteristicId: p.characteristicId,
      bytes: p.bytes,
    ));
  }
  accumulator.finish();
  await repository.write(accumulator.takeBatch());
  await repository.finish(id, endedAt: DateTime.utc(2026, 10, 15, 19));
  return id;
}

/// The force curves of [recording] as stroke number, drive length and values.
List<String> _curves(RawRecording recording) {
  final decoder = ErgDecoder.forProtocol(ErgProtocol.pm5);
  return [for (final p in recording.packets) ...decoder.decode(p), ...decoder.flush()]
      .whereType<StrokeForceCurve>()
      .map((c) => '${c.strokeNumber} ${c.driveLengthMeters} ${c.forcesNewtons}')
      .toList();
}

void main() {
  for (final fixture in ['just_row', 'pause', 'reset']) {
    test('export and import of $fixture give the same summary', () async {
      final phone = SessionRepository(openTestDatabase());
      final laptop = SessionRepository(openTestDatabase());
      final recorded = await _record(phone, fixture);

      final imported = await laptop.import(await phone.export(recorded));

      expect(_summary((await laptop.get(imported))!), _summary((await phone.get(recorded))!));
      expect((await laptop.rawRecording(imported)).packets.length, (await phone.rawRecording(recorded)).packets.length);
    });

    test('imports the unchanged $fixture fixture as an .aergrow file from before the rename', () async {
      final phone = SessionRepository(openTestDatabase());
      final laptop = SessionRepository(openTestDatabase());
      final recorded = (await phone.get(await _record(phone, fixture)))!;
      final file = File('packages/erg_protocol/test/fixtures/$fixture.jsonl').readAsBytesSync();
      expect(utf8.decode(file), startsWith('{"format":"aergrow-raw"'));

      final imported = (await laptop.get(await laptop.import(gzip.encode(file))))!;

      expect(
        (imported.distanceDm, imported.strokeCount, imported.durationMs),
        (recorded.distanceDm, recorded.strokeCount, recorded.durationMs),
      );
    });
  }

  test('stores the force curve packets and gives the same curves after export and import', () async {
    final phone = SessionRepository(openTestDatabase());
    final laptop = SessionRepository(openTestDatabase());
    final recorded = await _record(phone, 'force_curve');

    final stored = await phone.rawRecording(recorded);
    final imported = await laptop.rawRecording(await laptop.import(await phone.export(recorded)));

    final fixture = loadFixture('force_curve');
    bool isCurve(RawPacket p) => p.characteristicId == Pm5Characteristics.forceCurve;
    expect(stored.packets.where(isCurve).length, fixture.packets.where(isCurve).length);
    expect(_curves(imported), hasLength(17));
    expect(_curves(imported), _curves(stored));
  });

  test('writes a gzip-compressed Stroke & Split raw recording with the summary in the header', () async {
    final repository = SessionRepository(openTestDatabase());
    final id = await _record(repository, 'just_row');

    final lines = const LineSplitter().convert(utf8.decode(gzip.decode(await repository.export(id))));
    final header = jsonDecode(lines.first) as Map<String, Object?>;

    expect(header['format'], 'strokesplit-raw');
    expect(header['source'], 'pm5');
    expect(header['device'], 'PM5 430000001 Row');
    expect((header['session'] as Map)['distanceDm'], (await repository.get(id))!.distanceDm);
  });

  test('imports an uncompressed raw recording, e.g. from the spike', () async {
    final repository = SessionRepository(openTestDatabase());
    final file = File('packages/erg_protocol/test/fixtures/just_row.jsonl');

    final id = await repository.import(await file.readAsBytes());
    final session = (await repository.get(id))!;

    expect(session.status, SessionStatus.complete);
    expect(session.deviceName, 'PM5 430000001 Row');
    // The file is older than FTMS support and names no protocol.
    expect(session.protocol, ErgProtocol.pm5);
    expect(session.startedAt.isAtSameMomentAs(DateTime.parse('2026-10-15T20:31:33Z')), isTrue);
    expect(session.distanceDm, greaterThan(0));
    expect(session.courseVersionId, isNull);
    expect(await repository.laps(id), isEmpty);
  });

  test('imports an FTMS recording of the spike', () async {
    final dir = await Directory.systemTemp.createTemp('aergrow-spike');
    addTearDown(() => dir.delete(recursive: true));
    final writer = await RawLogWriter.create(dir, deviceName: 'AergRow FTMS Rower', protocol: 'ftms');
    await writer.close();
    final header = (await writer.file.readAsLines()).first;
    expect((jsonDecode(header) as Map)['format'], 'strokesplit-raw');
    // The spike also records the control point answers and the machine status.
    final lines = [
      header,
      jsonEncode({'t': 0, 'm': 'Fitness Machine Feature: 26 56 00 00 00 00 00 00'}),
      jsonEncode({'t': 10, 'c': FtmsIds.controlPoint, 'b': base64Encode([0x80, 0x00, 0x01])}),
      jsonEncode({'t': 20, 'c': FtmsIds.machineStatus, 'b': base64Encode([0x04])}),
      ...File('packages/erg_protocol/test/fixtures/ftms_just_row.jsonl').readAsLinesSync().skip(1),
    ];
    final db = openTestDatabase();
    final repository = SessionRepository(db);

    final id = await repository.import(utf8.encode(lines.join('\n')));
    final session = (await repository.get(id))!;

    expect(writer.file.path, contains('ftms-'));
    expect((session.source, session.protocol), (ErgSourceKind.ftms, ErgProtocol.ftms));
    expect(session.deviceName, 'AergRow FTMS Rower');
    expect(session.distanceDm, closeTo(2100, 10));
    expect(await db.select(db.strokes).get(), hasLength(43));
  });

  test('names the protocol in the header and recomputes an FTMS session on import', () async {
    final phone = SessionRepository(openTestDatabase());
    final laptop = SessionRepository(openTestDatabase());
    final id = await phone.create(
      startedAt: DateTime.utc(2026, 10, 16, 7),
      source: ErgSourceKind.ftms,
      protocol: ErgProtocol.ftms,
      deviceName: 'Rower 42',
    );
    final accumulator = SessionAccumulator(id, protocol: ErgProtocol.ftms);
    ftmsRowing(seconds: 120).forEach(accumulator.add);
    accumulator.finish();
    await phone.write(accumulator.takeBatch());
    await phone.finish(id, endedAt: DateTime.utc(2026, 10, 16, 7, 5));

    final bytes = await phone.export(id);
    final header = jsonDecode(const LineSplitter().convert(utf8.decode(gzip.decode(bytes))).first) as Map;
    expect(header['protocol'], 'ftms');

    final imported = await laptop.import(bytes);
    final original = (await phone.get(id))!;
    final copy = (await laptop.get(imported))!;
    expect(_summary(copy), _summary(original));
    expect((copy.protocol, copy.strokeCount, copy.distanceDm), (ErgProtocol.ftms, 48, 4800));
  });

  test('keeps an incomplete session incomplete', () async {
    final phone = SessionRepository(openTestDatabase());
    final laptop = SessionRepository(openTestDatabase());
    final id = await phone.create(startedAt: DateTime.utc(2026, 10, 15), source: ErgSourceKind.simulator);
    await phone.finish(id, status: SessionStatus.incomplete);

    final imported = await laptop.import(await phone.export(id));

    expect((await laptop.get(imported))!.status, SessionStatus.incomplete);
  });

  test('rejects files that are not Stroke & Split recordings', () async {
    final repository = SessionRepository(openTestDatabase());

    expect(() => repository.import(utf8.encode('{"format":"other"}\n')), throwsFormatException);
  });

  group('a session on a course', () {
    const tempo = Zone(name: 'Tempo', axis: CourseAxis.distance, length: 20, paceFastCs: 10000, paceSlowCs: 20000);

    /// A course from before zones: the band belongs to the segment.
    const unzoned = CourseDefinition(axis: CourseAxis.distance, length: 40, segments: [
      CourseSegment(length: 20),
      CourseSegment(length: 20, paceFastCs: 10000, paceSlowCs: 20000, spmMin: 15, spmMax: 40),
    ]);

    /// Records just_row as "Seerunde x3" on the phone, by default on a course
    /// with the zone "Tempo" from 20 to 40 m.
    Future<(AppDatabase, int)> recordOnPhone({CourseDefinition? definition, bool ftms = false}) async {
      final db = openTestDatabase();
      final zoneId = await ZoneRepository(db).create(tempo);
      final course = definition ??
          resolveCourse(
            axis: CourseAxis.distance,
            length: 40,
            placements: [ZonePlacement(zoneId: zoneId, start: 20)],
            zones: {zoneId: tempo.copyWith(id: zoneId)},
          ).definition!;
      final courseId = await CourseRepository(db).create('Seerunde', course);
      final templates = TemplateRepository(db);
      final template = (await templates.get(await templates.create('Seerunde x3', courseId: courseId, laps: 3)))!;
      final repository = SessionRepository(db);
      final id = await repository.create(
        startedAt: DateTime.utc(2026, 10, 16, 7),
        source: ftms ? ErgSourceKind.ftms : ErgSourceKind.pm5,
        protocol: ftms ? ErgProtocol.ftms : ErgProtocol.pm5,
        template: template,
      );
      final protocol = ftms ? ErgProtocol.ftms : ErgProtocol.pm5;
      final accumulator = SessionAccumulator(id, protocol: protocol, course: course, plannedLaps: 3);
      (ftms ? ftmsRowing(seconds: 40) : loadFixture('just_row').packets).forEach(accumulator.add);
      accumulator.finish();
      await repository.write(accumulator.takeBatch());
      await repository.finish(id);
      return (db, id);
    }

    Future<List<Object>> results(AppDatabase db, int id) async => [
          for (final l in await SessionRepository(db).laps(id))
            (l.lapNo, l.startWallMs, l.endWallMs, l.endDistanceDm, l.complete, l.inZoneShare),
          for (final s in await (db.select(db.lapSegments)..where((s) => s.sessionId.equals(id))).get())
            (s.lapNo, s.position, s.durationMs, s.distanceDm, s.inZoneShare),
        ];

    test('gives the same laps after export and import, and creates the missing course and zone', () async {
      final (phone, recorded) = await recordOnPhone();
      final laptop = openTestDatabase();

      final bytes = await SessionRepository(phone).export(recorded);
      final imported = await SessionRepository(laptop).import(bytes);

      expect(await results(laptop, imported), await results(phone, recorded));
      expect((await SessionRepository(laptop).laps(imported)).where((l) => l.complete), hasLength(3));
      final session = (await SessionRepository(laptop).get(imported))!;
      expect((session.templateName, session.plannedLaps, session.templateId), ('Seerunde x3', 3, null));
      final zone = (await ZoneRepository(laptop).all()).single;
      expect(zone.sameAs(tempo), isTrue);
      final course = (await CourseRepository(laptop).all()).single;
      expect(course.name, 'Seerunde');
      expect(course.definition.placements, [ZonePlacement(zoneId: zone.id, start: 20)]);
      expect(course.definition.sameAs((await CourseRepository(phone).all()).single.definition), isTrue);
      expect(course.versionId, session.courseVersionId);
    });

    test('gives the same laps for an FTMS session after export and import', () async {
      final (phone, recorded) = await recordOnPhone(ftms: true);
      final laptop = openTestDatabase();

      final imported = await SessionRepository(laptop).import(await SessionRepository(phone).export(recorded));

      expect(await results(laptop, imported), await results(phone, recorded));
      expect((await SessionRepository(laptop).laps(imported)).where((l) => l.complete), hasLength(3));
      expect((await SessionRepository(laptop).get(imported))!.protocol, ErgProtocol.ftms);
      expect((await ZoneRepository(laptop).all()).single.sameAs(tempo), isTrue);
    });

    test('reuses a course and its zone with the same name and definition', () async {
      final (phone, recorded) = await recordOnPhone();
      final bytes = await SessionRepository(phone).export(recorded);

      final imported = await SessionRepository(phone).import(bytes);

      expect(await CourseRepository(phone).all(), hasLength(1));
      expect(await ZoneRepository(phone).all(), hasLength(1));
      final original = (await SessionRepository(phone).get(recorded))!;
      expect((await SessionRepository(phone).get(imported))!.courseVersionId, original.courseVersionId);
    });

    test('names template, course and zones in the header', () async {
      final (phone, recorded) = await recordOnPhone();

      final bytes = await SessionRepository(phone).export(recorded);
      final lines = const LineSplitter().convert(utf8.decode(gzip.decode(bytes)));
      final header = jsonDecode(lines.first) as Map<String, Object?>;

      expect(header['template'], {'name': 'Seerunde x3', 'laps': 3});
      expect((header['course'] as Map)['segments'], [
        {'length': 20},
        {
          'length': 20,
          'paceFastCs': 10000,
          'paceSlowCs': 20000,
          'zone': {'name': 'Tempo', 'axis': 'distance', 'length': 20, 'paceFastCs': 10000, 'paceSlowCs': 20000},
        },
      ]);
    });

    test('turns the bands of a file from before zones into a zone named after the course', () async {
      final (phone, recorded) = await recordOnPhone(definition: unzoned);
      final laptop = openTestDatabase();

      final bytes = await SessionRepository(phone).export(recorded);
      final imported = await SessionRepository(laptop).import(bytes);

      expect(await results(laptop, imported), await results(phone, recorded));
      final zone = (await ZoneRepository(laptop).all()).single;
      expect((zone.name, zone.length, zone.paceFastCs, zone.spmMax), ('Seerunde 2', 20, 10000, 40));
      expect((await CourseRepository(laptop).all()).single.definition.placements,
          [ZonePlacement(zoneId: zone.id, start: 20)]);
    });
  });
}
