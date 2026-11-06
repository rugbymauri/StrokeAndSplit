import 'dart:convert';
import 'dart:io';

import 'package:erg_protocol/erg_protocol.dart';

/// Writes raw notifications of a PM5 or FTMS rower as JSON lines: one header
/// line, then one line per packet (`t`, `c`, `b`) or marker (`t`, `m`).
///
/// This is the uncompressed form of the `.strokesplit` export format, so spike
/// recordings can be used directly as test fixtures.
class RawLogWriter {
  RawLogWriter._(this.file, this._sink, this._clock);

  final File file;
  final IOSink _sink;
  final Stopwatch _clock;
  int packetCount = 0;

  /// [protocol] is `pm5` or `ftms` and names the file, e.g. `ftms-<time>.jsonl`.
  static Future<RawLogWriter> create(
    Directory dir, {
    required String deviceName,
    String protocol = 'pm5',
  }) async {
    final startedAt = DateTime.now();
    final stamp = startedAt
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File('${dir.path}/$protocol-$stamp.jsonl');
    final sink = file.openWrite();
    sink.writeln(
      jsonEncode({
        'format': RawRecording.formatName,
        'version': 1,
        'source': protocol,
        'protocol': protocol,
        'device': deviceName,
        'recordedAt': startedAt.toUtc().toIso8601String(),
      }),
    );
    return RawLogWriter._(file, sink, Stopwatch()..start());
  }

  void packet(String characteristicId, List<int> bytes) {
    packetCount++;
    _sink.writeln(
      jsonEncode({
        't': _clock.elapsedMilliseconds,
        'c': characteristicId,
        'b': base64Encode(bytes),
      }),
    );
  }

  void marker(String text) {
    _sink.writeln(jsonEncode({'t': _clock.elapsedMilliseconds, 'm': text}));
  }

  Future<void> close() async {
    await _sink.flush();
    await _sink.close();
  }
}
