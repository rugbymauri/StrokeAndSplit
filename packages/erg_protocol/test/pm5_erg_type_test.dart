import 'dart:typed_data';

import 'package:erg_protocol/erg_protocol.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

Uint8List _additionalStatus(int code) => Uint8List(17)..[16] = code;

void main() {
  test('recognises the RowErg of the recorded PM5', () {
    final recording = loadFixture('just_row');
    final status = recording.packets.firstWhere((p) => p.characteristicId == Pm5Characteristics.additionalStatus);
    expect(Pm5ErgType.fromAdditionalStatus(status.bytes), Pm5ErgKind.rowErg);
  });

  test('recognises SkiErg and BikeErg codes', () {
    for (final code in [128, 143, 225]) {
      expect(Pm5ErgType.fromAdditionalStatus(_additionalStatus(code)), Pm5ErgKind.skiErg, reason: '$code');
    }
    for (final code in [192, 193, 194, 207, 226]) {
      expect(Pm5ErgType.fromAdditionalStatus(_additionalStatus(code)), Pm5ErgKind.bikeErg, reason: '$code');
    }
  });

  test('recognises RowErg codes, including slides and the multi-erg rower', () {
    for (final code in [0, 1, 5, 16, 224]) {
      expect(Pm5ErgType.classify(code), Pm5ErgKind.rowErg, reason: '$code');
    }
  });

  test('leaves unknown codes and short packets open', () {
    expect(Pm5ErgType.classify(99), Pm5ErgKind.unknown);
    expect(Pm5ErgType.fromAdditionalStatus(Uint8List(11)), isNull);
  });
}
