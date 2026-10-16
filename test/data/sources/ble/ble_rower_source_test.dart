import 'dart:async';

import 'package:aergrow/data/sources/ble/ble_transport.dart';
import 'package:aergrow/data/sources/ble/ble_rower_source.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erg_protocol/erg_protocol.dart';

const _pm5 = FoundRower(id: 'C0:00:00:00:00:01', name: 'PM5 430000001 Row');
const _ftms = FoundRower(id: 'AA:BB:CC:DD:EE:FF', name: 'AergRow FTMS Rower', protocol: ErgProtocol.ftms);

class _FakeLink implements RowerLink {
  final _notifications = StreamController<(String, List<int>)>.broadcast();
  final _lost = Completer<void>();
  var disconnected = false;

  @override
  Stream<(String, List<int>)> get notifications => _notifications.stream;

  @override
  Future<void> get lost => _lost.future;

  void drop() => _lost.complete();

  void notify(String id, List<int> bytes) => _notifications.add((id, bytes));

  @override
  Future<void> disconnect() async => disconnected = true;
}

class _FakeTransport implements BleTransport {
  /// Whether the PM5 is reachable; when not, connect attempts fail.
  var reachable = true;
  var connectAttempts = 0;
  final links = <_FakeLink>[];

  @override
  Future<RowerLink> connect(FoundRower device) async {
    connectAttempts++;
    if (!reachable) throw const RowerConnectException('not reachable');
    final link = _FakeLink();
    links.add(link);
    return link;
  }

  @override
  Future<BluetoothReadiness> readiness() async => BluetoothReadiness.ready;

  @override
  Stream<List<FoundRower>> scan({Duration timeout = Duration.zero}) => const Stream.empty();
}

void main() {
  late _FakeTransport transport;
  late BleRowerSource source;
  late List<ErgConnectionState> states;

  setUp(() {
    transport = _FakeTransport();
    source = BleRowerSource(transport: transport, device: _pm5);
    states = [];
    source.connectionStates.listen(states.add);
  });

  test('connects and reports the connection', () {
    fakeAsync((async) {
      source.start();
      async.flushMicrotasks();

      expect(states, [ErgConnectionState.connecting, ErgConnectionState.connected]);
      expect(source.name, 'PM5 430000001 Row');
      expect(source.kind, ErgSourceKind.pm5);
    });
  });

  test('reports a failed connection and stays disconnected', () {
    fakeAsync((async) {
      transport.reachable = false;
      Object? error;
      source.start().catchError((Object e) => error = e);
      async.flushMicrotasks();

      expect(error, isA<RowerConnectException>());
      expect(states, [ErgConnectionState.connecting, ErgConnectionState.disconnected]);
    });
  });

  test('forwards notifications with the time since the start', () {
    fakeAsync((async) {
      final packets = <RawPacket>[];
      source.packets.listen(packets.add);
      source.start();
      async.flushMicrotasks();

      async.elapse(const Duration(milliseconds: 1500));
      transport.links.single.notify('0031', [1, 2, 3]);
      async.flushMicrotasks();

      expect(packets.single.characteristicId, '0031');
      expect(packets.single.time, const Duration(milliseconds: 1500));
    });
  });

  test('reconnects without user action after a short drop', () {
    fakeAsync((async) {
      source.start();
      async.flushMicrotasks();

      transport.reachable = false;
      transport.links.single.drop();
      async.elapse(const Duration(seconds: 10));
      expect(source.connectionState, ErgConnectionState.reconnecting);

      transport.reachable = true;
      async.elapse(const Duration(seconds: 3));

      expect(source.connectionState, ErgConnectionState.connected);
      expect(states, [
        ErgConnectionState.connecting,
        ErgConnectionState.connected,
        ErgConnectionState.reconnecting,
        ErgConnectionState.connected,
      ]);
    });
  });

  test('keeps delivering data after reconnecting', () {
    fakeAsync((async) {
      final packets = <RawPacket>[];
      source.packets.listen(packets.add);
      source.start();
      async.flushMicrotasks();

      transport.links.single.drop();
      async.flushMicrotasks();
      transport.links.last.notify('0032', [9]);
      async.flushMicrotasks();

      expect(transport.links, hasLength(2));
      expect(packets.single.characteristicId, '0032');
    });
  });

  test('gives up after 30 seconds without reaching the PM5', () {
    fakeAsync((async) {
      source.start();
      async.flushMicrotasks();

      transport.reachable = false;
      transport.links.single.drop();
      async.elapse(const Duration(seconds: 29));
      expect(source.connectionState, ErgConnectionState.reconnecting);

      async.elapse(const Duration(seconds: 2));
      expect(source.connectionState, ErgConnectionState.disconnected);

      final attempts = transport.connectAttempts;
      async.elapse(const Duration(minutes: 1));
      expect(transport.connectAttempts, attempts);
    });
  });

  test('does not reconnect after a deliberate disconnect', () {
    fakeAsync((async) {
      source.start();
      async.flushMicrotasks();
      final link = transport.links.single;

      source.stop();
      async.flushMicrotasks();
      link.drop();
      async.elapse(const Duration(minutes: 1));

      expect(link.disconnected, isTrue);
      expect(transport.connectAttempts, 1);
      expect(source.connectionState, ErgConnectionState.disconnected);
    });
  });

  test('stops reconnecting when the user disconnects meanwhile', () {
    fakeAsync((async) {
      source.start();
      async.flushMicrotasks();

      transport.reachable = false;
      transport.links.single.drop();
      async.elapse(const Duration(seconds: 5));
      source.stop();
      async.flushMicrotasks();
      final attempts = transport.connectAttempts;
      async.elapse(const Duration(minutes: 1));

      expect(transport.connectAttempts, attempts);
      expect(source.connectionState, ErgConnectionState.disconnected);
    });
  });

  group('with an FTMS rower', () {
    late BleRowerSource ftms;

    setUp(() {
      ftms = BleRowerSource(transport: transport, device: _ftms);
      states = [];
      ftms.connectionStates.listen(states.add);
    });

    test('is an FTMS source', () {
      expect((ftms.kind, ftms.protocol, ftms.name), (ErgSourceKind.ftms, ErgProtocol.ftms, 'AergRow FTMS Rower'));
    });

    test('reconnects without user action after a short drop', () {
      fakeAsync((async) {
        final packets = <RawPacket>[];
        ftms.packets.listen(packets.add);
        ftms.start();
        async.flushMicrotasks();

        transport.reachable = false;
        transport.links.single.drop();
        async.elapse(const Duration(seconds: 10));
        expect(ftms.connectionState, ErgConnectionState.reconnecting);

        transport.reachable = true;
        async.elapse(const Duration(seconds: 3));
        transport.links.last.notify('2ad1', [0x2c, 0x09]);
        async.flushMicrotasks();

        expect(ftms.connectionState, ErgConnectionState.connected);
        expect(packets.single.characteristicId, '2ad1');
      });
    });

    test('does not reconnect after a deliberate disconnect', () {
      fakeAsync((async) {
        ftms.start();
        async.flushMicrotasks();
        final link = transport.links.single;

        ftms.stop();
        async.flushMicrotasks();
        link.drop();
        async.elapse(const Duration(minutes: 1));

        expect(link.disconnected, isTrue);
        expect(transport.connectAttempts, 1);
        expect(ftms.connectionState, ErgConnectionState.disconnected);
      });
    });
  });
}
