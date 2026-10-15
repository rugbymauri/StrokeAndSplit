import 'dart:convert';
import 'dart:io';

import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/sessions/session_accumulator.dart';
import 'package:aergrow/data/sessions/session_repository.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm5_protocol/pm5_protocol.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

/// The summary without the fields that differ between two copies.
Map<String, Object?> _summary(SessionRow s) => {
      'startedAt': s.startedAt,
      'endedAt': s.endedAt,
      'status': s.status,
      'source': s.source,
      'deviceName': s.deviceName,
      'durationMs': s.durationMs,
      'distanceDm': s.distanceDm,
      'averagePaceCs': s.averagePaceCs,
      'averageWatts': s.averageWatts,
      'averageStrokeRate': s.averageStrokeRate,
      'strokeCount': s.strokeCount,
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
  }

  test('writes a gzip-compressed AergRow raw recording with the summary in the header', () async {
    final repository = SessionRepository(openTestDatabase());
    final id = await _record(repository, 'just_row');

    final lines = const LineSplitter().convert(utf8.decode(gzip.decode(await repository.export(id))));
    final header = jsonDecode(lines.first) as Map<String, Object?>;

    expect(header['format'], 'aergrow-raw');
    expect(header['source'], 'pm5');
    expect(header['device'], 'PM5 430000001 Row');
    expect((header['session'] as Map)['distanceDm'], (await repository.get(id))!.distanceDm);
  });

  test('imports an uncompressed raw recording, e.g. from the spike', () async {
    final repository = SessionRepository(openTestDatabase());
    final file = File('packages/pm5_protocol/test/fixtures/just_row.jsonl');

    final id = await repository.import(await file.readAsBytes());
    final session = (await repository.get(id))!;

    expect(session.status, SessionStatus.complete);
    expect(session.deviceName, 'PM5 430000001 Row');
    expect(session.startedAt.isAtSameMomentAs(DateTime.parse('2026-10-15T20:31:33Z')), isTrue);
    expect(session.distanceDm, greaterThan(0));
  });

  test('keeps an incomplete session incomplete', () async {
    final phone = SessionRepository(openTestDatabase());
    final laptop = SessionRepository(openTestDatabase());
    final id = await phone.create(startedAt: DateTime.utc(2026, 10, 15), source: ErgSourceKind.simulator);
    await phone.finish(id, status: SessionStatus.incomplete);

    final imported = await laptop.import(await phone.export(id));

    expect((await laptop.get(imported))!.status, SessionStatus.incomplete);
  });

  test('rejects files that are not AergRow recordings', () async {
    final repository = SessionRepository(openTestDatabase());

    expect(() => repository.import(utf8.encode('{"format":"other"}\n')), throwsFormatException);
  });
}
