import 'dart:io';

import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/replay_source.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm5_protocol/pm5_protocol.dart';

final _recording = RawRecording.parseLines(
    File('packages/pm5_protocol/test/fixtures/just_row.jsonl').readAsLinesSync());

List<String> _decode(Iterable<RawPacket> packets) {
  final decoder = Pm5Decoder();
  return [for (final p in packets) ...decoder.decode(p), ...decoder.flush()].map((e) => e.toString()).toList();
}

void main() {
  test('replays to the same events as decoding the recording directly', () {
    fakeAsync((async) {
      final replayed = <RawPacket>[];
      final source = ReplaySource(_recording);
      source.packets.listen(replayed.add);
      source.start();
      async.elapse(_recording.packets.last.time + const Duration(seconds: 1));

      expect(_decode(replayed), orderedEquals(_decode(_recording.packets)));
      expect(source.kind, ErgSourceKind.replay);
      expect(source.connectionState, ErgConnectionState.disconnected);
    });
  });

  test('keeps the original timing', () {
    fakeAsync((async) {
      final replayed = <RawPacket>[];
      ReplaySource(_recording)
        ..packets.listen(replayed.add)
        ..start();

      async.elapse(const Duration(seconds: 30));

      final expected = _recording.packets.where((p) => p.time <= const Duration(seconds: 30)).length;
      expect(replayed, hasLength(expected));
    });
  });

  test('plays ten times as fast with factor 10', () {
    fakeAsync((async) {
      final replayed = <RawPacket>[];
      var done = false;
      ReplaySource(_recording, speed: 10)
        ..packets.listen(replayed.add, onDone: () => done = true)
        ..start();

      final duration = _recording.packets.last.time;
      async.elapse(duration ~/ 10 - const Duration(seconds: 1));
      expect(done, isFalse);

      async.elapse(const Duration(seconds: 2));
      expect(done, isTrue);
      expect(_decode(replayed), orderedEquals(_decode(_recording.packets)));
    });
  });
}
