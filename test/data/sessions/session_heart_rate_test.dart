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
List<RawPacket> _ftmsWithStrap(List<(int, List<int>)> measurements) =>
    _withStrap(ftmsRowing(seconds: measurements.length), measurements);

List<RawPacket> _withStrap(
  List<RawPacket> rowing,
  List<(int, List<int>)> measurements,
) {
  final strap = [
    for (final (s, (heartRate, intervals)) in measurements.indexed)
      _strap.encode(
        heartRate: heartRate,
        intervalsMs: intervals,
        at: Duration(milliseconds: s * 1000 + 500),
      ),
  ];
  return [...rowing, ...strap]..sort((a, b) => a.time.compareTo(b.time));
}

void main() {
  group('RR intervals', () {
    test('stores each interval of a measurement at the time it ended', () {
      final accumulator = SessionAccumulator(1, protocol: ErgProtocol.ftms);
      final rowing = ftmsRowing(seconds: 2);
      accumulator
        ..add(rowing[0])
        ..add(rowing[1])
        ..add(
          _strap.encode(
            heartRate: 75,
            intervalsMs: [800, 810],
            at: const Duration(milliseconds: 1500),
          ),
        )
        ..add(rowing[2])
        ..finish();

      final rows = accumulator.takeBatch().rrIntervals;

      expect(rows.map((r) => (r.sessionId.value, r.tMs.value, r.rrMs.value)), [
        (1, 690, 800),
        (1, 1500, 810),
      ]);
    });

    test(
      'places the intervals relative to the first packet of the session',
      () {
        final accumulator = SessionAccumulator(1, protocol: ErgProtocol.ftms);
        for (final packet in ftmsRowing(seconds: 2)) {
          accumulator.add(
            RawPacket(
              time: packet.time + const Duration(seconds: 30),
              characteristicId: packet.characteristicId,
              bytes: packet.bytes,
            ),
          );
        }
        accumulator.add(
          _strap.encode(
            heartRate: 75,
            intervalsMs: [790],
            at: const Duration(seconds: 32),
          ),
        );

        expect(accumulator.takeBatch().rrIntervals.map((r) => r.tMs.value), [
          2000,
        ]);
      },
    );

    test('stores nothing for a measurement without RR intervals', () {
      final accumulator = SessionAccumulator(1, protocol: ErgProtocol.ftms)
        ..add(ftmsRowing(seconds: 0).single)
        ..add(
          _strap.encode(heartRate: 75, at: const Duration(milliseconds: 500)),
        );

      expect(accumulator.takeBatch().rrIntervals, isEmpty);
    });
  });

  group('pulse summary', () {
    test('RMSSD of 800, 810 and 790 ms is 16 ms', () {
      expect(rmssd([800, 810, 790]), 16);
    });

    test('RMSSD needs at least two intervals', () {
      expect(rmssd([]), isNull);
      expect(rmssd([800]), isNull);
      expect(rmssd([800, 800]), 0);
    });

    test(
      'a session with strap has average and maximum pulse and RMSSD',
      () async {
        final session = await _record(
          _ftmsWithStrap([
            (140, [800]),
            (150, [810]),
            (151, [790]),
          ]),
        );

        // The tick at 0 s comes before the first measurement and has no pulse.
        expect(
          (session.averageHeartRate, session.maxHeartRate, session.rmssdMs),
          (147, 151, 16),
        );
      },
    );

    test('a session with pulse only from the PM5 has no RMSSD', () async {
      final session = await _record(
        _pm5Rowing([120, 130, null, 141]),
        protocol: ErgProtocol.pm5,
      );

      expect(
        (session.averageHeartRate, session.maxHeartRate, session.rmssdMs),
        (130, 141, null),
      );
    });

    test('a session without pulse has no pulse summary', () async {
      final session = await _record(ftmsRowing(seconds: 10));

      expect(
        (session.averageHeartRate, session.maxHeartRate, session.rmssdMs),
        (null, null, null),
      );
      expect(session.distanceDm, 400);
    });
  });

  group('export and import', () {
    const measurements = [
      (140, [800]),
      (150, [810, 790]),
      (151, [820]),
      (149, [805]),
    ];

    final sessions = {
      ErgProtocol.pm5: _withStrap(
        _pm5Rowing([120, 121, 122, 123, 124]),
        measurements,
      ),
      ErgProtocol.ftms: _ftmsWithStrap(measurements),
    };

    for (final MapEntry(key: protocol, value: packets) in sessions.entries) {
      test(
        'keep pulse, RR intervals and summary of a ${protocol.name} session with strap',
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
          expect(header['session'], containsPair('rmssdMs', original.rmssdMs));
          expect(
            header['session'],
            containsPair('averageHeartRate', original.averageHeartRate),
          );
          expect(header['session'], containsPair('maxHeartRate', 151));
          expect(
            (copy.averageHeartRate, copy.maxHeartRate, copy.rmssdMs),
            (
              original.averageHeartRate,
              original.maxHeartRate,
              original.rmssdMs,
            ),
          );
          expect(copy.rmssdMs, isNotNull);

          Future<List<int?>> pulse(AppDatabase db, int id) async => [
            for (final s in await (db.select(
              db.samples,
            )..where((s) => s.sessionId.equals(id))).get())
              s.heartRate,
          ];
          Future<List<(int, int)>> rr(AppDatabase db, int id) async => [
            for (final r in await (db.select(
              db.rrIntervals,
            )..where((r) => r.sessionId.equals(id))).get())
              (r.tMs, r.rrMs),
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
          expect(await rr(phoneDb, recorded), [
            (500, 800),
            (710, 810),
            (1500, 790),
            (2500, 820),
            (3500, 805),
          ]);
          expect(await rr(laptopDb, imported), await rr(phoneDb, recorded));
        },
      );
    }
  });
}
