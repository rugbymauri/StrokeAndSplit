import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strokesplit/data/sessions/auto_pause.dart';
import 'package:strokesplit/data/sessions/first_stroke.dart';

import '../../support/fixtures.dart';

StatusTick _tick(double distance, {bool rowing = true, int elapsedMs = 0}) =>
    StatusTick(
      elapsed: Duration(milliseconds: elapsedMs),
      distanceMeters: distance,
      workoutType: WorkoutType.justRowSplits,
      workoutState: WorkoutState.workoutRow,
      isRowing: rowing,
    );

Stroke _stroke(int number, {int elapsedMs = 0}) => Stroke(
  elapsed: Duration(milliseconds: elapsedMs),
  strokeNumber: number,
  distanceMeters: 0,
);

/// Rows strokes every [intervalMs] from [fromMs] until before [untilMs], with
/// a status in between; returns the time after the last stroke.
int _row(
  AutoPause pause, {
  required int fromMs,
  required int untilMs,
  int intervalMs = 2500,
  double distance = 0,
}) {
  var t = fromMs;
  var n = 0;
  while (t < untilMs) {
    pause.add(t, [_stroke(n++), _tick(distance + t / 1000)]);
    pause.add(t + intervalMs ~/ 2, [
      _tick(distance + (t + intervalMs / 2) / 1000),
    ]);
    t += intervalMs;
  }
  return t - intervalMs;
}

/// Statuses without progress every 500 ms from [fromMs] until before [untilMs].
void _sit(
  AutoPause pause, {
  required int fromMs,
  required int untilMs,
  double distance = 100,
  bool rowing = false,
}) {
  for (var t = fromMs; t < untilMs; t += 500) {
    pause.add(t, [_tick(distance, rowing: rowing)]);
  }
}

/// Feeds the packets of [fixture] from the first movement on, as a session
/// gets them; with the arrival time of the first packet the session gets.
(AutoPause, int) _session(String fixture) {
  final recording = loadFixture(fixture);
  final protocol = ErgProtocol.parse(recording.metadata['protocol']);
  final detector = FirstStrokeDetector(protocol);
  final decoder = ErgDecoder.forProtocol(protocol);
  final pause = AutoPause();
  Duration? first;
  var started = false;
  for (final packet in recording.packets) {
    final early = started ? [packet] : detector.add(packet);
    if (early == null) continue;
    started = true;
    for (final p in early) {
      final start = first ??= p.time;
      pause.add((p.time - start).inMilliseconds, decoder.decode(p));
    }
  }
  return (pause, first!.inMilliseconds);
}

