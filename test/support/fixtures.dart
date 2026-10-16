import 'dart:io';

import 'package:erg_protocol/erg_protocol.dart';

/// A real PM5 recording from `packages/erg_protocol/test/fixtures`.
RawRecording loadFixture(String name) =>
    RawRecording.parseLines(File('packages/erg_protocol/test/fixtures/$name.jsonl').readAsLinesSync());

List<StatusTick> decodeTicks(Iterable<RawPacket> packets) {
  final decoder = Pm5Decoder();
  return [for (final p in packets) ...decoder.decode(p), ...decoder.flush()].whereType<StatusTick>().toList();
}
