import '../erg_decoder.dart';
import '../raw_packet.dart';
import '../rowing_event.dart';
import 'heart_rate_ids.dart';
import 'heart_rate_measurement.dart';

/// Adds a directly connected chest strap to the decoder of a rower.
///
/// Strap measurements never reach [inner]. Every [StatusTick] of [inner]
/// gets the strap's heart rate while its last value is at most
/// [strapTimeout] old, else keeps the rower's one, which may be null. Ages
/// are measured on the packet times, so live data, a replay and an import
/// yield the same result.
class HeartRateDecoder implements ErgDecoder {
  HeartRateDecoder(this.inner, {this.onWarning});

  /// The decoder of the rower's own protocol.
  final ErgDecoder inner;

  /// Receives a message for every strap packet that had to be dropped.
  final void Function(String message)? onWarning;

  /// How long the strap's last heart rate takes precedence over the rower's.
  static const strapTimeout = Duration(seconds: 3);

  int? _strapHeartRate;
  Duration? _strapTime;
  Duration? _lastRowerPacketTime;

  @override
  List<RowingEvent> decode(RawPacket packet) {
    if (packet.characteristicId == HeartRateIds.measurement) {
      return _onMeasurement(packet);
    }
    _lastRowerPacketTime = packet.time;
    return _withStrap(inner.decode(packet), packet.time);
  }

  @override
  List<RowingEvent> flush() => _withStrap(inner.flush(), _lastRowerPacketTime);

  List<RowingEvent> _onMeasurement(RawPacket packet) {
    final measurement = HeartRateMeasurement.parse(packet.bytes);
    if (measurement == null) {
      onWarning?.call(
        'Dropped ${packet.characteristicId} packet at ${packet.time.inMilliseconds} ms: '
        'shorter than its flags announce (${packet.bytes.length} bytes)',
      );
      return const [];
    }
    // 0 is what straps send without skin contact; it is no heart rate.
    if (measurement.heartRate > 0) {
      _strapHeartRate = measurement.heartRate;
      _strapTime = packet.time;
    }
    return const [];
  }

  List<RowingEvent> _withStrap(List<RowingEvent> events, Duration? time) {
    if (events.isEmpty) return events;
    final strapHeartRate = _strapHeartRate;
    final strapTime = _strapTime;
    final strapIsFresh =
        strapHeartRate != null &&
        strapTime != null &&
        time != null &&
        time - strapTime <= strapTimeout;
    return [
      for (final event in events)
        if (event is StatusTick)
          _onTick(event, strapIsFresh ? strapHeartRate : null)
        else
          event,
    ];
  }

  StatusTick _onTick(StatusTick tick, int? strapHeartRate) =>
      strapHeartRate == null ? tick : tick.copyWith(heartRate: strapHeartRate);
}
