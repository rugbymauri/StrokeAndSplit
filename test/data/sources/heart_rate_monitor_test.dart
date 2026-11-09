import 'dart:async';

import 'package:strokesplit/app/platform_providers.dart';
import 'package:strokesplit/data/sources/ble/ble_rower_source.dart';
import 'package:strokesplit/data/sources/ble/ble_transport.dart';
import 'package:strokesplit/data/sources/resistance_control.dart';
import 'package:strokesplit/data/sources/ble/heart_rate_transport.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/sources/erg_source_providers.dart';
import 'package:strokesplit/data/sources/heart_rate_choice.dart';
import 'package:strokesplit/data/sources/heart_rate_monitor.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_erg_source.dart';
import '../../support/fake_heart_rate_transport.dart';

const _pm5 = FoundRower(id: 'C0:00:00:00:00:01', name: 'PM5 430000001 Row');
const _ftms = FoundRower(
  id: 'AA:BB:CC:DD:EE:FF',
  name: 'Stroke & Split FTMS',
  protocol: ErgProtocol.ftms,
);
const _h10 = FoundHeartRateMonitor(
  id: 'A0:9E:1A:12:34:56',
  name: 'Polar H10 1A2B3C4D',
);
const _tickr = FoundHeartRateMonitor(
  id: 'C1:11:22:33:44:55',
  name: 'TICKR 1234',
);

class _RowerLink implements RowerLink {
  @override
  ResistanceControl? get resistanceControl => null;

  final _lost = Completer<void>();
  final _notifications = StreamController<(String, List<int>)>.broadcast();
  var disconnected = false;

  @override
  Stream<(String, List<int>)> get notifications => _notifications.stream;

  /// Sends one FTMS Rower Data record with the rower's own heart rate.
  void heartRate(int bpm, {Duration at = Duration.zero}) {
    final packet = const FtmsEncoder().encode(
      RowerData(
        strokeRate: 24,
        totalDistance: 10,
        heartRate: bpm,
        elapsedTime: at,
      ),
      at: at,
    );
    _notifications.add((packet.characteristicId, packet.bytes));
  }

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
  Stream<List<FoundRower>> scan({Duration timeout = Duration.zero}) =>
      const Stream.empty();
}

const _busy = HeartRateConnectException(
  HeartRateConnectError.failed,
  message: 'busy',
);

