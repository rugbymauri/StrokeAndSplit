import 'dart:convert';
import 'dart:io';

import 'package:erg_protocol/erg_protocol.dart';

/// `dart run erg_protocol:pm5_to_ftms <in> <out>`: turns a PM5 recording
/// (`.jsonl` or `.aergrow`) into an FTMS recording in the raw format.
void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('Usage: dart run erg_protocol:pm5_to_ftms <pm5 recording> <ftms recording>');
    exitCode = 64;
    return;
  }
  final bytes = File(args[0]).readAsBytesSync();
  final isGzip = bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;
  final text = utf8.decode(isGzip ? gzip.decode(bytes) : bytes);
  final pm5 = RawRecording.parseLines(const LineSplitter().convert(text));
  if (ErgProtocol.parse(pm5.metadata['protocol']) != ErgProtocol.pm5) {
    stderr.writeln('${args[0]} is not a PM5 recording');
    exitCode = 65;
    return;
  }
  final ftms = pm5ToFtms(pm5);
  File(args[1]).writeAsStringSync('${ftms.toLines().join('\n')}\n');
  stdout.writeln('${ftms.packets.length} Rower Data records written to ${args[1]}');
}
