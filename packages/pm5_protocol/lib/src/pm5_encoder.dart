import 'dart:typed_data';

import 'pm5_characteristics.dart';
import 'raw_packet.dart';
import 'rowing_event.dart';

/// Turns [RowingEvent]s into PM5 notifications, in the byte layout and order
/// a real PM5 sends them. Used by the simulator.
///
/// Fields the events do not carry are written as zero; derived values
/// (watts, speed) are recomputed by the decoder.
class Pm5Encoder {
  const Pm5Encoder();

  /// The three status notifications for one moment.
  List<RawPacket> encodeStatus(StatusTick tick, {required Duration at}) {
    final elapsed = _centi(tick.elapsed);
    final paceRaw = tick.pace == null ? 0 : _centi(tick.pace!);
    final speedRaw = tick.pace == null ? 0 : (500 / tick.pace!.inMilliseconds * 1000 * 1000).round();

    final general = _Bytes(19)
      ..u24(0, elapsed)
      ..u24(3, (tick.distanceMeters * 10).round())
      ..u8(6, _code(tick.workoutType.code))
      ..u8(7, 1)
      ..u8(8, _code(tick.workoutState.code))
      ..u8(9, tick.isRowing ? 1 : 0)
      ..u8(17, 0x80);
    final additional = _Bytes(17)
      ..u24(0, elapsed)
      ..u16(3, speedRaw)
      ..u8(5, tick.strokeRate ?? 0)
      ..u8(6, tick.heartRate ?? 255)
      ..u16(7, paceRaw);
    final additional2 = _Bytes(20)
      ..u24(0, elapsed)
      ..u16(6, tick.calories ?? 0);

    return [
      RawPacket(time: at, characteristicId: Pm5Characteristics.generalStatus, bytes: general.bytes),
      RawPacket(time: at, characteristicId: Pm5Characteristics.additionalStatus, bytes: additional.bytes),
      RawPacket(time: at, characteristicId: Pm5Characteristics.additionalStatus2, bytes: additional2.bytes),
    ];
  }

  /// The notifications at the end of the drive: stroke data and stroke power.
  List<RawPacket> encodeDriveEnd(Stroke stroke, {required Duration at}) => [
        RawPacket(time: at, characteristicId: Pm5Characteristics.strokeData, bytes: _strokeData(stroke)),
        RawPacket(
          time: at,
          characteristicId: Pm5Characteristics.additionalStrokeData,
          bytes: (_Bytes(15)
                ..u24(0, _centi(stroke.elapsed))
                ..u16(3, stroke.watts ?? 0)
                ..u16(7, stroke.strokeNumber))
              .bytes,
        ),
      ];

  /// The notification at the end of the recovery, which completes the stroke.
  RawPacket encodeRecoveryEnd(Stroke stroke, {required Duration at}) =>
      RawPacket(time: at, characteristicId: Pm5Characteristics.strokeData, bytes: _strokeData(stroke));

  Uint8List _strokeData(Stroke stroke) => (_Bytes(20)
        ..u24(0, _centi(stroke.elapsed))
        ..u24(3, (stroke.distanceMeters * 10).round())
        ..u8(6, (stroke.driveLengthMeters * 100).round())
        ..u8(7, _centi(stroke.driveTime))
        ..u16(8, _centi(stroke.recoveryTime))
        ..u16(12, (stroke.peakForceNewtons / newtonsPerPoundForce * 10).round())
        ..u16(14, (stroke.averageForceNewtons / newtonsPerPoundForce * 10).round())
        ..u16(18, stroke.strokeNumber))
      .bytes;

  static int _centi(Duration d) => (d.inMilliseconds / 10).round();

  // Unknown enum values have no PM5 code; send the neutral 0.
  static int _code(int code) => code < 0 ? 0 : code;
}

class _Bytes {
  _Bytes(int length) : bytes = Uint8List(length);

  final Uint8List bytes;

  void u8(int offset, int value) => bytes[offset] = value.clamp(0, 0xff);

  void u16(int offset, int value) {
    final v = value.clamp(0, 0xffff);
    bytes[offset] = v & 0xff;
    bytes[offset + 1] = v >> 8;
  }

  void u24(int offset, int value) {
    final v = value.clamp(0, 0xffffff);
    bytes[offset] = v & 0xff;
    bytes[offset + 1] = v >> 8 & 0xff;
    bytes[offset + 2] = v >> 16;
  }
}
