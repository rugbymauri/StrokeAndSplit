import '../pm5/pm5_decoder.dart';
import '../raw_recording.dart';
import '../rowing_event.dart';
import 'ftms_encoder.dart';

/// Turns a PM5 recording into the recording of an FTMS rower that rowed the
/// same: one Rower Data record per second, plus one at the end, with the
/// PM5's stroke count, distance, pace, power, energy and time (Design D11).
///
/// Used for the software rower under `tool/ftms_rower/` and as test fixture.
RawRecording pm5ToFtms(RawRecording pm5, {Duration interval = const Duration(seconds: 1)}) {
  const encoder = FtmsEncoder();
  final decoder = Pm5Decoder();

  final records = <({Duration at, StatusTick tick, int strokes})>[];
  var strokes = 0;
  StatusTick? last;
  Duration? lastAt;
  Duration? lastRecord;
  for (final packet in pm5.packets) {
    for (final event in decoder.decode(packet)) {
      switch (event) {
        case Stroke(:final strokeNumber):
          strokes = strokeNumber;
        case WorkoutStateChanged(isReset: true):
          strokes = 0;
        case StatusTick():
          last = event;
          lastAt = packet.time;
          final previous = lastRecord;
          if (previous == null || packet.time - previous >= interval) {
            lastRecord = packet.time;
            records.add((at: packet.time, tick: event, strokes: strokes));
          }
        case WorkoutStateChanged() || HeartBeatIntervals() || StrokeForceCurve():
          break;
      }
    }
  }
  final (finalTick, finalAt) = (last, lastAt);
  if (finalTick != null && finalAt != null && finalAt != lastRecord) {
    records.add((at: finalAt, tick: finalTick, strokes: strokes));
  }

  return RawRecording(
    metadata: {
      'format': RawRecording.formatName,
      'version': 1,
      'source': 'ftms',
      'protocol': 'ftms',
      'device': 'Stroke & Split FTMS',
      'recordedAt': ?pm5.metadata['recordedAt'],
      'convertedFrom': ?pm5.metadata['device'],
    },
    packets: [for (final r in records) encoder.encodeStatus(r.tick, strokeCount: r.strokes, at: r.at)],
  );
}
