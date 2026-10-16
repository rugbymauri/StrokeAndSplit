import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:erg_protocol/erg_protocol.dart';

import 'erg_source.dart';

/// A simulated rower that produces PM5 notifications like a real erg in
/// Just Row: the pace moves towards [targetPace] over a few strokes with a
/// slight variation per stroke, and the clock stops while paused.
class SimulatedSource implements ErgSource {
  SimulatedSource({
    this.targetPace = const Duration(minutes: 2, seconds: 10),
    this.targetStrokeRate = 22,
    int? seed,
    this.tickInterval = const Duration(milliseconds: 250),
  })  : _currentPace = targetPace,
        _random = math.Random(seed);

  /// Time between two status notifications, like the PM5 sample rate.
  final Duration tickInterval;

  static const _encoder = Pm5Encoder();
  static const _driveShare = 0.35;
  static const _driveLengthMeters = 1.4;

  final math.Random _random;
  final _packets = StreamController<RawPacket>.broadcast();
  final _states = StreamController<ErgConnectionState>.broadcast();
  var _state = ErgConnectionState.disconnected;
  Timer? _timer;
  DateTime? _startedAt;
  DateTime? _lastTick;

  /// Pace the rower moves towards, per 500 m.
  Duration targetPace;

  /// Strokes per minute.
  int targetStrokeRate;

  Duration _currentPace;
  var _paused = false;

  var _elapsed = Duration.zero;
  var _distanceMeters = 0.0;
  var _calories = 0.0;
  var _strokeNumber = 0;
  _SimulatedStroke? _stroke;

  bool get isPaused => _paused;

  /// Stops rowing; the clock and the distance stand still like on a PM5.
  void pause() {
    _paused = true;
    _stroke = null;
  }

  void resume() => _paused = false;

  @override
  ErgSourceKind get kind => ErgSourceKind.simulator;

  @override
  String get name => 'Simulator';

  @override
  Stream<RawPacket> get packets => _packets.stream;

  @override
  ErgConnectionState get connectionState => _state;

  @override
  Stream<ErgConnectionState> get connectionStates => _states.stream;

  @override
  Future<void> start() async {
    _startedAt ??= clock.now();
    _lastTick = clock.now();
    _timer ??= Timer.periodic(tickInterval, (_) => _tick());
    _setState(ErgConnectionState.connected);
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _setState(ErgConnectionState.disconnected);
  }

  void _tick() {
    final now = clock.now();
    final step = now.difference(_lastTick!);
    _lastTick = now;
    final at = now.difference(_startedAt!);

    if (!_paused) {
      _row(step, at);
    }
    final tick = StatusTick(
      elapsed: _elapsed,
      distanceMeters: _distanceMeters,
      workoutType: WorkoutType.justRowSplits,
      workoutState: WorkoutState.workoutRow,
      isRowing: !_paused,
      pace: _paused ? null : _currentPace,
      strokeRate: _paused ? 0 : targetStrokeRate,
      calories: _calories.floor(),
    );
    _encoder.encodeStatus(tick, at: at).forEach(_packets.add);
  }

  void _row(Duration step, Duration at) {
    _elapsed += step;
    _distanceMeters += _seconds(step) * 500 / _seconds(_currentPace);
    // Concept2 calorie formula: 4 × watts + 300 kcal/h.
    _calories += (4 * wattsForPace(_currentPace) + 300) * _seconds(step) / 3600;

    final stroke = _stroke ??= _nextStroke();
    if (!stroke.driveEndSent && _elapsed >= stroke.start + stroke.data.driveTime) {
      stroke.driveEndSent = true;
      _encoder.encodeDriveEnd(stroke.data, at: at).forEach(_packets.add);
    }
    if (_elapsed >= stroke.start + stroke.data.driveTime + stroke.data.recoveryTime) {
      _packets.add(_encoder.encodeRecoveryEnd(stroke.data, at: at));
      _stroke = null;
    }
  }

  _SimulatedStroke _nextStroke() {
    // Move a third of the way towards the target per stroke, ±2 % variation.
    final towardsTarget = _seconds(_currentPace) + (_seconds(targetPace) - _seconds(_currentPace)) / 3;
    final variation = 1 + (_random.nextDouble() * 2 - 1) * 0.02;
    _currentPace = Duration(microseconds: (towardsTarget * variation * 1e6).round());

    final interval = 60 / targetStrokeRate;
    final watts = wattsForPace(_currentPace);
    final driveSeconds = interval * _driveShare;
    final averageForce = watts * interval / _driveLengthMeters;
    _strokeNumber++;
    return _SimulatedStroke(
      _elapsed,
      Stroke(
        elapsed: _elapsed + _duration(driveSeconds),
        strokeNumber: _strokeNumber,
        distanceMeters: _distanceMeters,
        driveLengthMeters: _driveLengthMeters,
        driveTime: _duration(driveSeconds),
        recoveryTime: _duration(interval - driveSeconds),
        peakForceNewtons: averageForce * 1.6,
        averageForceNewtons: averageForce,
        watts: watts,
      ),
    );
  }

  void _setState(ErgConnectionState state) {
    if (_state == state) return;
    _state = state;
    _states.add(state);
  }

  static double _seconds(Duration d) => d.inMicroseconds / Duration.microsecondsPerSecond;

  static Duration _duration(double seconds) => Duration(microseconds: (seconds * 1e6).round());
}

class _SimulatedStroke {
  _SimulatedStroke(this.start, this.data);

  final Duration start;
  final Stroke data;
  var driveEndSent = false;
}
