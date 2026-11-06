import 'dart:math' as math;

/// Power for a pace per 500 m, using the Concept2 formula P = 2.80 / (s/m)³.
///
/// Used for every protocol, so the same pace always shows the same watts.
int wattsForPace(Duration pacePer500m) {
  final secondsPerMeter =
      pacePer500m.inMicroseconds / Duration.microsecondsPerSecond / 500;
  return (2.80 / math.pow(secondsPerMeter, 3)).round();
}
