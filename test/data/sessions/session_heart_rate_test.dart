import 'package:aergrow/data/sessions/session_accumulator.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';

const _strap = HeartRateEncoder();

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
}
