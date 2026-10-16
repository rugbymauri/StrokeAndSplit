import 'dart:async';

import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/sources/ble/ble_rower_source.dart';
import 'package:aergrow/data/sources/ble/ble_transport.dart';
import 'package:aergrow/data/sources/ble/heart_rate_transport.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/data/sources/heart_rate_choice.dart';
import 'package:aergrow/data/sources/heart_rate_monitor.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_erg_source.dart';
import '../../support/fake_heart_rate_transport.dart';

const _pm5 = FoundRower(id: 'C0:00:00:00:00:01', name: 'PM5 430000001 Row');
const _ftms = FoundRower(id: 'AA:BB:CC:DD:EE:FF', name: 'AergRow FTMS Rower', protocol: ErgProtocol.ftms);
const _h10 = FoundHeartRateMonitor(id: 'A0:9E:1A:12:34:56', name: 'Polar H10 1A2B3C4D');
const _tickr = FoundHeartRateMonitor(id: 'C1:11:22:33:44:55', name: 'TICKR 1234');

class _RowerLink implements RowerLink {
  final _lost = Completer<void>();
  var disconnected = false;

  @override
  Stream<(String, List<int>)> get notifications => const Stream.empty();

  @override
  Future<void> get lost => _lost.future;

  void drop() => _lost.complete();

  @override
  Future<void> disconnect() async => disconnected = true;
}

class _RowerTransport implements BleTransport {
  var reachable = true;
  var connectAttempts = 0;
  final links = <_RowerLink>[];

  @override
  Future<RowerLink> connect(FoundRower device) async {
    connectAttempts++;
    if (!reachable) throw const RowerConnectException(RowerConnectError.failed);
    final link = _RowerLink();
    links.add(link);
    return link;
  }

  @override
  Future<BluetoothReadiness> readiness() async => BluetoothReadiness.ready;

  @override
  Stream<List<FoundRower>> scan({Duration timeout = Duration.zero}) => const Stream.empty();
}

const _busy = HeartRateConnectException(HeartRateConnectError.failed, message: 'busy');

