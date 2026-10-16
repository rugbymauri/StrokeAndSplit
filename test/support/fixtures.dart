import 'dart:io';

import 'package:erg_protocol/erg_protocol.dart';

/// A real PM5 recording from `packages/erg_protocol/test/fixtures`.
RawRecording loadFixture(String name) =>
    RawRecording.parseLines(File('packages/erg_protocol/test/fixtures/$name.jsonl').readAsLinesSync());

List<StatusTick> decodeTicks(Iterable<RawPacket> packets) {
  final decoder = Pm5Decoder();
  return [for (final p in packets) ...decoder.decode(p), ...decoder.flush()].whereType<StatusTick>().toList();
}

/// One minute (by default) of rowing on an FTMS rower: one Rower Data record
/// per second at 2:05 per 500 m and 24 strokes per minute, starting at
/// [startDistance] metres.
List<RawPacket> ftmsRowing({int seconds = 60, int startDistance = 0, int startStrokes = 0}) {
  const encoder = FtmsEncoder();
  const pace = Duration(minutes: 2, seconds: 5);
  return [
    for (var s = 0; s <= seconds; s++)
      encoder.encode(
        RowerData(
          strokeRate: 24,
          strokeCount: startStrokes + s * 2 ~/ 5,
          totalDistance: startDistance + s * 4,
          pace: pace,
          power: 179,
          totalEnergy: s ~/ 6,
          energyPerHour: RowerData.energyNotAvailable,
          energyPerMinute: 0xFF,
          elapsedTime: Duration(seconds: s),
        ),
        at: Duration(seconds: s),
      ),
  ];
}