void main() {
  test('pauses 3 s after the next stroke was due and stands still', () {
    final pause = AutoPause();
    final last = _row(pause, fromMs: 0, untilMs: 60000);
    _sit(pause, fromMs: last + 1000, untilMs: last + 5000, rowing: true);
    expect(
      pause.paused,
      isFalse,
      reason: 'the next stroke is due after 2.5 s, overdue 3 s later',
    );

    pause.add(last + 5500, [_tick(100)]);
    expect(pause.paused, isTrue);
    expect(
      pause.activeMs,
      last + 5500,
      reason: 'the pause begins exactly when the stroke is overdue',
    );
    _sit(pause, fromMs: last + 6000, untilMs: last + 40000);
    expect(pause.activeMs, last + 5500);
  });

  test('a slow rhythm alone is no pause', () {
    final pause = AutoPause();
    // 16 strokes per minute: 3.75 s between two strokes.
    _row(pause, fromMs: 0, untilMs: 120000, intervalMs: 3750);
    expect(pause.paused, isFalse);
    expect(pause.takePauses(), isEmpty);
    expect(pause.activeMs, greaterThan(115000));
  });

  test('the first stroke after a pause resumes from where it stood', () {
    final pause = AutoPause();
    final last = _row(pause, fromMs: 0, untilMs: 30000);
    final pausedAt = last + 2500 + 3000;
    _sit(pause, fromMs: last + 500, untilMs: last + 40000, rowing: true);
    expect(pause.activeMs, pausedAt);

    final resumedAt = last + 40000;
    pause.add(resumedAt, [_stroke(99), _tick(101)]);
    expect(pause.paused, isFalse);
    expect(pause.activeMs, pausedAt, reason: 'nothing of the pause counts');
    pause.add(resumedAt + 1000, [_tick(103)]);
    expect(pause.activeMs, pausedAt + 1000);
    expect(pause.takePauses(), [
      PauseSpan(startWallMs: pausedAt, endWallMs: resumedAt),
    ]);
    expect(pause.takePauses(), isEmpty, reason: 'each pause once');
  });

  test('rowing again resumes from where the distance rose', () {
    final pause = AutoPause();
    final last = _row(pause, fromMs: 0, untilMs: 30000);
    _sit(pause, fromMs: last + 500, untilMs: last + 20000);
    expect(pause.paused, isTrue);

    // The distance rises before the monitor reports rowing, as on the PM5.
    final rise = last + 20000;
    pause.add(rise, [_tick(100.5, rowing: false)]);
    pause.add(rise + 300, [_tick(101, rowing: false)]);
    expect(pause.paused, isTrue);
    pause.add(rise + 600, [_tick(101.5)]);
    expect(pause.paused, isFalse);
    expect(pause.takePauses().single.endWallMs, rise);
    expect(pause.activeMs, last + 5500 + 600);
  });

  test(
    'a stroke rowed before the pause but reported later does not end it',
    () {
      final pause = AutoPause();
      final last = _row(pause, fromMs: 0, untilMs: 30000);
      _sit(pause, fromMs: last + 500, untilMs: last + 6000, rowing: true);
      expect(pause.paused, isTrue);

      // The monitor's clock stood at 40 s and the stroke began at 34 s, before the pause.
      pause.add(last + 6500, [_tick(100, rowing: true, elapsedMs: 40000)]);
      pause.add(last + 7000, [
        _stroke(50, elapsedMs: 34000),
        _tick(100, rowing: false, elapsedMs: 40000),
      ]);
      expect(pause.paused, isTrue);
      expect(pause.takePauses(), isEmpty);
    },
  );

  test('pauses before the first stroke and resumes with it', () {
    final pause = AutoPause();
    _sit(pause, fromMs: 0, untilMs: 20000, distance: 0);
    expect(pause.paused, isTrue);
    expect(pause.activeMs, 3000);

    pause.add(20000, [_stroke(0), _tick(0.2)]);
    expect(pause.paused, isFalse);
    expect(pause.takePauses(), [
      const PauseSpan(startWallMs: 3000, endWallMs: 20000),
    ]);
  });

  test('the session time never goes back', () {
    final pause = AutoPause();
    var previous = 0;
    void check() {
      expect(pause.activeMs, greaterThanOrEqualTo(previous));
      previous = pause.activeMs;
    }

    for (var t = 0; t < 120000; t += 250) {
      // Rows for 20 s, then sits for 10 s, again and again.
      final rowing = t % 30000 < 20000;
      pause.add(t, [
        if (rowing && t % 2500 == 0) _stroke(t),
        _tick(rowing ? t / 1000 : 0, rowing: rowing),
      ]);
      check();
    }
  });

  group('recordings', () {
    test('force_curve: no pause while rowing', () {
      expect(_session('force_curve').$1.takePauses(), isEmpty);
    });

    // These recordings stop now and then; each pause lies where the rower stood or coasted.
    for (final (fixture, count) in const [
      ('just_row', 2),
      ('ftms_just_row', 3),
      ('reset', 3),
    ]) {
      test('$fixture: pauses only where the rower stopped', () {
        final (pause, _) = _session(fixture);
        expect(pause.takePauses(), hasLength(count));
      });
    }

    test('pause: one pause from after the last stroke until the distance rises again', () {
      final (pause, first) = _session('pause');
      final pauses = pause.takePauses();
      expect(pauses, hasLength(1));
      // The rower stops after the stroke reported at 101.3 s, the PM5 reports
      // the open one at 108.1 s, and the distance rises again at 188.3 s.
      expect(
        pauses.single.startWallMs + first,
        inInclusiveRange(101266 + 3000, 108113),
      );
      expect(pauses.single.endWallMs + first, 188333);
    });
  });
}
