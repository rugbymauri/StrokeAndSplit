import '../erg_decoder.dart';
import '../power.dart';
import '../raw_packet.dart';
import '../rowing_event.dart';
import '../workout.dart';
import 'ftms_ids.dart';
import 'rower_data.dart';

/// Turns FTMS Rower Data notifications into [RowingEvent]s of the same form
/// and meaning as the PM5 ones (Change device-types, Design D8).
///
/// Fields of a record split over several notifications are merged; a status
/// tick follows at the end of every record. Time is measured from the receive
/// times while rowing, so it behaves like the PM5 clock and a replay yields
/// the same values. Implausible values become null.
class FtmsDecoder implements ErgDecoder {
  FtmsDecoder({this.onWarning});

  final void Function(String message)? onWarning;

  /// Rowing stops when neither distance nor stroke count rose for this long.
  static const rowingTimeout = Duration(seconds: 4);

  /// More strokes than this between two records are taken over without
  /// events, e.g. when connecting in the middle of rowing.
  static const maxStrokeGap = 10;

  static const _minPace = Duration(minutes: 1);
  static const _maxPace = Duration(minutes: 10);

  // Last known value of every field used.
  double? _strokeRate;
  int? _strokeCount;
  int? _distance;
  Duration? _pace;
  int? _energy;
  int? _heartRate;

  // State at the end of the previous record.
  int? _previousCount;
  int? _previousDistance;
  Duration? _previousRecordTime;
  Duration? _lastProgress;
  var _elapsed = Duration.zero;

  @override
  List<RowingEvent> decode(RawPacket packet) {
    switch (packet.characteristicId) {
      case FtmsIds.rowerData:
        break;
      case FtmsIds.machineStatus || FtmsIds.controlPoint:
        // Recorded for analysis, not needed for the metrics.
        return const [];
      default:
        return _drop(packet, 'unknown characteristic ${packet.characteristicId}');
    }
    final data = RowerData.parse(packet.bytes);
    if (data == null) return _drop(packet, 'shorter than its flags announce (${packet.bytes.length} bytes)');

    _strokeRate = data.strokeRate ?? _strokeRate;
    _strokeCount = data.strokeCount ?? _strokeCount;
    _distance = data.totalDistance ?? _distance;
    _pace = data.pace ?? _pace;
    _energy = data.totalEnergy ?? _energy;
    _heartRate = data.heartRate ?? _heartRate;
    return data.moreData ? const [] : _onRecord(packet.time);
  }

  @override
  List<RowingEvent> flush() => const [];

  List<RowingEvent> _drop(RawPacket packet, String reason) {
    onWarning?.call('Dropped ${packet.characteristicId} packet at ${packet.time.inMilliseconds} ms: $reason');
    return const [];
  }

  List<RowingEvent> _onRecord(Duration time) {
    final events = <RowingEvent>[];
    final count = _strokeCount;
    final distance = _distance;
    final previousCount = _previousCount;
    final previousDistance = _previousDistance;

    final isReset = previousCount != null && count != null && count < previousCount ||
        previousDistance != null && distance != null && distance < previousDistance;
    if (isReset) {
      // Like a new workout on the PM5: time and distance start again from
      // zero, the session carries the progress over.
      _elapsed = Duration.zero;
      _lastProgress = null;
      events.add(WorkoutStateChanged(
          elapsed: _elapsed, previous: WorkoutState.unknown, current: WorkoutState.unknown, isReset: true));
    } else if (previousCount != null && count != null && count > previousCount ||
        previousDistance != null && distance != null && distance > previousDistance) {
      _lastProgress = time;
    }

    final lastProgress = _lastProgress;
    final isRowing = !isReset && lastProgress != null && time - lastProgress <= rowingTimeout;
    final previousTime = _previousRecordTime;
    if (isRowing && previousTime != null && time > previousTime) _elapsed += time - previousTime;
    _previousRecordTime = time;

    if (!isReset && previousCount != null && count != null && count > previousCount) {
      if (count - previousCount <= maxStrokeGap) {
        for (var n = previousCount + 1; n <= count; n++) {
          events.add(Stroke(elapsed: _elapsed, strokeNumber: n, distanceMeters: (distance ?? 0).toDouble()));
        }
      } else {
        onWarning?.call('Stroke count jumped from $previousCount to $count, no stroke events');
      }
    }
    _previousCount = count;
    _previousDistance = distance;

    final rawPace = _pace;
    final pace = isRowing && rawPace != null && rawPace >= _minPace && rawPace <= _maxPace ? rawPace : null;
    final strokeRate = _strokeRate?.round();
    final heartRate = _heartRate;
    final energy = _energy;
    events.add(StatusTick(
      elapsed: _elapsed,
      distanceMeters: (distance ?? 0).toDouble(),
      workoutType: WorkoutType.unknown,
      workoutState: WorkoutState.unknown,
      isRowing: isRowing,
      pace: pace,
      watts: pace == null ? null : wattsForPace(pace),
      strokeRate: strokeRate != null && strokeRate >= 1 && strokeRate <= 60 ? strokeRate : null,
      heartRate: heartRate != null && heartRate > 0 && heartRate <= 250 ? heartRate : null,
      calories: energy == RowerData.energyNotAvailable ? null : energy,
    ));
    return events;
  }
}
