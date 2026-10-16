import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/sessions/session_accumulator.dart';
import 'package:aergrow/data/sessions/session_repository.dart';
import 'package:aergrow/data/sources/erg_source.dart';
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
Future<SessionRow> _record(List<RawPacket> packets, {ErgProtocol protocol = ErgProtocol.ftms}) async {
  final repository = SessionRepository(openTestDatabase());
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
  return (await repository.get(id))!;
}

/// FTMS rowing with a strap that measures once per second from 0.5 s on.
List<RawPacket> _ftmsWithStrap(List<(int, List<int>)> measurements) {
  final strap = [
    for (final (s, (heartRate, intervals)) in measurements.indexed)
      _strap.encode(heartRate: heartRate, intervalsMs: intervals, at: Duration(milliseconds: s * 1000 + 500)),
  ];
  return [...ftmsRowing(seconds: measurements.length), ...strap]..sort((a, b) => a.time.compareTo(b.time));
}

void main() {
  group('RR intervals', () {
    test('stores each interval of a measurement at the time it ended', () {
      final accumulator = SessionAccumulator(1, protocol: ErgProtocol.ftms);
      final rowing = ftmsRowing(seconds: 2);
      accumulator
        ..add(rowing[0])
        ..add(rowing[1])
        ..add(_strap.encode(heartRate: 75, intervalsMs: [800, 810], at: const Duration(milliseconds: 1500)))
        ..add(rowing[2])
        ..finish();

      final rows = accumulator.takeBatch().rrIntervals;

      expect(rows.map((r) => (r.sessionId.value, r.tMs.value, r.rrMs.value)), [(1, 690, 800), (1, 1500, 810)]);
    });

    test('places the intervals relative to the first packet of the session', () {
      final accumulator = SessionAccumulator(1, protocol: ErgProtocol.ftms);
      for (final packet in ftmsRowing(seconds: 2)) {
        accumulator.add(RawPacket(
          time: packet.time + const Duration(seconds: 30),
          characteristicId: packet.characteristicId,
          bytes: packet.bytes,
        ));
      }
      accumulator.add(_strap.encode(heartRate: 75, intervalsMs: [790], at: const Duration(seconds: 32)));

      expect(accumulator.takeBatch().rrIntervals.map((r) => r.tMs.value), [2000]);
    });

    test('stores nothing for a measurement without RR intervals', () {
      final accumulator = SessionAccumulator(1, protocol: ErgProtocol.ftms)
        ..add(ftmsRowing(seconds: 0).single)
        ..add(_strap.encode(heartRate: 75, at: const Duration(milliseconds: 500)));

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

    test('a session with strap has average and maximum pulse and RMSSD', () async {
      final session = await _record(_ftmsWithStrap([
        (140, [800]),
        (150, [810]),
        (151, [790]),
      ]));

      // The tick at 0 s comes before the first measurement and has no pulse.
      expect((session.averageHeartRate, session.maxHeartRate, session.rmssdMs), (147, 151, 16));
    });

    test('a session with pulse only from the PM5 has no RMSSD', () async {
      final session = await _record(_pm5Rowing([120, 130, null, 141]), protocol: ErgProtocol.pm5);

      expect((session.averageHeartRate, session.maxHeartRate, session.rmssdMs), (130, 141, null));
    });

    test('a session without pulse has no pulse summary', () async {
      final session = await _record(ftmsRowing(seconds: 10));

      expect((session.averageHeartRate, session.maxHeartRate, session.rmssdMs), (null, null, null));
      expect(session.distanceDm, 400);
    });
  });
}
