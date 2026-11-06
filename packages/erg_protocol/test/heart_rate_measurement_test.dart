import 'dart:typed_data';

import 'package:erg_protocol/erg_protocol.dart';
import 'package:test/test.dart';

HeartRateMeasurement? _parse(List<int> bytes) =>
    HeartRateMeasurement.parse(Uint8List.fromList(bytes));

void main() {
  group('parse', () {
    test('reads a uint8 heart rate', () {
      final m = _parse([0x00, 142])!;
      expect(m.heartRate, 142);
      expect(m.intervalsMs, isEmpty);
    });

    test('reads a uint16 heart rate', () {
      final m = _parse([0x01, 0x2C, 0x01])!;
      expect(m.heartRate, 300);
      expect(m.intervalsMs, isEmpty);
    });

    test('ignores the sensor contact bits', () {
      expect(_parse([0x06, 70])!.heartRate, 70);
    });

    test('skips Energy Expended', () {
      final m = _parse([0x08, 142, 0x34, 0x12])!;
      expect(m.heartRate, 142);
      expect(m.intervalsMs, isEmpty);
    });

    test('converts RR intervals from 1/1024 s to rounded milliseconds', () {
      // 832/1024 s = 812.5 ms, 809/1024 s = 790.04 ms.
      final m = _parse([0x10, 142, 0x40, 0x03, 0x29, 0x03])!;
      expect(m.heartRate, 142);
      expect(m.intervalsMs, [813, 790]);
    });

    test('reads every field with a uint16 heart rate, Energy Expended and RR intervals', () {
      final m = _parse([0x19, 142, 0x00, 0x34, 0x12, 0x00, 0x04])!;
      expect(m.heartRate, 142);
      expect(m.intervalsMs, [1000]);
    });

    test('reads RR intervals after a uint8 heart rate and Energy Expended', () {
      final m = _parse([0x18, 142, 0x34, 0x12, 0x00, 0x04, 0x00, 0x03])!;
      expect(m.intervalsMs, [1000, 750]);
    });

    test('accepts the RR flag without any interval', () {
      final m = _parse([0x10, 142])!;
      expect(m.heartRate, 142);
      expect(m.intervalsMs, isEmpty);
    });
  });

  group('cut off packets', () {
    for (final (name, bytes) in [
      ('empty', <int>[]),
      ('no heart rate', [0x00]),
      ('half a uint16 heart rate', [0x01, 0x8E]),
      ('half of Energy Expended', [0x08, 142, 0x34]),
      ('no Energy Expended', [0x18, 142]),
      ('half an RR interval', [0x10, 142, 0x40]),
      ('a cut off second RR interval', [0x10, 142, 0x40, 0x03, 0x29]),
    ]) {
      test('yield null: $name', () => expect(_parse(bytes), isNull));
    }
  });

  group('HeartRateEncoder', () {
    const encoder = HeartRateEncoder();

    test('writes a Heart Rate Measurement of the strap', () {
      final packet = encoder.encode(
        heartRate: 142,
        at: const Duration(seconds: 3),
      );
      expect(packet.characteristicId, HeartRateIds.measurement);
      expect(packet.time, const Duration(seconds: 3));
      expect(packet.bytes, [0x00, 142]);
    });

    for (final (name, heartRate, wide, energy, intervals) in [
      ('uint8 without RR', 142, false, null, <int>[]),
      ('uint8 with RR', 142, false, null, [812, 790]),
      ('uint16 with RR', 142, true, null, [812]),
      ('uint16 above 255', 300, false, null, <int>[]),
      ('Energy Expended and RR', 98, false, 1234, [1200, 1180, 1215]),
    ]) {
      test('round trips $name', () {
        final packet = encoder.encode(
          heartRate: heartRate,
          wide: wide,
          energyExpended: energy,
          intervalsMs: intervals,
          at: Duration.zero,
        );
        final m = HeartRateMeasurement.parse(packet.bytes)!;
        expect(m.heartRate, heartRate);
        expect(m.intervalsMs, intervals);
      });
    }

    test('round trips every RR interval from 250 to 2000 ms exactly', () {
      final intervals = [for (var ms = 250; ms <= 2000; ms++) ms];
      for (var i = 0; i < intervals.length; i += 8) {
        final chunk = intervals.sublist(i, (i + 8).clamp(0, intervals.length));
        final packet = encoder.encode(
          heartRate: 60,
          intervalsMs: chunk,
          at: Duration.zero,
        );
        expect(HeartRateMeasurement.parse(packet.bytes)!.intervalsMs, chunk);
      }
    });
  });
}
