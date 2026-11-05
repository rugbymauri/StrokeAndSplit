/// Short ids of the Fitness Machine Service (Bluetooth SIG, FTMS 1.0) as four
/// hex digits, in the form [RawPacket.characteristicId] uses.
abstract final class FtmsIds {
  static const service = '1826';
  static const feature = '2acc';
  static const rowerData = '2ad1';
  static const supportedResistanceLevelRange = '2ad6';
  static const controlPoint = '2ad9';
  static const machineStatus = '2ada';

  /// Bit of the Fitness Machine Type field in the service data that marks a
  /// rower.
  static const rowerTypeBit = 4;
}
