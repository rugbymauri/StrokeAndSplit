import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/sources/simulated_source.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erg_protocol/erg_protocol.dart';

/// Runs [source] in fake time and collects the decoded events.
List<RowingEvent> _listen(SimulatedSource source) {
  final decoder = ErgDecoder.forProtocol(source.protocol, onWarning: (w) => fail(w));
  final events = <RowingEvent>[];
  source.packets.listen((p) => events.addAll(decoder.decode(p)));
  return events;
}

double _paceSeconds(Duration pace) => pace.inMilliseconds / 1000;

void main() {
  test('behaves like a connected PM5 producing live data', () {
    fakeAsync((async) {
      final source = SimulatedSource(seed: 1);
      final events = _listen(source);
      source.start();
      async.elapse(const Duration(seconds: 10));

      expect(source.kind, ErgSourceKind.simulator);
      expect(source.connectionState, ErgConnectionState.connected);
      expect(events.whereType<StatusTick>(), hasLength(40));
      expect(events.whereType<Stroke>().length, inInclusiveRange(3, 4));
      expect(events.whereType<StatusTick>().last.distanceMeters, closeTo(10 * 500 / 130, 1));
    });
  });

  test('approaches a new target pace within a few strokes', () {
    fakeAsync((async) {
      final source = SimulatedSource(targetPace: const Duration(minutes: 2, seconds: 10), seed: 7);
      final events = _listen(source);
      source.start();
      async.elapse(const Duration(seconds: 20));

      source.targetPace = const Duration(minutes: 1, seconds: 50);
      final strokesBefore = events.whereType<Stroke>().length;
      async.elapse(const Duration(seconds: 20));

      final strokesAfter = events.whereType<Stroke>().skip(strokesBefore).toList();
      final fifth = events.whereType<StatusTick>().lastWhere((t) => t.elapsed <= strokesAfter[4].elapsed);
      expect(_paceSeconds(fifth.pace!), closeTo(110, 110 * 0.06));
      // ±2 % variation per stroke plus what is left of the approach.
      expect(_paceSeconds(events.whereType<StatusTick>().last.pace!), closeTo(110, 110 * 0.04));
    });
  });

  test('stands still while paused and continues afterwards', () {
    fakeAsync((async) {
      final source = SimulatedSource(seed: 3);
      final events = _listen(source);
      source.start();
      async.elapse(const Duration(seconds: 10));

      source.pause();
      async.elapse(const Duration(milliseconds: 250));
      final atPause = events.whereType<StatusTick>().last;
      final strokesAtPause = events.whereType<Stroke>().length;
      async.elapse(const Duration(seconds: 30));
      final duringPause = events.whereType<StatusTick>().last;

      expect(duringPause.distanceMeters, atPause.distanceMeters);
      expect(duringPause.elapsed, atPause.elapsed);
      expect(duringPause.isRowing, isFalse);
      expect(duringPause.pace, isNull);
      expect(events.whereType<Stroke>().length, strokesAtPause);

      source.resume();
      async.elapse(const Duration(seconds: 10));
      expect(events.whereType<StatusTick>().last.distanceMeters, greaterThan(atPause.distanceMeters));
    });
  });

  test('produces the same data with the same seed', () {
    List<String> run() {
      late List<String> result;
      fakeAsync((async) {
        final source = SimulatedSource(seed: 42);
        final events = _listen(source);
        source.start();
        async.elapse(const Duration(seconds: 15));
        result = events.map((e) => e.toString()).toList();
      });
      return result;
    }

    expect(run(), orderedEquals(run()));
  });

  group('force curve', () {
    test('is provided when speaking PM5 and not FTMS', () {
      expect(SimulatedSource(seed: 1).providesForceCurves, isTrue);
      expect(SimulatedSource(seed: 1, protocol: ErgProtocol.ftms).providesForceCurves, isFalse);
    });

    /// The force curves of 30 s of rowing at [pace].
    List<StrokeForceCurve> curvesAt(Duration pace) {
      late List<StrokeForceCurve> curves;
      fakeAsync((async) {
        final source = SimulatedSource(targetPace: pace, seed: 5);
        final events = _listen(source);
        source.start();
        async.elapse(const Duration(seconds: 30));
        curves = events.whereType<StrokeForceCurve>().toList();
      });
      return curves;
    }

    double meanPeak(List<StrokeForceCurve> curves) =>
        curves.map((c) => c.peakNewtons).reduce((a, b) => a + b) / curves.length;

    test('comes once per stroke with the peak force and drive length of the stroke', () {
      fakeAsync((async) {
        final source = SimulatedSource(seed: 2);
        final events = _listen(source);
        source.start();
        async.elapse(const Duration(seconds: 20));

        final curves = {for (final c in events.whereType<StrokeForceCurve>()) c.strokeNumber: c};
        final strokes = events.whereType<Stroke>().toList();
        expect(strokes, isNotEmpty);
        for (final stroke in strokes) {
          final curve = curves[stroke.strokeNumber]!;
          // Curve values travel in whole pound-force, the peak force in tenths.
          expect(curve.peakNewtons, closeTo(stroke.peakForceNewtons!, newtonsPerPoundForce));
          expect(curve.driveLengthMeters, stroke.driveLengthMeters);
          expect(curve.forcesNewtons.length, inInclusiveRange(30, 70));
        }
      });
    });

    test('carries a drive length between 0.8 and 1.3 m that varies from stroke to stroke', () {
      final lengths = curvesAt(const Duration(minutes: 2, seconds: 10)).map((c) => c.driveLengthMeters).toList();

      expect(lengths, hasLength(greaterThan(5)));
      expect(lengths, everyElement(allOf(isNotNull, inInclusiveRange(0.8, 1.3))));
      expect(lengths.toSet().length, greaterThan(1));
    });

    test('is higher at a higher power', () {
      final easy = curvesAt(const Duration(minutes: 2, seconds: 20));
      final hard = curvesAt(const Duration(minutes: 1, seconds: 45));

      expect(meanPeak(hard), greaterThan(meanPeak(easy) * 1.5));
    });
  });

  test('stops producing data when stopped', () {
    fakeAsync((async) {
      final source = SimulatedSource(seed: 1);
      final events = _listen(source);
      source.start();
      async.elapse(const Duration(seconds: 2));
      source.stop();
      final count = events.length;
      async.elapse(const Duration(seconds: 5));

      expect(events, hasLength(count));
      expect(source.connectionState, ErgConnectionState.disconnected);
    });
  });

  group('in FTMS mode', () {
    test('sends one Rower Data record per second', () {
      fakeAsync((async) {
        final source = SimulatedSource(seed: 1, protocol: ErgProtocol.ftms);
        final packets = <RawPacket>[];
        source.packets.listen(packets.add);
        source.start();
        async.elapse(const Duration(seconds: 10));

        expect(source.protocol, ErgProtocol.ftms);
        expect(packets.map((p) => p.characteristicId).toSet(), {FtmsIds.rowerData});
        expect(packets, hasLength(inInclusiveRange(9, 10)));
      });
    });

    test('approaches a new target pace and counts the strokes', () {
      fakeAsync((async) {
        final source = SimulatedSource(seed: 7, protocol: ErgProtocol.ftms);
        final events = _listen(source);
        source.start();
        async.elapse(const Duration(seconds: 20));
        source.targetPace = const Duration(minutes: 1, seconds: 50);
        async.elapse(const Duration(seconds: 30));

        final last = events.whereType<StatusTick>().last;
        expect(_paceSeconds(last.pace!), closeTo(110, 110 * 0.04));
        // 22 strokes per minute over 50 s; strokes end on a 250 ms tick, so
        // the simulator rows a little slower, like in PM5 mode.
        expect(events.whereType<Stroke>().length, inInclusiveRange(15, 19));
        expect(events.whereType<Stroke>().every((s) => s.driveTime == null), isTrue);
        expect(last.distanceMeters, greaterThan(150));
      });
    });

    test('stands still while paused and continues afterwards', () {
      fakeAsync((async) {
        final source = SimulatedSource(seed: 3, protocol: ErgProtocol.ftms);
        final events = _listen(source);
        source.start();
        async.elapse(const Duration(seconds: 10));

        source.pause();
        async.elapse(const Duration(seconds: 30));
        final duringPause = events.whereType<StatusTick>().last;
        final strokesAtPause = events.whereType<Stroke>().length;
        async.elapse(const Duration(seconds: 5));

        expect(duringPause.isRowing, isFalse);
        expect(duringPause.pace, isNull);
        expect(events.whereType<StatusTick>().last.elapsed, duringPause.elapsed);
        expect(events.whereType<Stroke>().length, strokesAtPause);

        source.resume();
        async.elapse(const Duration(seconds: 10));
        final resumed = events.whereType<StatusTick>().last;
        expect(resumed.distanceMeters, greaterThan(duringPause.distanceMeters));
        expect(resumed.elapsed, greaterThan(duringPause.elapsed));
      });
    });
  });
}
