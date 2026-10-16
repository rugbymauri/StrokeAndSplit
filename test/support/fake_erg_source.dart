import 'dart:async';

import 'package:aergrow/data/sources/erg_source.dart';
import 'package:erg_protocol/erg_protocol.dart';

/// An [ErgSource] driven by the test.
class FakeErgSource implements ErgSource {
  FakeErgSource({this.kind = ErgSourceKind.pm5, this.name = 'PM5 Test', this.protocol = ErgProtocol.pm5});

  @override
  final ErgSourceKind kind;

  @override
  final ErgProtocol protocol;

  @override
  final String name;

  final _packets = StreamController<RawPacket>.broadcast();
  final _states = StreamController<ErgConnectionState>.broadcast();
  var started = false;
  var stopped = false;

  @override
  ErgConnectionState connectionState = ErgConnectionState.disconnected;

  @override
  Stream<RawPacket> get packets => _packets.stream;

  @override
  Stream<ErgConnectionState> get connectionStates => _states.stream;

  void emit(RawPacket packet) => _packets.add(packet);

  void setState(ErgConnectionState state) {
    connectionState = state;
    _states.add(state);
  }

  @override
  Future<void> start() async {
    started = true;
    setState(ErgConnectionState.connected);
  }

  @override
  Future<void> stop() async {
    stopped = true;
    setState(ErgConnectionState.disconnected);
  }
}
