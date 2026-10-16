import 'dart:math' as math;
import 'dart:typed_data';

import 'pm5_characteristics.dart';
import '../raw_packet.dart';
import '../rowing_event.dart';
import '../workout.dart';

/// Turns PM5 notifications into [RowingEvent]s.
///
/// Stateful: the three status characteristics are merged into one
/// [StatusTick], and the two stroke data notifications per stroke into one
/// [Stroke]. Byte layouts are documented in the package README.
class Pm5Decoder {
  Pm5Decoder({this.onWarning});

  /// Receives a message for every packet that had to be dropped.
  final void Function(String message)? onWarning;

  static const _minLength = {
    Pm5Characteristics.generalStatus: 11,
    Pm5Characteristics.additionalStatus: 11,
    Pm5Characteristics.additionalStatus2: 8,
    Pm5Characteristics.strokeData: 20,
    Pm5Characteristics.additionalStrokeData: 9,
  };

  _General? _general;
  _Additional? _additional;
  _Additional2? _additional2;
  _General? _previousGeneral;

  _StrokePart? _pendingStroke;
  int? _lastEmittedStroke;
  (int count, int watts)? _strokePower;

  List<RowingEvent> decode(RawPacket packet) {
    var id = packet.characteristicId;
    var bytes = packet.bytes;

    if (id == Pm5Characteristics.multiplexed) {
      if (bytes.isEmpty) return _drop(packet, 'empty multiplexed packet');
      id = bytes[0].toRadixString(16).padLeft(4, '0');
      bytes = Uint8List.sublistView(bytes, 1);
    }

    final minLength = _minLength[id];
    if (minLength == null) return _drop(packet, 'unknown characteristic $id');
    if (bytes.length < minLength) return _drop(packet, '$id has ${bytes.length} bytes, expected $minLength');

    return switch (id) {
      Pm5Characteristics.generalStatus => _onStatusPart(_General.parse(bytes)),
      Pm5Characteristics.additionalStatus => _onStatusPart(_Additional.parse(bytes)),
      Pm5Characteristics.additionalStatus2 => _onStatusPart(_Additional2.parse(bytes)),
      Pm5Characteristics.strokeData => _onStrokeData(_StrokePart.parse(bytes)),
      _ => _onAdditionalStrokeData(bytes),
    };
  }

  /// Emits what is still buffered, e.g. at the end of a replay.
  List<RowingEvent> flush() => [..._flushStatus(), ..._flushStroke()];

  List<RowingEvent> _drop(RawPacket packet, String reason) {
    onWarning?.call('Dropped ${packet.characteristicId} packet at ${packet.time.inMilliseconds} ms: $reason');
    return const [];
  }

  // The PM5 sends 0x0031, 0x0032 and 0x0033 for the same moment in a row.
  // They are collected until all three are there, or until a part arrives
  // that belongs to the next moment.
  List<RowingEvent> _onStatusPart(_StatusPart part) {
    final slotTaken = switch (part) {
      _General() => _general != null,
      _Additional() => _additional != null,
      _Additional2() => _additional2 != null,
    };
    final groupElapsed = (_general ?? _additional ?? _additional2)?.elapsedRaw;
    final belongsToNext = slotTaken || groupElapsed != null && groupElapsed != part.elapsedRaw;

    final events = belongsToNext ? _flushStatus() : <RowingEvent>[];
    switch (part) {
      case _General():
        _general = part;
      case _Additional():
        _additional = part;
      case _Additional2():
        _additional2 = part;
    }
    if (_general != null && _additional != null && _additional2 != null) {
      events.addAll(_flushStatus());
    }
    return events;
  }

  List<RowingEvent> _flushStatus() {
    final general = _general;
    final additional = _additional;
    final additional2 = _additional2;
    _general = null;
    _additional = null;
    _additional2 = null;
    if (general == null) return [];

    final events = <RowingEvent>[];
    final previous = _previousGeneral;
    final elapsed = Duration(milliseconds: general.elapsedRaw * 10);
    if (previous == null) {
      events.add(WorkoutStateChanged(
          elapsed: elapsed, previous: WorkoutState.unknown, current: general.state, isReset: false));
    } else {
      final isReset = general.elapsedRaw < previous.elapsedRaw || general.distanceRaw < previous.distanceRaw;
      if (isReset) {
        _pendingStroke = null;
        _lastEmittedStroke = null;
        _strokePower = null;
      }
      if (isReset || general.state != previous.state) {
        events.add(WorkoutStateChanged(
            elapsed: elapsed, previous: previous.state, current: general.state, isReset: isReset));
      }
    }
    _previousGeneral = general;

    // When the rower stops, the closing stroke notification may never come.
    if (!general.isRowing) events.addAll(_flushStroke());

    final pace = general.isRowing && additional != null && additional.paceRaw > 0
        ? Duration(milliseconds: additional.paceRaw * 10)
        : null;
    events.add(StatusTick(
      elapsed: elapsed,
      distanceMeters: general.distanceRaw / 10,
      workoutType: general.type,
      workoutState: general.state,
      isRowing: general.isRowing,
      pace: pace,
      watts: pace == null ? null : wattsForPace(pace),
      strokeRate: additional?.strokeRate,
      heartRate: additional == null || additional.heartRate == 255 ? null : additional.heartRate,
      calories: additional2?.calories,
    ));
    return events;
  }

