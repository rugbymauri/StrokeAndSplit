import 'package:erg_protocol/erg_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('features', () {
    test('Domyos Woodrower reports and sets the level', () {
      final features = FtmsFeatures.parse([0xa6, 0x56, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00])!;
      expect(features.reportsResistanceLevel, isTrue);
      expect(features.setsResistanceLevel, isTrue);
    });

    test('a rower without target settings sets nothing', () {
      final features = FtmsFeatures.parse([0x26, 0x56, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])!;
      expect(features.reportsResistanceLevel, isFalse);
      expect(features.setsResistanceLevel, isFalse);
    });

    test('too few bytes', () => expect(FtmsFeatures.parse([0xa6, 0x56, 0x00, 0x00]), isNull));
  });

  group('range', () {
    test('Domyos Woodrower: 1 to 15 in steps of 1', () {
      expect(ResistanceRange.parse([0x0a, 0x00, 0x96, 0x00, 0x0a, 0x00]), const ResistanceRange(min: 1, max: 15));
    });

    test('nonsense ranges are dropped', () {
      expect(ResistanceRange.parse([0x0a, 0x00, 0x96, 0x00, 0x00, 0x00]), isNull, reason: 'step 0');
      expect(ResistanceRange.parse([0x96, 0x00, 0x0a, 0x00, 0x0a, 0x00]), isNull, reason: 'min above max');
      expect(ResistanceRange.parse([0xf6, 0xff, 0x96, 0x00, 0x0a, 0x00]), isNull, reason: 'negative');
      expect(ResistanceRange.parse([0x0a, 0x00, 0x96, 0x00]), isNull, reason: 'too short');
    });

    test('clamps into the range and onto its steps', () {
      const range = ResistanceRange(min: 1, max: 15);
      expect(range.clamp(20), 15);
      expect(range.clamp(0), 1);
      expect(range.clamp(7), 7);
      expect(const ResistanceRange(min: 2, max: 10, step: 2).clamp(5), 6);
    });

    test('a level reported in tenths becomes a whole level', () {
      const range = ResistanceRange(min: 1, max: 15);
      expect(range.wholeLevel(60), 6);
      expect(range.wholeLevel(6), 6);
      expect(range.wholeLevel(15), 15);
      expect(range.wholeLevel(17), 17, reason: 'not tenths, left alone');
    });
  });

  group('control point', () {
    test('level 6 is one byte in tenths', () => expect(FtmsControl.setResistanceLevel(6), [0x04, 0x3c]));

    test('level 6 as 16 bits', () => expect(FtmsControl.setResistanceLevel(6, wide: true), [0x04, 0x3c, 0x00]));

    test('a level above 25.5 needs 16 bits', () {
      expect(FtmsControl.needsWide(26), isTrue);
      expect(FtmsControl.setResistanceLevel(30), [0x04, 0x2c, 0x01]);
    });

    test('answers', () {
      expect(FtmsControlResponse.parse([0x80, 0x04, 0x01])!.succeeded, isTrue);
      expect(FtmsControlResponse.parse([0x80, 0x04, 0x03])!.result, FtmsControl.invalidParameter);
      expect(FtmsControlResponse.parse([0x80, 0x00, 0x05])!.requestOpCode, FtmsControl.requestControl);
      expect(FtmsControlResponse.parse([0x80, 0x04]), isNull);
      expect(FtmsControlResponse.parse([0x07, 0x3c]), isNull);
    });
  });
}
