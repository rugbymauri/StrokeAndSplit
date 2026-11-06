import 'dart:async';

import 'package:clock/clock.dart';
import 'package:erg_protocol/erg_protocol.dart';

import 'erg_source.dart';
import 'resistance_control.dart';

/// Plays a recorded session back as if the rowing machine sent it again, at
/// original speed or faster.
class ReplaySource implements ErgSource {
  ReplaySource(this.recording, {this.speed = 1, String? name})
    : assert(speed > 0),
      name = name ?? 'Replay';

  final RawRecording recording;

  /// Playback speed factor, e.g. 10 for ten times as fast.
  final double speed;

  @override
  ResistanceControl? get resistanceControl => null;

  @override
  final String name;

  final _packets = StreamController<RawPacket>.broadcast();
  final _states = StreamController<ErgConnectionState>.broadcast();
  var _state = ErgConnectionState.disconnected;
  Timer? _timer;
  var _next = 0;
  DateTime? _startedAt;

  @override
  ErgSourceKind get kind => ErgSourceKind.replay;

  /// From the header of the recording; recordings without one are PM5 ones.
  @override
  ErgProtocol get protocol => ErgProtocol.parse(recording.metadata['protocol']);

  /// Only when the recording holds curve packets; older PM5 recordings have none.
  @override
  late final bool providesForceCurves =
      protocol == ErgProtocol.pm5 &&
      recording.packets.any(
        (p) => p.characteristicId == Pm5Characteristics.forceCurve,
      );

  @override
  Stream<RawPacket> get packets => _packets.stream;

  @override
  ErgConnectionState get connectionState => _state;

  @override
  Stream<ErgConnectionState> get connectionStates => _states.stream;

  @override
  Future<void> start() async {
    _startedAt = clock.now();
    _setState(ErgConnectionState.connected);
    _scheduleNext();
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _setState(ErgConnectionState.disconnected);
  }

  void _scheduleNext() {
    final packets = recording.packets;
    if (_next >= packets.length) {
      _setState(ErgConnectionState.disconnected);
      _packets.close();
      return;
    }
    final due =
        _scaled(packets[_next].time) - clock.now().difference(_startedAt!);
    _timer = Timer(due.isNegative ? Duration.zero : due, () {
      final elapsed = clock.now().difference(_startedAt!);
      // Emit everything that is due, so equal timestamps stay together.
      while (_next < packets.length &&
          _scaled(packets[_next].time) <= elapsed) {
        final p = packets[_next++];
        _packets.add(
          RawPacket(
            time: _scaled(p.time),
            characteristicId: p.characteristicId,
            bytes: p.bytes,
          ),
        );
      }
      _scheduleNext();
    });
  }

  Duration _scaled(Duration time) =>
      Duration(microseconds: (time.inMicroseconds / speed).round());

  void _setState(ErgConnectionState state) {
    if (_state == state) return;
    _state = state;
    _states.add(state);
  }
}
