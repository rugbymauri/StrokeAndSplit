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
    expect(ftms.toLines(), pm5ToFtms(pm5).toLines());
  });

  test('an FTMS rower rowing like the PM5 ends with the same distance and strokes', () {
    final (original, converted) = (result(pm5), result(ftms));
    expect(ftms.metadata['protocol'], 'ftms');
    expect(converted.distance, closeTo(original.distance, 1));
    expect(converted.strokes, original.strokes);
  });
}
