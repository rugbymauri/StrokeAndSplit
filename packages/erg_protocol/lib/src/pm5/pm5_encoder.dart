import 'dart:typed_data';

import 'pm5_characteristics.dart';
import '../raw_packet.dart';
import '../rowing_event.dart';

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
    final speedRaw = tick.pace == null
        ? 0
        : (500 / tick.pace!.inMilliseconds * 1000 * 1000).round();

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
      RawPacket(
        time: at,
        characteristicId: Pm5Characteristics.generalStatus,
        bytes: general.bytes,
      ),
      RawPacket(
        time: at,
        characteristicId: Pm5Characteristics.additionalStatus,
        bytes: additional.bytes,
      ),
      RawPacket(
        time: at,
        characteristicId: Pm5Characteristics.additionalStatus2,
        bytes: additional2.bytes,
      ),
    ];
  }

  /// The notifications at the end of the drive: stroke data and stroke power.
  List<RawPacket> encodeDriveEnd(Stroke stroke, {required Duration at}) => [
    RawPacket(
      time: at,
      characteristicId: Pm5Characteristics.strokeData,
      bytes: _strokeData(stroke),
    ),
    RawPacket(
      time: at,
      characteristicId: Pm5Characteristics.additionalStrokeData,
      bytes:
          (_Bytes(15)
                ..u24(0, _centi(stroke.elapsed))
                ..u16(3, stroke.watts ?? 0)
                ..u16(7, stroke.strokeNumber))
              .bytes,
    ),
  ];

  /// The notification at the end of the recovery, which completes the stroke.
  RawPacket encodeRecoveryEnd(Stroke stroke, {required Duration at}) =>
      RawPacket(
        time: at,
        characteristicId: Pm5Characteristics.strokeData,
        bytes: _strokeData(stroke),
      );

  /// The force curve notifications sent right after [encodeDriveEnd]: nine
  /// values in whole pound-force per packet, the last packet shorter.
  ///
  /// Throws an [ArgumentError] for an empty curve or one with more values than
  /// fit into 15 packets.
  List<RawPacket> encodeForceCurve(
    List<double> forcesNewtons, {
    required Duration at,
  }) {
    const perPacket = 9, maxPackets = 15;
    if (forcesNewtons.isEmpty ||
        forcesNewtons.length > perPacket * maxPackets) {
      throw ArgumentError.value(
        forcesNewtons.length,
        'forcesNewtons',
        'must hold 1 to ${perPacket * maxPackets} values',
      );
    }
    final total = (forcesNewtons.length / perPacket).ceil();
    return [
      for (var counter = 0; counter < total; counter++)
        RawPacket(
          time: at,
          characteristicId: Pm5Characteristics.forceCurve,
          bytes: _curvePacket(
            total,
            counter,
            forcesNewtons.skip(counter * perPacket).take(perPacket).toList(),
          ),
        ),
    ];
  }

  static Uint8List _curvePacket(
    int total,
    int counter,
    List<double> forcesNewtons,
  ) {
    final packet = _Bytes(2 + 2 * forcesNewtons.length)
      ..u8(0, total << 4 | forcesNewtons.length)
      ..u8(1, counter);
    for (final (i, force) in forcesNewtons.indexed) {
      packet.u16(2 + 2 * i, (force / newtonsPerPoundForce).round());
    }
    return packet.bytes;
  }

  Uint8List _strokeData(Stroke stroke) =>
      (_Bytes(20)
            ..u24(0, _centi(stroke.elapsed))
            ..u24(3, (stroke.distanceMeters * 10).round())
            ..u8(6, ((stroke.driveLengthMeters ?? 0) * 100).round())
            ..u8(7, _centi(stroke.driveTime ?? Duration.zero))
            ..u16(8, _centi(stroke.recoveryTime ?? Duration.zero))
            ..u16(
              12,
              ((stroke.peakForceNewtons ?? 0) / newtonsPerPoundForce * 10)
                  .round(),
            )
            ..u16(
              14,
              ((stroke.averageForceNewtons ?? 0) / newtonsPerPoundForce * 10)
                  .round(),
            )
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
