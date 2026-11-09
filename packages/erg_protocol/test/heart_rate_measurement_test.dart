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
    });

    test('reads a uint16 heart rate', () {
      final m = _parse([0x01, 0x2C, 0x01])!;
      expect(m.heartRate, 300);
    });

    test('ignores the sensor contact bits', () {
      expect(_parse([0x06, 70])!.heartRate, 70);
    });

    test('skips Energy Expended', () {
      final m = _parse([0x08, 142, 0x34, 0x12])!;
      expect(m.heartRate, 142);
    });

    test('reads the heart rate before RR intervals', () {
      expect(_parse([0x10, 142, 0x40, 0x03, 0x29, 0x03])!.heartRate, 142);
    });

    test('reads a uint16 heart rate with Energy Expended and RR intervals', () {
      expect(_parse([0x19, 142, 0x00, 0x34, 0x12, 0x00, 0x04])!.heartRate, 142);
    });

    test('reads a uint8 heart rate with Energy Expended and RR intervals', () {
      final m = _parse([0x18, 142, 0x34, 0x12, 0x00, 0x04, 0x00, 0x03])!;
      expect(m.heartRate, 142);
    });

    test('accepts the RR flag without any interval', () {
      final m = _parse([0x10, 142])!;
      expect(m.heartRate, 142);
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

    for (final (name, heartRate, wide, energy) in [
      ('uint8', 142, false, null),
      ('uint16', 142, true, null),
      ('uint16 above 255', 300, false, null),
      ('Energy Expended', 98, false, 1234),
    ]) {
      test('round trips $name', () {
        final packet = encoder.encode(
          heartRate: heartRate,
          wide: wide,
          energyExpended: energy,
          at: Duration.zero,
        );
        expect(HeartRateMeasurement.parse(packet.bytes)!.heartRate, heartRate);
      });
    }
  });
}
