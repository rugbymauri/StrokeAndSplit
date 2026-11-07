import 'dart:async';

import 'package:strokesplit/data/sources/ble/ble_transport.dart';
import 'package:strokesplit/data/sources/resistance_control.dart';
import 'package:strokesplit/data/sources/ble/ble_rower_source.dart';
import 'package:strokesplit/data/sources/ble/heart_rate_transport.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../../../support/fake_heart_rate_transport.dart';

const _pm5 = FoundRower(id: 'c0:00:00:00:00:01', name: 'PM5 430000001 Row');
const _ftms = FoundRower(
  id: 'aa:bb:cc:dd:ee:ff',
  name: 'Stroke & Split FTMS',
  protocol: ErgProtocol.ftms,
);

class _FakeControl implements ResistanceControl {
  @override
  ResistanceRange get range => const ResistanceRange(min: 1, max: 15);

  @override
  Future<ResistanceResult> setLevel(int level) async =>
      ResistanceResult.accepted;
}

class _FakeLink implements RowerLink {
  @override
  final ResistanceControl? resistanceControl = _FakeControl();

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
    if (!reachable) {
      throw const RowerConnectException(
        RowerConnectError.failed,
        message: 'not reachable',
      );
    }
    final link = _FakeLink();
    links.add(link);
    return link;
  }

  @override
  Future<BluetoothReadiness> readiness() async => BluetoothReadiness.ready;

  @override
  Stream<List<FoundRower>> scan({Duration timeout = Duration.zero}) =>
      const Stream.empty();
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

      expect(states, [
        ErgConnectionState.connecting,
        ErgConnectionState.connected,
      ]);
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
      expect(states, [
        ErgConnectionState.connecting,
        ErgConnectionState.disconnected,
      ]);
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

  test('offers the resistance control of the current link', () {
    fakeAsync((async) {
      expect(source.resistanceControl, isNull);
      source.start();
      async.flushMicrotasks();
      final first = source.resistanceControl;
      expect(first, same(transport.links.single.resistanceControl));

      transport.reachable = false;
      transport.links.single.drop();
      async.elapse(const Duration(seconds: 1));
      expect(
        source.resistanceControl,
        isNull,
        reason: 'none while reconnecting',
      );
      transport.reachable = true;
      async.elapse(const Duration(seconds: 3));

      expect(source.connectionState, ErgConnectionState.connected);
      expect(
        source.resistanceControl,
        same(transport.links.last.resistanceControl),
      );
      expect(source.resistanceControl, isNot(same(first)));
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
      expect(
        (ftms.kind, ftms.protocol, ftms.name),
        (ErgSourceKind.ftms, ErgProtocol.ftms, 'Stroke & Split FTMS'),
      );
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

  group('with a heart rate strap', () {
    const strap = FoundHeartRateMonitor(
      id: 'a0:9e:1a:12:34:56',
      name: 'Polar H10 1A2B3C4D',
    );
    late FakeHeartRateTransport straps;

    setUp(() => straps = FakeHeartRateTransport());

    /// Starts [rower], attaches a strap after 1 s and returns its link and
    /// the packets of the source.
    (FakeHeartRateLink, List<RawPacket>) startWithStrap(
      FakeAsync async,
      BleRowerSource rower,
    ) {
      final packets = <RawPacket>[];
      rower.packets.listen(packets.add);
      rower.start();
      async.elapse(const Duration(seconds: 1));
      straps
          .connectHeartRateMonitor(strap)
          .then((link) => rower.attachHeartRate(link.notifications));
      async.flushMicrotasks();
      return (straps.links.single, packets);
    }

    for (final device in [_pm5, _ftms]) {
      test(
        'puts strap packets on the time line of the ${device.protocol.name} rower',
        () {
          fakeAsync((async) {
            final rower = BleRowerSource(transport: transport, device: device);
            final (strapLink, packets) = startWithStrap(async, rower);
            final rowerId = device.protocol == ErgProtocol.pm5
                ? '0031'
                : '2ad1';

            async.elapse(const Duration(milliseconds: 500));
            transport.links.single.notify(rowerId, [1]);
            async.elapse(const Duration(milliseconds: 250));
            strapLink.notify([0x00, 72]);
            async.flushMicrotasks();

            expect(
              [for (final p in packets) (p.characteristicId, p.time)],
              [
                (rowerId, const Duration(milliseconds: 1500)),
                ('2a37', const Duration(milliseconds: 1750)),
              ],
            );
            expect(packets.last.bytes, [0x00, 72]);
          });
        },
      );
    }

    test('keeps the strap while the rower reconnects', () {
      fakeAsync((async) {
        final (strapLink, packets) = startWithStrap(async, source);

        transport.reachable = false;
        transport.links.single.drop();
        async.elapse(const Duration(seconds: 2));
        strapLink.notify([0x00, 70]);
        transport.reachable = true;
        async.elapse(const Duration(seconds: 3));
        strapLink.notify([0x00, 71]);
        async.flushMicrotasks();

        expect(source.connectionState, ErgConnectionState.connected);
        expect(transport.links, hasLength(2));
        expect(
          [for (final p in packets) (p.characteristicId, p.bytes[1], p.time)],
          [
            ('2a37', 70, const Duration(seconds: 3)),
            ('2a37', 71, const Duration(seconds: 6)),
          ],
        );
        expect(strapLink.disconnected, isFalse);
      });
    });

    test('forwards nothing from the strap once detached', () {
      fakeAsync((async) {
        final (strapLink, packets) = startWithStrap(async, source);

        source.detachHeartRate();
        strapLink.notify([0x00, 72]);
        async.flushMicrotasks();

        expect(packets, isEmpty);
      });
    });

    test('forwards only the strap attached last', () {
      fakeAsync((async) {
        final (first, packets) = startWithStrap(async, source);
        straps
            .connectHeartRateMonitor(strap)
            .then((link) => source.attachHeartRate(link.notifications));
        async.flushMicrotasks();

        first.notify([0x00, 60]);
        straps.links.last.notify([0x00, 80]);
        async.flushMicrotasks();

        expect([for (final p in packets) p.bytes[1]], [80]);
      });
    });
  });
}
