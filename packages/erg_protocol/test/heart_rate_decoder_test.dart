import 'dart:typed_data';

import 'package:erg_protocol/erg_protocol.dart';
import 'package:test/test.dart';

const _pm5 = Pm5Encoder();
const _ftms = FtmsEncoder();
const _strap = HeartRateEncoder();

Duration _s(num seconds) => Duration(milliseconds: (seconds * 1000).round());

/// Feeds rower and strap packets into the decoder [ErgDecoder.forProtocol]
/// builds, on one time axis.
class _Session {
  _Session(this.protocol)
    : decoder = ErgDecoder.forProtocol(protocol, onWarning: warnings.add);

  final ErgProtocol protocol;
  final ErgDecoder decoder;
  static final warnings = <String>[];
  final events = <RowingEvent>[];
  var _strokes = 0;

  List<RowingEvent> _feed(Iterable<RawPacket> packets) {
    final result = [for (final packet in packets) ...decoder.decode(packet)];
    events.addAll(result);
    return result;
  }

  /// One status record of the rower at [at] reporting [heartRate].
  StatusTick rower(Duration at, {int? heartRate}) {
    final tick = StatusTick(
      elapsed: at,
      distanceMeters: at.inSeconds * 4.0,
      workoutType: WorkoutType.justRowSplits,
      workoutState: WorkoutState.workoutRow,
      isRowing: true,
      pace: const Duration(minutes: 2),
      strokeRate: 24,
      heartRate: heartRate,
      calories: 10,
    );
    final packets = switch (protocol) {
      ErgProtocol.pm5 => _pm5.encodeStatus(tick, at: at),
      ErgProtocol.ftms => [
        _ftms.encode(
          RowerData(
            strokeRate: 24,
            strokeCount: ++_strokes,
            totalDistance: tick.distanceMeters.floor(),
            pace: tick.pace,
            heartRate: heartRate,
          ),
          at: at,
        ),
      ],
    };
    return _feed(packets).whereType<StatusTick>().single;
  }

  List<RowingEvent> strap(Duration at, int heartRate) =>
      _feed([_strap.encode(heartRate: heartRate, at: at)]);
}

void main() {
  setUp(_Session.warnings.clear);

  for (final protocol in ErgProtocol.values) {
    final rowerHeartRate = protocol == ErgProtocol.pm5 ? 140 : 138;

    group('${protocol.name}: heart rate precedence', () {
      test('prefers the strap over the rower', () {
        final session = _Session(protocol)..strap(_s(10), 142);
        expect(session.rower(_s(10), heartRate: rowerHeartRate).heartRate, 142);
      });

      test('takes the rower\'s heart rate once the strap is silent for more than 3 s', () {
        final session = _Session(protocol)
          ..strap(_s(10), 142)
          ..rower(_s(11), heartRate: rowerHeartRate);
        expect(
          session.rower(_s(14), heartRate: rowerHeartRate).heartRate,
          rowerHeartRate,
        );
      });

      test(
        'reports no heart rate once the strap is silent and the rower has none',
        () {
          final session = _Session(protocol)
            ..strap(_s(10), 142)
            ..rower(_s(11));
          expect(session.rower(_s(14)).heartRate, isNull);
        },
      );

      test('keeps the strap for exactly 3 s', () {
        final session = _Session(protocol)..strap(_s(10), 142);
        expect(session.rower(_s(13), heartRate: rowerHeartRate).heartRate, 142);
        expect(
          session.rower(_s(13.001), heartRate: rowerHeartRate).heartRate,
          rowerHeartRate,
        );
      });

      test('measures the age on the packet times', () {
        final session = _Session(protocol)
          ..strap(_s(10), 142)
          ..rower(_s(12), heartRate: rowerHeartRate)
          ..strap(_s(12.5), 150);
        expect(session.rower(_s(15), heartRate: rowerHeartRate).heartRate, 150);
      });

      test('treats a strap heart rate of 0 as missing', () {
        final session = _Session(protocol)
          ..strap(_s(10), 142)
          ..strap(_s(11), 0);
        expect(session.rower(_s(12), heartRate: rowerHeartRate).heartRate, 142);
        expect(
          session.rower(_s(13.5), heartRate: rowerHeartRate).heartRate,
          rowerHeartRate,
        );
      });

      test('leaves every other metric to the rower', () {
        // FTMS rowers count as rowing from the second record on.
        final session = _Session(protocol)
          ..rower(_s(9))
          ..strap(_s(10), 142);
        final tick = session.rower(_s(10), heartRate: rowerHeartRate);
        expect(tick.distanceMeters, 40);
        expect(tick.strokeRate, 24);
        expect(tick.pace, const Duration(minutes: 2));
      });
    });

    group('${protocol.name}: cut off measurement', () {
      test('is dropped with a warning while the rower data goes on', () {
        final session = _Session(protocol)
          ..strap(_s(10), 142)
          ..rower(_s(10), heartRate: rowerHeartRate);
        // The RR flag with half an interval after the heart rate.
        final events = session.decoder.decode(
          RawPacket(
            time: _s(13),
            characteristicId: HeartRateIds.measurement,
            bytes: Uint8List.fromList([0x10, 150, 0x40]),
          ),
        );

        expect(events, isEmpty);
        expect(_Session.warnings.single, contains('2a37'));
        final tick = session.rower(_s(14), heartRate: rowerHeartRate);
        expect(tick.heartRate, rowerHeartRate);
        expect(tick.distanceMeters, 56);
      });
    });
  }

  group('FTMS heart rate as fallback', () {
    test('comes through without a strap', () {
      final session = _Session(ErgProtocol.ftms);
      expect(session.rower(_s(1), heartRate: 138).heartRate, 138);
    });

    test('is overridden by a fresh strap and applies again 3 s after its last value', () {
      final session = _Session(ErgProtocol.ftms)..rower(_s(1), heartRate: 138);
      session.strap(_s(2), 142);
      expect(session.rower(_s(2), heartRate: 138).heartRate, 142);
      expect(session.rower(_s(5), heartRate: 139).heartRate, 142);
      expect(session.rower(_s(6), heartRate: 139).heartRate, 139);
    });

    test('stays missing when the rower reports 0', () {
      final session = _Session(ErgProtocol.ftms)
        ..strap(_s(1), 142)
        ..rower(_s(1), heartRate: 0);
      expect(session.rower(_s(5), heartRate: 0).heartRate, isNull);
      expect(
        _Session(ErgProtocol.ftms).rower(_s(1), heartRate: 0).heartRate,
        isNull,
      );
    });
  });

  test('a strap packet never reaches the rower decoder', () {
    final session = _Session(ErgProtocol.pm5)..strap(_s(1), 142);
    expect(_Session.warnings, isEmpty);
    expect(session.events, isEmpty);
  });

  test('applies the strap to status ticks emitted on flush', () {
    final decoder = HeartRateDecoder(Pm5Decoder());
    final tick = StatusTick(
      elapsed: _s(5),
      distanceMeters: 20,
      workoutType: WorkoutType.justRowSplits,
      workoutState: WorkoutState.workoutRow,
      isRowing: true,
      heartRate: 140,
    );
    // Only the general status: the PM5 decoder holds the tick until flush.
    decoder.decode(_pm5.encodeStatus(tick, at: _s(5)).first);
    decoder.decode(_strap.encode(heartRate: 142, at: _s(6)));

    expect(decoder.flush().whereType<StatusTick>().single.heartRate, 142);
  });
}
