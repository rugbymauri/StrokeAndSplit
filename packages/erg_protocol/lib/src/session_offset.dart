/// Session-relative progress derived from the counters of the rowing machine.
class SessionProgress {
  const SessionProgress({required this.distanceMeters, required this.elapsed});

  final double distanceMeters;
  final Duration elapsed;

  @override
  bool operator ==(Object other) =>
      other is SessionProgress &&
      other.distanceMeters == distanceMeters &&
      other.elapsed == elapsed;

  @override
  int get hashCode => Object.hash(distanceMeters, elapsed);

  @override
  String toString() => 'SessionProgress(${distanceMeters}m, $elapsed)';
}

/// Turns the rowing machine's own time and distance into values that count
/// from the start of the session and keep counting when the machine is reset.
///
/// A reset is detected when either counter goes backwards, or signalled
/// explicitly via [reset].
class SessionOffset {
  SessionOffset.start({
    required double deviceDistance,
    required Duration deviceElapsed,
  }) : _baseDistance = deviceDistance,
       _baseElapsed = deviceElapsed,
       _lastDistance = deviceDistance,
       _lastElapsed = deviceElapsed;

  double _carriedDistance = 0;
  Duration _carriedElapsed = Duration.zero;
  double _baseDistance;
  Duration _baseElapsed;
  double _lastDistance;
  Duration _lastElapsed;

  SessionProgress update({
    required double deviceDistance,
    required Duration deviceElapsed,
  }) {
    if (deviceDistance < _lastDistance || deviceElapsed < _lastElapsed) {
      reset();
    }
    _lastDistance = deviceDistance;
    _lastElapsed = deviceElapsed;
    return current;
  }

  /// Carries the progress so far over and continues counting from zero
  /// device values.
  void reset() {
    _carriedDistance += _lastDistance - _baseDistance;
    _carriedElapsed += _lastElapsed - _baseElapsed;
    _baseDistance = 0;
    _baseElapsed = Duration.zero;
    _lastDistance = 0;
    _lastElapsed = Duration.zero;
  }

  SessionProgress get current => SessionProgress(
    distanceMeters: _carriedDistance + _lastDistance - _baseDistance,
    elapsed: _carriedElapsed + _lastElapsed - _baseElapsed,
  );
}
