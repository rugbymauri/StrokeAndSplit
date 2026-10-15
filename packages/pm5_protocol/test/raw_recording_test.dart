import 'package:pm5_protocol/pm5_protocol.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  test('reads packets, markers and metadata of a recording', () {
    final recording = loadFixture('pause');

    expect(recording.metadata['device'], 'PM5 430000001 Row');
    expect(recording.packets, hasLength(2848));
    expect(recording.markers.map((m) => m.text), ['Stopp Rudern', 'Weiter']);
  });

  test('writes the same lines it read', () {
    final recording = loadFixture('pause');
    final reread = RawRecording.parseLines(recording.toLines());

    expect(reread.toLines(), orderedEquals(recording.toLines()));
  });

  test('rejects files that are not AergRow recordings', () {
    expect(() => RawRecording.parseLines(['{"format":"other"}']), throwsFormatException);
    expect(() => RawRecording.parseLines([]), throwsFormatException);
  });
}
