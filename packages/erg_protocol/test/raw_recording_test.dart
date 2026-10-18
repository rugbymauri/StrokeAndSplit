import 'package:erg_protocol/erg_protocol.dart';
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

  test('writes the current format name and reads recordings from before the rename', () {
    final recording = loadFixture('just_row');
    final rewritten = RawRecording(metadata: {...recording.metadata, 'format': RawRecording.formatName}, packets: []);

    expect(recording.metadata['format'], 'aergrow-raw');
    expect(RawRecording.formatName, 'strokesplit-raw');
    expect(RawRecording.parseLines(rewritten.toLines()).metadata['format'], 'strokesplit-raw');
  });

  test('rejects files that are not Stroke & Split recordings', () {
    expect(() => RawRecording.parseLines(['{"format":"other"}']), throwsFormatException);
    expect(() => RawRecording.parseLines([]), throwsFormatException);
  });
}
