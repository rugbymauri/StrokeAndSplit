import 'package:erg_protocol/erg_protocol.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  final pm5 = loadFixture('just_row');
  final ftms = loadFixture('ftms_just_row');

  ({double distance, int strokes}) result(RawRecording recording) {
    final decoder = ErgDecoder.forProtocol(ErgProtocol.parse(recording.metadata['protocol']));
    final events = [for (final p in recording.packets) ...decoder.decode(p), ...decoder.flush()];
    return (
      distance: events.whereType<StatusTick>().last.distanceMeters,
      strokes: events.whereType<Stroke>().last.strokeNumber,
    );
  }

  test('the FTMS fixture is the converted PM5 fixture', () {
    final converted = pm5ToFtms(pm5);
    // The fixture keeps the format name from before the rename.
    expect({...ftms.metadata}..remove('format'), {...converted.metadata}..remove('format'));
    expect(ftms.toLines().skip(1), converted.toLines().skip(1));
  });

  test('an FTMS rower rowing like the PM5 ends with the same distance and strokes', () {
    final (original, converted) = (result(pm5), result(ftms));
    expect(ftms.metadata['protocol'], 'ftms');
    expect(converted.distance, closeTo(original.distance, 1));
    expect(converted.strokes, original.strokes);
  });
}
