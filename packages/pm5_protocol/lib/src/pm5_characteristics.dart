/// Short ids of the PM5 rowing characteristics, as used in [RawPacket].
abstract final class Pm5Characteristics {
  static const generalStatus = '0031';
  static const additionalStatus = '0032';
  static const additionalStatus2 = '0033';
  static const sampleRate = '0034';
  static const strokeData = '0035';
  static const additionalStrokeData = '0036';
  static const multiplexed = '0080';

  /// Characteristics a client subscribes to for live data.
  static const subscribed = [generalStatus, additionalStatus, additionalStatus2, strokeData, additionalStrokeData];

  /// Full 128-bit UUID of a PM5 service or characteristic.
  static String uuid(String shortId) => 'ce06$shortId-43e5-11e4-916c-0800200c9a66';

  /// Value for [sampleRate]: one status notification every 250 ms.
  static const sampleRate250ms = 2;
}

/// Conversion factor from pound-force, the PM5 force unit, to newtons.
const newtonsPerPoundForce = 4.44822;
