import 'dart:typed_data';

import 'package:erg_protocol/erg_protocol.dart';
import 'package:test/test.dart';

RowerData? _parse(List<int> bytes) => RowerData.parse(Uint8List.fromList(bytes));

void main() {
  group('reads each flag on its own', () {
    test('bit 0 clear: stroke rate in half strokes and stroke count', () {
      final data = _parse([0x00, 0x00, 45, 0x2A, 0x01])!;
      expect((data.moreData, data.strokeRate, data.strokeCount), (false, 22.5, 298));
    });

    test('bit 0 set: more data follows, without stroke rate and count', () {
      final data = _parse([0x01, 0x00])!;
      expect((data.moreData, data.strokeRate, data.strokeCount), (true, null, null));
    });

    final cases = <String, (int, List<int>, Object? Function(RowerData))>{
      'average stroke rate': (1, [41], (d) => d.averageStrokeRate),
      'total distance': (2, [0xDC, 0x05, 0x01], (d) => d.totalDistance),
      'instantaneous pace': (3, [0x7D, 0x00], (d) => d.pace),
      'average pace': (4, [0x82, 0x00], (d) => d.averagePace),
      'instantaneous power': (5, [0xCB, 0x00], (d) => d.power),
      'average power': (6, [0xFE, 0xFF], (d) => d.averagePower),
      'resistance level': (7, [0x05, 0x00], (d) => d.resistanceLevel),
      'total energy': (8, [0x2C, 0x01, 0xFF, 0xFF, 0xFF], (d) => (d.totalEnergy, d.energyPerHour, d.energyPerMinute)),
      'heart rate': (9, [151], (d) => d.heartRate),
      'metabolic equivalent': (10, [87], (d) => d.metabolicEquivalent),
      'elapsed time': (11, [0x2C, 0x01], (d) => d.elapsedTime),
      'remaining time': (12, [0x3C, 0x00], (d) => d.remainingTime),
    };
    final expected = <String, Object?>{
      'average stroke rate': 20.5,
      'total distance': 67036,
      'instantaneous pace': const Duration(seconds: 125),
      'average pace': const Duration(seconds: 130),
      'instantaneous power': 203,
      'average power': -2,
      'resistance level': 5,
      'total energy': (300, 0xFFFF, 0xFF),
      'heart rate': 151,
      'metabolic equivalent': 8.7,
      'elapsed time': const Duration(seconds: 300),
      'remaining time': const Duration(seconds: 60),
    };
    for (final MapEntry(key: name, value: (bit, bytes, read)) in cases.entries) {
      test('bit $bit: $name', () {
        final flags = 1 | 1 << bit;
        final data = _parse([flags & 0xFF, flags >> 8, ...bytes])!;
        expect(read(data), expected[name]);
        // Only this field is present.
        expect(data.strokeCount, isNull);
      });
    }
  });

  test('reads a typical record in the order of the specification', () {
    // Stroke rate/count, distance, pace, power, energy, heart rate, time.
    const flags = 1 << 2 | 1 << 3 | 1 << 5 | 1 << 8 | 1 << 9 | 1 << 11;
    final data = _parse([
      flags & 0xFF, flags >> 8, //
      44, 0x64, 0x00, // 22 spm, stroke 100
      0xE8, 0x03, 0x00, // 1000 m
      0x78, 0x00, // 2:00
      0xCB, 0x00, // 203 W
      0x32, 0x00, 0xFF, 0xFF, 0xFF, // 50 kcal
      140, // bpm
      0xF0, 0x00, // 240 s
    ])!;
    expect(data.strokeRate, 22);
    expect(data.strokeCount, 100);
    expect(data.totalDistance, 1000);
    expect(data.pace, const Duration(minutes: 2));
    expect(data.power, 203);
    expect(data.totalEnergy, 50);
    expect(data.heartRate, 140);
    expect(data.elapsedTime, const Duration(seconds: 240));
    expect(data.averagePace, isNull);
  });

  test('reads the second part of a split record', () {
    const flags = 1 | 1 << 9 | 1 << 11;
    final data = _parse([flags & 0xFF, flags >> 8, 150, 0x0A, 0x00])!;
    expect((data.moreData, data.heartRate, data.elapsedTime), (true, 150, const Duration(seconds: 10)));
  });

  group('rejects packets shorter than their flags announce', () {
    test('no flags', () => expect(_parse([0x00]), isNull));
    test('stroke count cut off', () => expect(_parse([0x00, 0x00, 44, 0x01]), isNull));
    test('distance cut off', () => expect(_parse([0x05, 0x00, 0xE8, 0x03]), isNull));
    test('energy cut off', () => expect(_parse([0x01, 0x01, 0x32, 0x00, 0xFF]), isNull));
  });

  test('ignores bytes after the announced fields', () {
    expect(_parse([0x01, 0x00, 0x99])?.moreData, isTrue);
  });
}
