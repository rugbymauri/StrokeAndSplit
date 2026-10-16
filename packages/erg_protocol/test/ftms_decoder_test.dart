import 'package:erg_protocol/erg_protocol.dart';
import 'package:test/test.dart';

const _encoder = FtmsEncoder();

/// Feeds one record per second; each entry is (stroke count, distance).
class _Rower {
  final decoder = FtmsDecoder(onWarning: warnings.add);
  static final warnings = <String>[];
  static const pace = Duration(minutes: 2);
  var time = Duration.zero;
  final events = <RowingEvent>[];

  List<RowingEvent> send(RowerData data, {Duration step = const Duration(seconds: 1)}) {
    final result = decoder.decode(_encoder.encode(data, at: time));
    time += step;
    events.addAll(result);
    return result;
  }

  List<RowingEvent> record(int count, int distance, {double rate = 22, Duration? pace, int? heartRate}) =>
      send(RowerData(
        strokeRate: rate,
        strokeCount: count,
        totalDistance: distance,
        pace: pace ?? _Rower.pace,
        heartRate: heartRate,
      ));

  StatusTick get lastTick => events.whereType<StatusTick>().last;
  List<Stroke> get strokes => events.whereType<Stroke>().toList();
}

void main() {
  setUp(_Rower.warnings.clear);

  group('status', () {
    test('measures the time itself on a rower without time field', () {
      final rower = _Rower();
      // Two minutes of rowing at about 4 m/s, one record per second.
      for (var s = 0; s <= 120; s++) {
        rower.record(s ~/ 3, s * 4);
      }
      expect(rower.lastTick.elapsed, const Duration(minutes: 2));
      expect(rower.lastTick.distanceMeters, 480);
      expect(rower.lastTick.isRowing, isTrue);
    });

    test('stops the clock when the rower stops and runs on afterwards', () {
      final rower = _Rower();
      for (var s = 0; s <= 10; s++) {
        rower.record(s, s * 4);
      }
      expect(rower.lastTick.elapsed, const Duration(seconds: 10));
      // Ten seconds without progress; the device repeats its last values.
      for (var s = 0; s < 10; s++) {
        rower.record(10, 40);
      }
      expect(rower.lastTick.isRowing, isFalse);
      expect(rower.lastTick.pace, isNull);
      // Rowing counts as stopped 4 s after the last progress.
      expect(rower.lastTick.elapsed, const Duration(seconds: 14));
      rower.record(11, 44);
      rower.record(12, 48);
      expect(rower.lastTick.isRowing, isTrue);
      expect(rower.lastTick.elapsed, const Duration(seconds: 16));
    });

    test('has no workout type or state', () {
      final rower = _Rower()..record(0, 0);
      expect(rower.lastTick.workoutType, WorkoutType.unknown);
      expect(rower.lastTick.workoutState, WorkoutState.unknown);
    });

    test('shows the same watts as the PM5 at 2:00', () {
      final rower = _Rower()
        ..record(0, 0)
        ..record(1, 4);
      expect(rower.lastTick.pace, const Duration(minutes: 2));
      expect(rower.lastTick.watts, wattsForPace(const Duration(minutes: 2)));
      expect(rower.lastTick.watts, 203);
    });

    test('ignores the power of the device', () {
      final rower = _Rower()
        ..record(0, 0)
        ..send(const RowerData(
            strokeRate: 22, strokeCount: 1, totalDistance: 4, pace: Duration(minutes: 2), power: 999));
      expect(rower.lastTick.watts, 203);
    });

    test('treats a pace of 0 as missing and keeps the other values', () {
      final rower = _Rower()
        ..record(0, 0)
        ..record(1, 4, pace: Duration.zero);
      expect(rower.lastTick.pace, isNull);
      expect(rower.lastTick.watts, isNull);
      expect(rower.lastTick.distanceMeters, 4);
      expect(rower.lastTick.strokeRate, 22);
    });

    test('treats a heart rate of 0 as missing', () {
      final rower = _Rower()..record(0, 0, heartRate: 0);
      expect(rower.lastTick.heartRate, isNull);
      rower.record(1, 4, heartRate: 140);
      expect(rower.lastTick.heartRate, 140);
    });

    test('treats a stroke rate of 120 as missing', () {
      final rower = _Rower()..record(0, 0, rate: 120);
      expect(rower.lastTick.strokeRate, isNull);
    });

    test('treats the energy placeholder as missing calories', () {
      final rower = _Rower()
        ..send(const RowerData(
          strokeRate: 22,
          strokeCount: 0,
          totalDistance: 0,
          totalEnergy: RowerData.energyNotAvailable,
          energyPerHour: RowerData.energyNotAvailable,
          energyPerMinute: 0xFF,
        ));
      expect(rower.lastTick.calories, isNull);
      rower.send(const RowerData(
          strokeRate: 22, strokeCount: 1, totalDistance: 4, totalEnergy: 12, energyPerHour: 0, energyPerMinute: 0));
      expect(rower.lastTick.calories, 12);
    });

    test('merges a record split over several notifications', () {
      final rower = _Rower();
      final first = rower.send(const RowerData(moreData: true, totalDistance: 100, pace: Duration(minutes: 2)),
          step: Duration.zero);
      expect(first, isEmpty);
      rower.send(const RowerData(strokeRate: 24, strokeCount: 30, heartRate: 150));
      expect(rower.lastTick.distanceMeters, 100);
      expect(rower.lastTick.strokeRate, 24);
      expect(rower.lastTick.heartRate, 150);
    });

    test('drops a packet shorter than announced and goes on', () {
      final rower = _Rower()..record(0, 0);
      final dropped = rower.decoder
          .decode(RawPacket(time: rower.time, characteristicId: FtmsIds.rowerData, bytes: [0x04, 0x00, 44]));
      expect(dropped, isEmpty);
      expect(_Rower.warnings.single, contains('shorter'));
      rower.record(1, 4);
      expect(rower.lastTick.distanceMeters, 4);
    });

    test('ignores machine status and control point responses', () {
      final decoder = FtmsDecoder(onWarning: _Rower.warnings.add);
      expect(decoder.decode(RawPacket(time: Duration.zero, characteristicId: FtmsIds.machineStatus, bytes: [4])),
          isEmpty);
      final response = RawPacket(time: Duration.zero, characteristicId: FtmsIds.controlPoint, bytes: [0x80, 0, 1]);
      expect(decoder.decode(response), isEmpty);
      expect(_Rower.warnings, isEmpty);
    });
  });

  group('strokes', () {
    test('emits one stroke per counter step without details', () {
      final rower = _Rower()
        ..record(0, 0)
        ..record(1, 4);
      final stroke = rower.strokes.single;
      expect((stroke.strokeNumber, stroke.distanceMeters), (1, 4.0));
      expect(stroke.driveLengthMeters, isNull);
      expect(stroke.driveTime, isNull);
      expect(stroke.recoveryTime, isNull);
      expect(stroke.peakForceNewtons, isNull);
      expect(stroke.averageForceNewtons, isNull);
      expect(stroke.watts, isNull);
    });

    test('emits the missed strokes when the counter jumps from 40 to 42', () {
      final rower = _Rower()
        ..record(40, 400)
        ..record(42, 408);
      expect(rower.strokes.map((s) => s.strokeNumber), [41, 42]);
    });

    test('takes over the count of the first record in the middle of rowing', () {
      final rower = _Rower()..record(250, 2500);
      expect(rower.strokes, isEmpty);
      rower.record(251, 2504);
      expect(rower.strokes.map((s) => s.strokeNumber), [251]);
    });

    test('emits no strokes for a jump of more than 10 strokes', () {
      final rower = _Rower()
        ..record(10, 100)
        ..record(30, 180);
      expect(rower.strokes, isEmpty);
      rower.record(31, 184);
      expect(rower.strokes.map((s) => s.strokeNumber), [31]);
    });
  });

  group('reset', () {
    test('reports a reset when the distance falls from 1500 m to 0 m', () {
      final rower = _Rower();
      for (var s = 0; s <= 5; s++) {
        rower.record(100 + s, 1480 + s * 4);
      }
      final events = rower.record(0, 0);
      final reset = events.whereType<WorkoutStateChanged>().single;
      expect(reset.isReset, isTrue);
      expect((reset.previous, reset.current), (WorkoutState.unknown, WorkoutState.unknown));
      expect(rower.lastTick.distanceMeters, 0);
      expect(rower.lastTick.elapsed, Duration.zero);
      expect(events.whereType<Stroke>(), isEmpty);
    });

    test('reports a reset when only the stroke count falls', () {
      final rower = _Rower()
        ..record(100, 1500)
        ..record(101, 1504);
      final events = rower.record(0, 1504);
      expect(events.whereType<WorkoutStateChanged>().single.isReset, isTrue);
    });

    test('counts strokes again from the new count after a reset', () {
      final rower = _Rower()
        ..record(100, 1500)
        ..record(0, 0)
        ..record(1, 4)
        ..record(2, 8);
      expect(rower.strokes.map((s) => s.strokeNumber), [1, 2]);
    });

    test('lets the session go on without a jump back', () {
      final rower = _Rower();
      SessionOffset? offset;
      SessionProgress? progress;
      void track(List<RowingEvent> events) {
        for (final tick in events.whereType<StatusTick>()) {
          offset ??= SessionOffset.start(deviceDistance: tick.distanceMeters, deviceElapsed: tick.elapsed);
          progress = offset!.update(deviceDistance: tick.distanceMeters, deviceElapsed: tick.elapsed);
        }
      }

      for (var s = 0; s <= 10; s++) {
        track(rower.record(s, s * 4));
      }
      expect(progress, const SessionProgress(distanceMeters: 40, elapsed: Duration(seconds: 10)));
      track(rower.record(0, 0));
      for (var s = 1; s <= 5; s++) {
        track(rower.record(s, s * 4));
      }
      expect(progress!.distanceMeters, 60);
      expect(progress!.elapsed, const Duration(seconds: 15));
    });
  });

  test('is the decoder of the FTMS protocol', () {
    expect(ErgDecoder.forProtocol(ErgProtocol.ftms), isA<FtmsDecoder>());
  });
}
