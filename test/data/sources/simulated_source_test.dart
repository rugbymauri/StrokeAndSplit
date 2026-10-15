import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/simulated_source.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm5_protocol/pm5_protocol.dart';

/// Runs [source] in fake time and collects the decoded events.
List<RowingEvent> _listen(SimulatedSource source) {
  final decoder = Pm5Decoder(onWarning: (w) => fail(w));
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
}