void main() {
  late _RowerTransport rowers;
  late FakeHeartRateTransport straps;
  late ProviderContainer container;
  late List<HeartRateMonitorState> states;

  setUp(() {
    rowers = _RowerTransport();
    straps = FakeHeartRateTransport();
    container = ProviderContainer(
      overrides: [heartRateTransportProvider.overrideWithValue(straps)],
    );
    addTearDown(container.dispose);
    states = [];
  });

  HeartRateMonitorState state() => container.read(heartRateMonitorProvider);
  List<HeartRateMonitorPhase> phases() => [for (final s in states) s.phase];

  /// Watches the strap like the screens do, so the provider stays alive.
  void watch(FakeAsync async) {
    container.listen(
      heartRateMonitorProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    async.elapse(Duration.zero);
  }

  /// How long the strap waits for the rower's heart rate by default.
  const wait = Duration(seconds: 5);

  /// Pairs [monitor] and lets a connected rower's wait pass.
  void pair(FakeAsync async, FoundHeartRateMonitor monitor) {
    container.read(chosenHeartRateMonitorProvider.notifier).pair(monitor);
    async.elapse(wait);
  }

  /// Connects the rower without letting the wait for its heart rate pass.
  BleRowerSource connectRower(FakeAsync async, [FoundRower device = _pm5]) {
    final source = BleRowerSource(transport: rowers, device: device);
    container.read(activeErgSourceProvider.notifier).use(source);
    async.elapse(Duration.zero);
    return source;
  }

  /// Connects the rower and lets the wait pass, so a paired strap connects.
  BleRowerSource row(FakeAsync async, [FoundRower device = _pm5]) {
    final source = connectRower(async, device);
    async.elapse(wait);
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

      expect(
        (state().phase, state().monitor),
        (HeartRateMonitorPhase.ready, _h10),
      );
      expect(straps.attempts, isEmpty);
    });
  });

  for (final device in [_pm5, _ftms]) {
    test(
      'connects the strap once the ${device.protocol.name} rower is connected and feeds it in',
      () {
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
      },
    );
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
        container
            .read(activeErgSourceProvider.notifier)
            .use(FakeErgSource(kind: kind));
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
      expect(
        straps.attempts,
        hasLength(1),
        reason: 'a failed strap is only tried again on request',
      );
    });
  });

  test('reports a device without heart rate service', () {
    fakeAsync((async) {
      straps.connectError = const HeartRateConnectException(
        HeartRateConnectError.noHeartRateService,
      );
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

      expect(
        state(),
        isA<HeartRateMonitorState>().having(
          (s) => s.failure,
          'failure',
          isNull,
        ),
      );
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

      container
          .read(activeErgSourceProvider.notifier)
          .use(FakeErgSource(kind: ErgSourceKind.simulator));
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
      expect(
        (state().phase, state().monitor),
        (HeartRateMonitorPhase.connected, _tickr),
      );
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

  group('heart rate from the rower', () {
    test('waits 5 seconds before it connects the strap', () {
      fakeAsync((async) {
        pair(async, _h10);
        watch(async);
        connectRower(async, _ftms);

        async.elapse(const Duration(seconds: 4));
        expect(state().phase, HeartRateMonitorPhase.ready);
        expect(straps.attempts, isEmpty);

        async.elapse(const Duration(seconds: 1));
        expect(state().phase, HeartRateMonitorPhase.connected);
      });
    });

    test('connects no strap while the rower reports the heart rate', () {
      fakeAsync((async) {
        pair(async, _h10);
        watch(async);
        connectRower(async, _ftms);

        async.elapse(const Duration(seconds: 2));
        rowers.links.single.heartRate(95, at: const Duration(seconds: 2));
        async.elapse(const Duration(minutes: 1));

        expect(state().phase, HeartRateMonitorPhase.fromRower);
        expect(state().monitor, _h10);
        expect(straps.attempts, isEmpty);
      });
    });

    test('ignores a heart rate of 0 from the rower', () {
      fakeAsync((async) {
        pair(async, _h10);
        watch(async);
        connectRower(async, _ftms);

        rowers.links.single.heartRate(0);
        async.elapse(wait);

        expect(state().phase, HeartRateMonitorPhase.connected);
      });
    });

    test('ends a failed strap when the rower reports the heart rate', () {
      fakeAsync((async) {
        straps.connectError = _busy;
        pair(async, _h10);
        watch(async);
        row(async, _ftms);
        expect(state().phase, HeartRateMonitorPhase.disconnected);

        rowers.links.single.heartRate(95);
        async.elapse(Duration.zero);

        expect(state().phase, HeartRateMonitorPhase.fromRower);
        expect(straps.attempts, hasLength(1));
      });
    });

    test('discards a strap that connects after the rower reported', () {
      fakeAsync((async) {
        final link = Completer<HeartRateLink>();
        straps.pending = link;
        pair(async, _h10);
        watch(async);
        row(async, _ftms);
        expect(state().phase, HeartRateMonitorPhase.connecting);

        rowers.links.single.heartRate(95);
        async.elapse(Duration.zero);
        final strap = FakeHeartRateLink(_h10);
        link.complete(strap);
        async.elapse(Duration.zero);

        expect(state().phase, HeartRateMonitorPhase.fromRower);
        expect(strap.disconnected, isTrue);
      });
    });

    test('keeps a connected strap although the rower reports a heart rate', () {
      fakeAsync((async) {
        pair(async, _h10);
        watch(async);
        row(async, _ftms);

        rowers.links.single.heartRate(95);
        async.elapse(Duration.zero);

        expect(state().phase, HeartRateMonitorPhase.connected);
        expect(straps.links.single.disconnected, isFalse);
      });
    });

    test('treats a heart rate right after a strap drop as the strap\'s', () {
      fakeAsync((async) {
        pair(async, _h10);
        watch(async);
        row(async, _ftms);

        straps.connectError = _busy;
        straps.links.single.drop();
        async.elapse(const Duration(seconds: 1));
        rowers.links.single.heartRate(95);
        async.elapse(Duration.zero);
        expect(state().phase, HeartRateMonitorPhase.reconnecting);

        async.elapse(const Duration(seconds: 3));
        rowers.links.single.heartRate(95, at: const Duration(seconds: 4));
        async.elapse(Duration.zero);
        expect(state().phase, HeartRateMonitorPhase.fromRower);
      });
    });

    test('keeps the rower\'s heart rate while the rower reconnects', () {
      fakeAsync((async) {
        pair(async, _h10);
        watch(async);
        final source = connectRower(async, _ftms);
        rowers.links.single.heartRate(95);
        async.elapse(Duration.zero);

        rowers.links.single.drop();
        async.elapse(const Duration(seconds: 5));
        expect(source.connectionState, ErgConnectionState.connected);

        async.elapse(const Duration(minutes: 1));
        expect(state().phase, HeartRateMonitorPhase.fromRower);
        expect(straps.attempts, isEmpty);
      });
    });

    test('waits again when the rower is connected anew', () {
      fakeAsync((async) {
        pair(async, _h10);
        watch(async);
        connectRower(async, _ftms);
        rowers.links.single.heartRate(95);
        async.elapse(Duration.zero);

        container.read(activeErgSourceProvider.notifier).clear();
        async.elapse(Duration.zero);
        row(async, _ftms);

        expect(state().phase, HeartRateMonitorPhase.connected);
        expect(straps.attempts, [_h10]);
      });
    });
  });

  group('cancel', () {
    test('gives a failed strap up until the rower connects anew', () {
      fakeAsync((async) {
        straps.connectError = _busy;
        pair(async, _h10);
        watch(async);
        row(async, _ftms);

        container.read(heartRateMonitorProvider.notifier).cancel();
        async.elapse(Duration.zero);
        expect(state().phase, HeartRateMonitorPhase.cancelled);

        container.read(heartRateMonitorProvider.notifier).retry();
        async.elapse(const Duration(minutes: 5));
        expect(state().phase, HeartRateMonitorPhase.cancelled);
        expect(straps.attempts, hasLength(1));

        straps.connectError = null;
        container.read(activeErgSourceProvider.notifier).clear();
        async.elapse(Duration.zero);
        row(async, _ftms);
        expect(state().phase, HeartRateMonitorPhase.connected);
      });
    });

    test('cancels by itself after a minute without action', () {
      fakeAsync((async) {
        straps.connectError = _busy;
        pair(async, _h10);
        watch(async);
        row(async, _ftms);

        async.elapse(const Duration(seconds: 59));
        expect(state().phase, HeartRateMonitorPhase.disconnected);
        async.elapse(const Duration(seconds: 1));
        expect(state().phase, HeartRateMonitorPhase.cancelled);
      });
    });

    test('restarts the minute with a failed retry', () {
      fakeAsync((async) {
        straps.connectError = _busy;
        pair(async, _h10);
        watch(async);
        row(async, _ftms);

        async.elapse(const Duration(seconds: 40));
        container.read(heartRateMonitorProvider.notifier).retry();
        async.elapse(const Duration(seconds: 40));
        expect(state().phase, HeartRateMonitorPhase.disconnected);
        async.elapse(const Duration(seconds: 20));
        expect(state().phase, HeartRateMonitorPhase.cancelled);
      });
    });

    test('cancels a strap given up after 30 seconds a minute later', () {
      fakeAsync((async) {
        pair(async, _h10);
        watch(async);
        row(async, _ftms);

        straps.connectError = _busy;
        straps.links.single.drop();
        async.elapse(const Duration(minutes: 1));
        expect(state().phase, HeartRateMonitorPhase.disconnected);
        async.elapse(const Duration(seconds: 31));
        expect(state().phase, HeartRateMonitorPhase.cancelled);
      });
    });

    test('stays cancelled while the rower reconnects by itself', () {
      fakeAsync((async) {
        straps.connectError = _busy;
        pair(async, _h10);
        watch(async);
        final source = row(async, _ftms);
        container.read(heartRateMonitorProvider.notifier).cancel();
        async.elapse(Duration.zero);

        straps.connectError = null;
        rowers.links.single.drop();
        async.elapse(const Duration(seconds: 5));
        expect(source.connectionState, ErgConnectionState.connected);
        async.elapse(const Duration(minutes: 1));

        expect(state().phase, HeartRateMonitorPhase.cancelled);
        expect(straps.attempts, hasLength(1));
      });
    });

    test('ignores cancel while the strap is connected', () {
      fakeAsync((async) {
        pair(async, _h10);
        watch(async);
        row(async, _ftms);

        container.read(heartRateMonitorProvider.notifier).cancel();
        async.elapse(Duration.zero);

        expect(state().phase, HeartRateMonitorPhase.connected);
      });
    });
  });
}
