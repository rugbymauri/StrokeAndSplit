/// The Bluetooth protocol a rowing machine speaks.
///
/// Stored with sessions and recordings by [name], so replay and import pick
/// the matching decoder.
enum ErgProtocol {
  /// Concept2 PM5 with its own rowing service.
  pm5,

  /// Bluetooth SIG Fitness Machine Service, rower profile.
  ftms;

  /// Parses a stored [name]; a missing value means [pm5], as recordings
  /// made before FTMS support carry none.
  static ErgProtocol parse(Object? name) {
    if (name == null) return pm5;
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw FormatException('Unknown protocol: $name');
  }
}