void main() {
  late _RowerTransport rowers;
  late FakeHeartRateTransport straps;
  late ProviderContainer container;
  late List<HeartRateMonitorState> states;

  setUp(() {
    rowers = _RowerTransport();
    straps = FakeHeartRateTransport();
    container = ProviderContainer(overrides: [heartRateTransportProvider.overrideWithValue(straps)]);
    addTearDown(container.dispose);
    states = [];
  });

  HeartRateMonitorState state() => container.read(heartRateMonitorProvider);
  List<HeartRateMonitorPhase> phases() => [for (final s in states) s.phase];

  /// Watches the strap like the screens do, so the provider stays alive.
  void watch(FakeAsync async) {
    container.listen(heartRateMonitorProvider, (_, next) => states.add(next), fireImmediately: true);
    async.elapse(Duration.zero);
  }

  void pair(FakeAsync async, FoundHeartRateMonitor monitor) {
    container.read(chosenHeartRateMonitorProvider.notifier).pair(monitor);
    async.elapse(Duration.zero);
  }

  BleRowerSource row(FakeAsync async, [FoundRower device = _pm5]) {
    final source = BleRowerSource(transport: rowers, device: device);
    container.read(activeErgSourceProvider.notifier).use(source);
    async.elapse(Duration.zero);
    return source;
  }

  test('stays not paired without a strap, even with a connected PM5', () {
    fakeAsync((async) {
      watch(async);
      row(async);

      expect(state(), const HeartRateMonitorState.notPaired());
      expect(straps.attempts, isEmpty);
    });
  });

  test('waits for a rower while a strap is paired', () {
    fakeAsync((async) {
      watch(async);
      pair(async, _h10);

      expect((state().phase, state().monitor), (HeartRateMonitorPhase.ready, _h10));
      expect(straps.attempts, isEmpty);
    });
  });

  for (final device in [_pm5, _ftms]) {
    test('connects the strap once the ${device.protocol.name} rower is connected and feeds it in', () {
      fakeAsync((async) {
        pair(async, _h10);
        watch(async);
        final source = row(async, device);
        final packets = <RawPacket>[];
        source.packets.listen(packets.add);

        straps.links.single.notify([0x00, 72]);
        async.elapse(Duration.zero);

        expect(phases(), [
          HeartRateMonitorPhase.ready,
          HeartRateMonitorPhase.connecting,
          HeartRateMonitorPhase.connected,
        ]);
        expect(straps.attempts, [_h10]);
        expect(packets.single.characteristicId, HeartRateIds.measurement);
      });
    });
  }

  test('connects a strap paired while the rower is already connected', () {
    fakeAsync((async) {
      watch(async);
      row(async);
      pair(async, _h10);

      expect(state().phase, HeartRateMonitorPhase.connected);
    });
  });

  for (final kind in [ErgSourceKind.simulator, ErgSourceKind.replay]) {
    test('connects no strap with the ${kind.name}', () {
      fakeAsync((async) {
        pair(async, _h10);
        watch(async);
        container.read(activeErgSourceProvider.notifier).use(FakeErgSource(kind: kind));
        async.elapse(const Duration(seconds: 5));

        expect(state().phase, HeartRateMonitorPhase.ready);
        expect(straps.attempts, isEmpty);
      });
    });
  }

  test('reports a busy strap and leaves the rower connected', () {
    fakeAsync((async) {
      straps.connectError = _busy;
      pair(async, _h10);
      watch(async);
      final source = row(async);

      expect(state().phase, HeartRateMonitorPhase.disconnected);
      expect(state().failure, HeartRateMonitorFailure.unreachable);
      expect(source.connectionState, ErgConnectionState.connected);
      expect(rowers.links.single.disconnected, isFalse);

      async.elapse(const Duration(minutes: 1));
      expect(straps.attempts, hasLength(1), reason: 'a failed strap is only tried again on request');
    });
  });

  test('reports a device without heart rate service', () {
    fakeAsync((async) {
      straps.connectError = const HeartRateConnectException(HeartRateConnectError.noHeartRateService);
      pair(async, _h10);
      watch(async);
      row(async);

      expect(state().failure, HeartRateMonitorFailure.noHeartRateService);
    });
  });

  test('tries again on request', () {
    fakeAsync((async) {
      straps.connectError = _busy;
      pair(async, _h10);
      watch(async);
      row(async);

      straps.connectError = null;
      container.read(heartRateMonitorProvider.notifier).retry();
      async.elapse(Duration.zero);

      expect(state(), isA<HeartRateMonitorState>().having((s) => s.failure, 'failure', isNull));
      expect(state().phase, HeartRateMonitorPhase.connected);
      expect(straps.attempts, hasLength(2));
    });
  });

  test('reconnects the strap after a short drop', () {
    fakeAsync((async) {
      pair(async, _h10);
      watch(async);
      final source = row(async);
      final packets = <RawPacket>[];
      source.packets.listen(packets.add);

      straps.connectError = _busy;
      straps.links.single.drop();
      async.elapse(const Duration(seconds: 10));
      expect(state().phase, HeartRateMonitorPhase.reconnecting);

      straps.connectError = null;
      async.elapse(const Duration(seconds: 3));
      straps.links.first.notify([0x00, 60]);
      straps.links.last.notify([0x00, 72]);
      async.elapse(Duration.zero);

      expect(state().phase, HeartRateMonitorPhase.connected);
      expect(straps.links, hasLength(2));
      expect([for (final p in packets) p.bytes[1]], [72]);
    });
  });

  test('gives the strap up after 30 seconds and leaves the rower alone', () {
    fakeAsync((async) {
      pair(async, _h10);
      watch(async);
      final source = row(async);

      straps.connectError = _busy;
      straps.links.single.drop();
      async.elapse(const Duration(seconds: 29));
      expect(state().phase, HeartRateMonitorPhase.reconnecting);
      async.elapse(const Duration(seconds: 2));

      expect(state().phase, HeartRateMonitorPhase.disconnected);
      expect(state().failure, HeartRateMonitorFailure.lost);
      expect(source.connectionState, ErgConnectionState.connected);
      expect(rowers.connectAttempts, 1);

      final attempts = straps.attempts.length;
      async.elapse(const Duration(minutes: 1));
      expect(straps.attempts, hasLength(attempts));
    });
  });

  test('keeps the strap while the rower reconnects', () {
    fakeAsync((async) {
      pair(async, _h10);
      watch(async);
      final source = row(async);

      rowers.reachable = false;
      rowers.links.single.drop();
      async.elapse(const Duration(seconds: 5));
      expect(source.connectionState, ErgConnectionState.reconnecting);
      expect(state().phase, HeartRateMonitorPhase.connected);

      rowers.reachable = true;
      async.elapse(const Duration(seconds: 3));

      expect(source.connectionState, ErgConnectionState.connected);
      expect(state().phase, HeartRateMonitorPhase.connected);
      expect(straps.attempts, hasLength(1));
      expect(straps.links.single.disconnected, isFalse);
    });
  });

  test('disconnects the strap when the rower is stopped on purpose', () {
    fakeAsync((async) {
      pair(async, _h10);
      watch(async);
      row(async);

      container.read(activeErgSourceProvider.notifier).clear();
      async.elapse(Duration.zero);

      expect(straps.links.single.disconnected, isTrue);
      expect(state().phase, HeartRateMonitorPhase.ready);
    });
  });

  test('disconnects the strap when the source changes', () {
    fakeAsync((async) {
      pair(async, _h10);
      watch(async);
      final first = row(async);
      final packets = <RawPacket>[];
      first.packets.listen(packets.add);
      final strap = straps.links.single;

      container.read(activeErgSourceProvider.notifier).use(FakeErgSource(kind: ErgSourceKind.simulator));
      async.elapse(Duration.zero);
      strap.notify([0x00, 72]);
      async.elapse(Duration.zero);

      expect(strap.disconnected, isTrue);
      expect(packets, isEmpty);
      expect(state().phase, HeartRateMonitorPhase.ready);
    });
  });

  test('disconnects a forgotten strap and connects none any more', () {
    fakeAsync((async) {
      pair(async, _h10);
      watch(async);
      row(async);

      container.read(chosenHeartRateMonitorProvider.notifier).forget();
      async.elapse(const Duration(minutes: 1));

      expect(straps.links.single.disconnected, isTrue);
      expect(state(), const HeartRateMonitorState.notPaired());
      expect(straps.attempts, hasLength(1));
    });
  });

  test('switches to another strap', () {
    fakeAsync((async) {
      pair(async, _h10);
      watch(async);
      row(async);
      pair(async, _tickr);

      expect(straps.links.first.disconnected, isTrue);
      expect(straps.links.last.monitor, _tickr);
      expect((state().phase, state().monitor), (HeartRateMonitorPhase.connected, _tickr));
    });
  });

  test('stops reconnecting the strap when the rower is stopped meanwhile', () {
    fakeAsync((async) {
      pair(async, _h10);
      watch(async);
      row(async);

      straps.connectError = _busy;
      straps.links.single.drop();
      async.elapse(const Duration(seconds: 5));
      container.read(activeErgSourceProvider.notifier).clear();
      async.elapse(Duration.zero);
      final attempts = straps.attempts.length;
      async.elapse(const Duration(minutes: 1));

      expect(straps.attempts, hasLength(attempts));
      expect(state().phase, HeartRateMonitorPhase.ready);
    });
  });
}
