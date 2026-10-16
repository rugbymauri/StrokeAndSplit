import 'dart:typed_data';

/// One BLE notification as received from a PM5 (or produced by the simulator).
class RawPacket {
  RawPacket({required this.time, required this.characteristicId, required List<int> bytes})
      : bytes = Uint8List.fromList(bytes);

  /// Receive time relative to the start of the recording.
  final Duration time;

  /// Short characteristic id as four hex digits, e.g. `0031`.
  final String characteristicId;

  final Uint8List bytes;

  @override
  String toString() => 'RawPacket($characteristicId @ ${time.inMilliseconds} ms, ${bytes.length} bytes)';
}
