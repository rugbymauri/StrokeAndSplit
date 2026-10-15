import 'dart:io';

import 'package:pm5_protocol/pm5_protocol.dart';

/// A real PM5 recording from `packages/pm5_protocol/test/fixtures`.
RawRecording loadFixture(String name) =>
    RawRecording.parseLines(File('packages/pm5_protocol/test/fixtures/$name.jsonl').readAsLinesSync());

List<StatusTick> decodeTicks(Iterable<RawPacket> packets) {
  final decoder = Pm5Decoder();
  return [for (final p in packets) ...decoder.decode(p), ...decoder.flush()].whereType<StatusTick>().toList();
}