  // 0x0035 arrives twice per stroke: at the end of the drive (new stroke
  // number, recovery time of the previous stroke) and at the end of the
  // recovery (same number, final recovery time).
  List<RowingEvent> _onStrokeData(_StrokePart part) {
    final pending = _pendingStroke;
    if (pending == null) {
      // A closing notification for a stroke already emitted is ignored.
      if (part.count != _lastEmittedStroke) _pendingStroke = part;
      return const [];
    }
    // Either the closing notification of the pending stroke, or the opening
    // one of the next stroke; both carry the pending stroke's recovery time.
    _pendingStroke = part.count == pending.count ? null : part;
    return [_toStroke(pending, recoveryRaw: part.recoveryRaw)];
  }

  List<RowingEvent> _onAdditionalStrokeData(Uint8List bytes) {
    _strokePower = (_u16(bytes, 7), _u16(bytes, 3));
    return const [];
  }

  List<RowingEvent> _flushStroke() {
    final pending = _pendingStroke;
    _pendingStroke = null;
    return pending == null ? [] : [_toStroke(pending, recoveryRaw: pending.recoveryRaw)];
  }

  Stroke _toStroke(_StrokePart part, {required int recoveryRaw}) {
    _lastEmittedStroke = part.count;
    final power = _strokePower;
    return Stroke(
      elapsed: Duration(milliseconds: part.elapsedRaw * 10),
      strokeNumber: part.count,
      distanceMeters: part.distanceRaw / 10,
      driveLengthMeters: part.driveLengthRaw / 100,
      driveTime: Duration(milliseconds: part.driveTimeRaw * 10),
      recoveryTime: Duration(milliseconds: recoveryRaw * 10),
      peakForceNewtons: part.peakForceRaw / 10 * newtonsPerPoundForce,
      averageForceNewtons: part.averageForceRaw / 10 * newtonsPerPoundForce,
      watts: power != null && power.$1 == part.count ? power.$2 : null,
    );
  }
}

/// Power for a pace per 500 m, using the Concept2 formula P = 2.80 / (s/m)³.
int wattsForPace(Duration pacePer500m) {
  final secondsPerMeter = pacePer500m.inMicroseconds / Duration.microsecondsPerSecond / 500;
  return (2.80 / math.pow(secondsPerMeter, 3)).round();
}

int _u16(Uint8List b, int offset) => b[offset] | b[offset + 1] << 8;
int _u24(Uint8List b, int offset) => b[offset] | b[offset + 1] << 8 | b[offset + 2] << 16;

sealed class _StatusPart {
  const _StatusPart(this.elapsedRaw);

  final int elapsedRaw;
}

final class _General extends _StatusPart {
  const _General(super.elapsedRaw, this.distanceRaw, this.type, this.state, this.isRowing);

  factory _General.parse(Uint8List b) => _General(
        _u24(b, 0),
        _u24(b, 3),
        WorkoutType.fromCode(b[6]),
        WorkoutState.fromCode(b[8]),
        b[9] == 1,
      );

  final int distanceRaw;
  final WorkoutType type;
  final WorkoutState state;
  final bool isRowing;
}

final class _Additional extends _StatusPart {
  const _Additional(super.elapsedRaw, this.strokeRate, this.heartRate, this.paceRaw);

  factory _Additional.parse(Uint8List b) => _Additional(_u24(b, 0), b[5], b[6], _u16(b, 7));

  final int strokeRate;
  final int heartRate;
  final int paceRaw;
}

final class _Additional2 extends _StatusPart {
  const _Additional2(super.elapsedRaw, this.calories);

  factory _Additional2.parse(Uint8List b) => _Additional2(_u24(b, 0), _u16(b, 6));

  final int calories;
}

class _StrokePart {
  const _StrokePart({
    required this.elapsedRaw,
    required this.distanceRaw,
    required this.driveLengthRaw,
    required this.driveTimeRaw,
    required this.recoveryRaw,
    required this.peakForceRaw,
    required this.averageForceRaw,
    required this.count,
  });

  factory _StrokePart.parse(Uint8List b) => _StrokePart(
        elapsedRaw: _u24(b, 0),
        distanceRaw: _u24(b, 3),
        driveLengthRaw: b[6],
        driveTimeRaw: b[7],
        recoveryRaw: _u16(b, 8),
        peakForceRaw: _u16(b, 12),
        averageForceRaw: _u16(b, 14),
        count: _u16(b, 18),
      );

  final int elapsedRaw;
  final int distanceRaw;
  final int driveLengthRaw;
  final int driveTimeRaw;
  final int recoveryRaw;
  final int peakForceRaw;
  final int averageForceRaw;
  final int count;
}
