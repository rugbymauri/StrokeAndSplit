import 'package:strokesplit/data/db/database.dart';

import 'dart:convert';
import 'dart:io';

import 'package:strokesplit/data/sessions/session_accumulator.dart';
import 'package:strokesplit/data/sessions/session_repository.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

const _strap = HeartRateEncoder();

/// One minute of rowing on a PM5 with its own heart rate: [heartRates], one
/// per second, starting at the first second.
List<RawPacket> _pm5Rowing(List<int?> heartRates) => [
  for (final (s, heartRate) in heartRates.indexed)
    ...const Pm5Encoder().encodeStatus(
      StatusTick(
        elapsed: Duration(seconds: s),
        distanceMeters: s * 4.0,
        workoutType: WorkoutType.justRowNoSplits,
        workoutState: WorkoutState.workoutRow,
        isRowing: true,
        pace: const Duration(minutes: 2, seconds: 5),
        strokeRate: 24,
        heartRate: heartRate,
      ),
      at: Duration(seconds: s),
    ),
];

/// Records [packets] as a finished session.
Future<SessionRow> _record(
  List<RawPacket> packets, {
  ErgProtocol protocol = ErgProtocol.ftms,
}) async {
  final repository = SessionRepository(openTestDatabase());
  return (await repository.get(
    await _recordIn(repository, packets, protocol: protocol),
  ))!;
}

Future<int> _recordIn(
  SessionRepository repository,
  List<RawPacket> packets, {
  required ErgProtocol protocol,
}) async {
  final id = await repository.create(
    startedAt: DateTime.utc(2026, 10, 16, 7),
    source: ErgSourceKind.values.byName(protocol.name),
    protocol: protocol,
  );
  final accumulator = SessionAccumulator(id, protocol: protocol);
  packets.forEach(accumulator.add);
  accumulator.finish();
  await repository.write(accumulator.takeBatch());
  await repository.finish(id);
  return id;
}

/// FTMS rowing with a strap that measures once per second from 0.5 s on.
List<RawPacket> _ftmsWithStrap(List<int> heartRates) =>
    _withStrap(ftmsRowing(seconds: heartRates.length), heartRates);

List<RawPacket> _withStrap(List<RawPacket> rowing, List<int> heartRates) {
  final strap = [
    for (final (s, heartRate) in heartRates.indexed)
      _strap.encode(
        heartRate: heartRate,
        at: Duration(milliseconds: s * 1000 + 500),
      ),
  ];
  return [...rowing, ...strap]..sort((a, b) => a.time.compareTo(b.time));
}

/// [bytes] of an export with [extra] added to the session block of its
/// header, as a file of an earlier version would have it.
List<int> _withSessionHeader(List<int> bytes, Map<String, Object?> extra) {
  final lines = const LineSplitter().convert(utf8.decode(gzip.decode(bytes)));
  final header = jsonDecode(lines.first) as Map<String, Object?>;
  (header['session']! as Map<String, Object?>).addAll(extra);
  return gzip.encode(
    utf8.encode([jsonEncode(header), ...lines.skip(1)].join('\n')),
  );
}

void main() {
  group('pulse summary', () {
    test('a session with strap has average and maximum pulse', () async {
      final session = await _record(_ftmsWithStrap([140, 150, 151]));

      // The tick at 0 s comes before the first measurement and has no pulse.
      expect((session.averageHeartRate, session.maxHeartRate), (147, 151));
    });

    test(
      'a session with pulse only from the PM5 has a pulse summary',
      () async {
        final session = await _record(
          _pm5Rowing([120, 130, null, 141]),
          protocol: ErgProtocol.pm5,
        );

        expect((session.averageHeartRate, session.maxHeartRate), (130, 141));
      },
    );

    test('a session without pulse has no pulse summary', () async {
      final session = await _record(ftmsRowing(seconds: 10));

      expect((session.averageHeartRate, session.maxHeartRate), (null, null));
      expect(session.distanceDm, 400);
    });
  });

  group('export and import', () {
    const heartRates = [140, 150, 151, 149];

    final sessions = {
      ErgProtocol.pm5: _withStrap(
        _pm5Rowing([120, 121, 122, 123, 124]),
        heartRates,
      ),
      ErgProtocol.ftms: _ftmsWithStrap(heartRates),
    };

    for (final MapEntry(key: protocol, value: packets) in sessions.entries) {
      test(
        'keep pulse and summary of a ${protocol.name} session with strap',
        () async {
          final phoneDb = openTestDatabase();
          final laptopDb = openTestDatabase();
          final phone = SessionRepository(phoneDb);
          final laptop = SessionRepository(laptopDb);
          final recorded = await _recordIn(phone, packets, protocol: protocol);

          final bytes = await phone.export(recorded);
          final imported = await laptop.import(bytes);

          final header = jsonDecode(
            const LineSplitter().convert(utf8.decode(gzip.decode(bytes))).first,
          ) as Map;
          final original = (await phone.get(recorded))!;
          final copy = (await laptop.get(imported))!;
          expect(header['session'], isNot(contains('rmssdMs')));
          expect(
            header['session'],
            containsPair('averageHeartRate', original.averageHeartRate),
          );
          expect(header['session'], containsPair('maxHeartRate', 151));
          expect(
            (copy.averageHeartRate, copy.maxHeartRate),
            (original.averageHeartRate, original.maxHeartRate),
          );

          Future<List<int?>> pulse(AppDatabase db, int id) async => [
            for (final s in await (db.select(
              db.samples,
            )..where((s) => s.sessionId.equals(id))).get())
              s.heartRate,
          ];
          // The strap wins over the PM5 from its first measurement on.
          expect(await pulse(phoneDb, recorded), [
            if (protocol == ErgProtocol.pm5) 120 else null,
            140,
            150,
            151,
            149,
          ]);
          expect(
            await pulse(laptopDb, imported),
            await pulse(phoneDb, recorded),
          );
        },
      );
    }

    test(
      'imports a file of an earlier version with RMSSD in its header',
      () async {
        final phone = SessionRepository(openTestDatabase());
        final laptop = SessionRepository(openTestDatabase());
        final recorded = await _recordIn(
          phone,
          _ftmsWithStrap(heartRates),
          protocol: ErgProtocol.ftms,
        );
        final bytes = _withSessionHeader(await phone.export(recorded), {
          'rmssdMs': 16,
        });

        final copy = (await laptop.get(await laptop.import(bytes)))!;
        final original = (await phone.get(recorded))!;
        expect(
          (copy.averageHeartRate, copy.maxHeartRate, copy.distanceDm),
          (
            original.averageHeartRate,
            original.maxHeartRate,
            original.distanceDm,
          ),
        );
      },
    );
  });
}
