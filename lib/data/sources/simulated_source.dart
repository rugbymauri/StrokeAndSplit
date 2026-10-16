import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:erg_protocol/erg_protocol.dart';

import 'erg_source.dart';

/// A simulated rower that produces notifications like a real erg in Just
/// Row: the pace moves towards [targetPace] over a few strokes with a slight
/// variation per stroke, and the clock stops while paused.
///
/// With [protocol] FTMS it sends one Rower Data record per second like a
/// typical FTMS rower instead of the PM5 notifications (Design D10).
class SimulatedSource implements ErgSource {
  SimulatedSource({
    this.targetPace = const Duration(minutes: 2, seconds: 10),
    this.targetStrokeRate = 22,
    int? seed,
    this.tickInterval = const Duration(milliseconds: 250),
    this.protocol = ErgProtocol.pm5,
  })  : _currentPace = targetPace,
        _random = math.Random(seed);

  /// Time between two status notifications, like the PM5 sample rate.
  final Duration tickInterval;

  @override
  final ErgProtocol protocol;

  /// Time between two Rower Data records in FTMS mode.
  static const ftmsInterval = Duration(seconds: 1);

  static const _encoder = Pm5Encoder();
  static const _ftmsEncoder = FtmsEncoder();
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
  var _completedStrokes = 0;
  _SimulatedStroke? _stroke;
  Duration? _lastFtmsRecord;

  bool get isPaused => _paused;

  /// A new simulator with the same targets that speaks [protocol].
  SimulatedSource withProtocol(ErgProtocol protocol) => SimulatedSource(
        targetPace: targetPace,
        targetStrokeRate: targetStrokeRate,
        tickInterval: tickInterval,
        protocol: protocol,
      );

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
    switch (protocol) {
      case ErgProtocol.pm5:
        _encoder.encodeStatus(tick, at: at).forEach(_packets.add);
      case ErgProtocol.ftms:
        final last = _lastFtmsRecord;
        if (last != null && at - last < ftmsInterval) return;
        _lastFtmsRecord = at;
        _packets.add(_ftmsEncoder.encodeStatus(
          StatusTick(
            elapsed: tick.elapsed,
            distanceMeters: tick.distanceMeters,
            workoutType: tick.workoutType,
            workoutState: tick.workoutState,
            isRowing: tick.isRowing,
            pace: tick.pace,
            watts: tick.pace == null ? null : wattsForPace(tick.pace!),
            strokeRate: tick.strokeRate,
            calories: tick.calories,
          ),
          strokeCount: _completedStrokes,
          at: at,
        ));
    }
  }

  void _row(Duration step, Duration at) {
    _elapsed += step;
    _distanceMeters += _seconds(step) * 500 / _seconds(_currentPace);
    // Concept2 calorie formula: 4 × watts + 300 kcal/h.
    _calories += (4 * wattsForPace(_currentPace) + 300) * _seconds(step) / 3600;

    final stroke = _stroke ??= _nextStroke();
    if (!stroke.driveEndSent && _elapsed >= stroke.start + stroke.drive) {
      stroke.driveEndSent = true;
      if (protocol == ErgProtocol.pm5) _encoder.encodeDriveEnd(stroke.data, at: at).forEach(_packets.add);
    }
    if (_elapsed >= stroke.start + stroke.drive + stroke.recovery) {
      if (protocol == ErgProtocol.pm5) _packets.add(_encoder.encodeRecoveryEnd(stroke.data, at: at));
      _completedStrokes++;
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
    final drive = _duration(driveSeconds);
    final recovery = _duration(interval - driveSeconds);
    _strokeNumber++;
    return _SimulatedStroke(
      _elapsed,
      drive,
      recovery,
      Stroke(
        elapsed: _elapsed + drive,
        strokeNumber: _strokeNumber,
        distanceMeters: _distanceMeters,
        driveLengthMeters: _driveLengthMeters,
        driveTime: drive,
        recoveryTime: recovery,
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
  _SimulatedStroke(this.start, this.drive, this.recovery, this.data);

  final Duration start;
  final Duration drive;
  final Duration recovery;
  final Stroke data;
  var driveEndSent = false;
}
