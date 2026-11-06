import 'dart:convert';

import 'raw_packet.dart';

/// A note set during recording, e.g. "Stopp Rudern".
class RecordingMarker {
  const RecordingMarker({required this.time, required this.text});

  final Duration time;
  final String text;
}

/// A recorded stream of PM5 notifications in the Stroke & Split raw format: one
/// JSON header line, then one line per packet (`t`, `c`, `b`) or marker (`t`, `m`).
class RawRecording {
  RawRecording({
    required this.metadata,
    required this.packets,
    this.markers = const [],
  });

  /// Parses the line format. Lines that are neither a packet nor a marker are
  /// ignored so newer files with additional line types stay readable.
  factory RawRecording.parseLines(Iterable<String> lines) {
    final iterator = lines.where((l) => l.trim().isNotEmpty).iterator;
    if (!iterator.moveNext()) {
      throw const FormatException('Recording is empty');
    }
    final metadata = jsonDecode(iterator.current) as Map<String, Object?>;
    if (!readableFormatNames.contains(metadata['format'])) {
      throw FormatException(
        'Not a Stroke & Split recording: ${metadata['format']}',
      );
    }

    final packets = <RawPacket>[];
    final markers = <RecordingMarker>[];
    while (iterator.moveNext()) {
      final line = jsonDecode(iterator.current) as Map<String, Object?>;
      final time = Duration(milliseconds: line['t'] as int);
      if (line case {'c': final String id, 'b': final String bytes}) {
        packets.add(
          RawPacket(
            time: time,
            characteristicId: id,
            bytes: base64Decode(bytes),
          ),
        );
      } else if (line case {'m': final String text}) {
        markers.add(RecordingMarker(time: time, text: text));
      }
    }
    return RawRecording(metadata: metadata, packets: packets, markers: markers);
  }

  /// The format name written into new recordings.
  static const formatName = 'strokesplit-raw';

  /// The format names read: the current one and the one from before the app
  /// was renamed from AergRow, so older exports and recordings stay readable.
  static const readableFormatNames = {formatName, 'aergrow-raw'};

  final Map<String, Object?> metadata;
  final List<RawPacket> packets;
  final List<RecordingMarker> markers;

  Iterable<String> toLines() sync* {
    yield jsonEncode(metadata);
    final lines = [
      for (final p in packets)
        (
          p.time,
          jsonEncode({
            't': p.time.inMilliseconds,
            'c': p.characteristicId,
            'b': base64Encode(p.bytes),
          }),
        ),
      for (final m in markers)
        (m.time, jsonEncode({'t': m.time.inMilliseconds, 'm': m.text})),
    ];
    // Sort by time, keeping the original order of lines with the same time.
    final ordered = [...lines.indexed]
      ..sort((a, b) {
        final byTime = a.$2.$1.compareTo(b.$2.$1);
        return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
      });
    for (final (_, (_, line)) in ordered) {
      yield line;
    }
  }
}
