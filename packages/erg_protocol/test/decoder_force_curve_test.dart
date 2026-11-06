import 'dart:typed_data';

import 'package:erg_protocol/erg_protocol.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

/// The packets of [recording] without the force curve packet [counter] of
/// stroke [strokeNumber].
List<RawPacket> _without(
  RawRecording recording, {
  required int strokeNumber,
  required int counter,
}) {
  int? lastStroke;
  final packets = <RawPacket>[];
  for (final p in recording.packets) {
    if (p.characteristicId == Pm5Characteristics.strokeData) {
      lastStroke = p.bytes[18] | p.bytes[19] << 8;
    }
    final isRemoved =
        p.characteristicId == Pm5Characteristics.forceCurve &&
        lastStroke == strokeNumber &&
        p.bytes[1] == counter;
    if (!isRemoved) packets.add(p);
  }
  expect(
    packets,
    hasLength(recording.packets.length - 1),
    reason: 'exactly one packet is removed',
  );
  return packets;
}

RawPacket _curvePacket(int total, int counter, List<int> forcesLbf) {
  final bytes = Uint8List(2 + 2 * forcesLbf.length)
    ..[0] = total << 4 | forcesLbf.length
    ..[1] = counter;
  for (final (i, f) in forcesLbf.indexed) {
    bytes[2 + 2 * i] = f & 0xff;
    bytes[3 + 2 * i] = f >> 8;
  }
  return RawPacket(
    time: Duration.zero,
    characteristicId: Pm5Characteristics.forceCurve,
    bytes: bytes,
  );
}

void main() {
  final recording = loadFixture('force_curve');
  final warnings = <String>[];
  final events = decodeAll(recording.packets, warnings: warnings);
  final curves = events.whereType<StrokeForceCurve>().toList();
  final strokes = {
    for (final s in events.whereType<Stroke>()) s.strokeNumber: s,
  };

  test('emits one curve for each of the strokes 2 to 18, none for the strokes 0 and 1', () {
    expect(curves.map((c) => c.strokeNumber), [
      for (var n = 2; n <= 18; n++) n,
    ]);
  });

  test('drops no force curve packet', () {
    expect(warnings, isEmpty);
  });

  test('has the peak force of its stroke, cut to whole pound-force', () {
    for (final curve in curves) {
      final peakTenthsLbf =
          (strokes[curve.strokeNumber]!.peakForceNewtons! /
                  newtonsPerPoundForce *
                  10)
              .round();
      expect(
        (curve.peakNewtons / newtonsPerPoundForce).round(),
        peakTenthsLbf ~/ 10,
        reason: 'stroke ${curve.strokeNumber}',
      );
    }
  });

  test('converts whole pound-force to newtons', () {
    final stroke4 = curves.firstWhere((c) => c.strokeNumber == 4);

    expect(stroke4.forcesNewtons, hasLength(60));
    expect(stroke4.forcesNewtons.take(4), [
      6 * 4.44822,
      6 * 4.44822,
      6 * 4.44822,
      19 * 4.44822,
    ]);
    expect(stroke4.forcesNewtons.last, 0);
  });

  test('carries the drive length of the stroke data before it', () {
    expect(
      curves.firstWhere((c) => c.strokeNumber == 4).driveLengthMeters,
      1.06,
    );
    for (final curve in curves) {
      expect(
        curve.driveLengthMeters,
        strokes[curve.strokeNumber]!.driveLengthMeters,
      );
    }
  });

  test('comes before the stroke event of the same stroke, with the time of the drive end', () {
    for (final curve in curves) {
      final stroke = strokes[curve.strokeNumber]!;
      expect(events.indexOf(curve), lessThan(events.indexOf(stroke)));
      expect(curve.elapsed, stroke.elapsed);
    }
  });

  group('with a packet missing', () {
    for (final (counter, what) in [
      (0, 'the first'),
      (3, 'a middle'),
      (6, 'the last'),
    ]) {
      test(
        'discards the curve when $what packet is missing and continues with the next stroke',
        () {
          final warnings = <String>[];
          final events = decodeAll(
            _without(recording, strokeNumber: 4, counter: counter),
            warnings: warnings,
          );
          final numbers = events.whereType<StrokeForceCurve>().map(
            (c) => c.strokeNumber,
          );

          expect(numbers, [2, 3, for (var n = 5; n <= 18; n++) n]);
          expect(warnings, isNotEmpty);
          expect(
            events.whereType<Stroke>().map((s) => s.strokeNumber),
            contains(4),
          );
        },
      );
    }
  });

  group('built by hand', () {
    final strokeData = const Pm5Encoder().encodeDriveEnd(
      const Stroke(
        elapsed: Duration(seconds: 5),
        strokeNumber: 3,
        distanceMeters: 20,
        peakForceNewtons: 400,
      ),
      at: Duration.zero,
    );

    test('marks a drive length of 0 as missing', () {
      final decoder = Pm5Decoder();
      final events = [
        for (final p in [
          ...strokeData,
          _curvePacket(2, 0, [1, 2, 3, 4, 5, 6, 7, 8, 9]),
          _curvePacket(2, 1, [4]),
        ])
          ...decoder.decode(p),
      ];

      final curve = events.whereType<StrokeForceCurve>().single;
      expect(curve.strokeNumber, 3);
      expect(curve.forcesNewtons, hasLength(10));
      expect(curve.driveLengthMeters, isNull);
    });

    test('discards a curve whose packets announce different totals', () {
      final warnings = <String>[];
      final decoder = Pm5Decoder(onWarning: warnings.add);
      final events = [
        for (final p in [
          ...strokeData,
          _curvePacket(3, 0, [1, 2, 3, 4, 5, 6, 7, 8, 9]),
          _curvePacket(2, 1, [4]),
        ])
          ...decoder.decode(p),
      ];

      expect(events.whereType<StrokeForceCurve>(), isEmpty);
      expect(warnings, hasLength(1));
    });

    test('drops a packet shorter than its values announce', () {
      final warnings = <String>[];
      final decoder = Pm5Decoder(onWarning: warnings.add);
      final short = RawPacket(
        time: Duration.zero,
        characteristicId: Pm5Characteristics.forceCurve,
        bytes: Uint8List.fromList([0x13, 0, 1, 0, 2, 0]),
      );
      final events = [
        for (final p in [...strokeData, short]) ...decoder.decode(p),
      ];

      expect(events.whereType<StrokeForceCurve>(), isEmpty);
      expect(warnings.single, contains('6 bytes for 3 values'));
    });

    test('drops a curve without stroke data before it', () {
      final warnings = <String>[];
      final events = Pm5Decoder(onWarning: warnings.add)
          .decode(_curvePacket(1, 0, [1, 2]));

      expect(events, isEmpty);
      expect(warnings.single, contains('without preceding stroke data'));
    });
  });
}
