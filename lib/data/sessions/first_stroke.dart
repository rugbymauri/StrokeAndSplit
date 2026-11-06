import 'package:erg_protocol/erg_protocol.dart';

/// Waits for the first stroke of a session that is ready but not started
/// (start-on-first-stroke, Design D2).
///
/// The last status before the first movement is the base: the session starts
/// with its packets, so time and distance count from there and nothing of the
/// first stroke is lost. The first movement is whatever comes first: more
/// distance than the base, a stroke, or a stroke rate while the base had none.
/// A stroke rate alone is no movement when the base shows one too: a paused
/// PM5 keeps showing the rate of the earlier piece.
class FirstStrokeDetector {
  FirstStrokeDetector(ErgProtocol protocol)
    : _decoder = ErgDecoder.forProtocol(protocol);

  final ErgDecoder _decoder;
  StatusTick? _base;

  /// The packets of the base status.
  var _baseGroup = <RawPacket>[];

  /// The packets since the base status.
  var _since = <RawPacket>[];

  /// Adds [packet]; returns the packets the session starts with once the first
  /// movement shows, else null.
  List<RawPacket>? add(RawPacket packet) {
    _since.add(packet);
    for (final event in _decoder.decode(packet)) {
      if (event is Stroke || event is StatusTick && _moves(event)) {
        return [..._baseGroup, ..._since];
      }
      if (event is StatusTick) {
        _base = event;
        _baseGroup = _since;
        _since = [];
      }
    }
    return null;
  }

  bool _moves(StatusTick tick) {
    final base = _base;
    if (base == null) return false;
    if (tick.distanceMeters > base.distanceMeters) return true;
    return (tick.strokeRate ?? 0) > 0 && (base.strokeRate ?? 0) == 0;
  }
}
