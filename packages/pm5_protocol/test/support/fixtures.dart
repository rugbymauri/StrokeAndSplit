import 'dart:io';

import 'package:pm5_protocol/pm5_protocol.dart';

RawRecording loadFixture(String name) =>
    RawRecording.parseLines(File('test/fixtures/$name.jsonl').readAsLinesSync());

List<RowingEvent> decodeAll(Iterable<RawPacket> packets, {List<String>? warnings}) {
  final decoder = Pm5Decoder(onWarning: warnings?.add);
  return [for (final p in packets) ...decoder.decode(p), ...decoder.flush()];
}

int countPackets(RawRecording recording, String characteristicId) =>
    recording.packets.where((p) => p.characteristicId == characteristicId).length;
