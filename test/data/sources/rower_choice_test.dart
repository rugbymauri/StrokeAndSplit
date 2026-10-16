import 'package:aergrow/data/sources/ble/ble_rower_source.dart';
import 'package:aergrow/data/sources/ble/ble_transport.dart';
import 'package:aergrow/data/sources/rower_choice.dart';
import 'package:aergrow/data/sources/simulated_source.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_ble_transport.dart';

const _ftms = FoundRower(id: 'AA:BB:CC:DD:EE:FF', name: 'AergRow FTMS Rower', protocol: ErgProtocol.ftms);

void main() {
  test('a rower and both simulators survive storing', () {
    for (final choice in const [
      RowerChoice.device(_ftms),
      RowerChoice.simulator(),
      RowerChoice.simulator(ErgProtocol.ftms),
    ]) {
      expect(RowerChoice.decode(choice.encode()), choice);
    }
    final device = RowerChoice.decode(const RowerChoice.device(_ftms).encode())!.device!;
    expect((device.name, device.protocol), ('AergRow FTMS Rower', ErgProtocol.ftms));
  });

  test('nothing stored or something unreadable means no choice', () {
    expect(RowerChoice.decode(null), isNull);
    expect(RowerChoice.decode('{"simulator": "rowing"}'), isNull);
    expect(RowerChoice.decode('not json'), isNull);
  });

  test('creates the source of the choice and recognises it', () {
    final transport = FakeBleTransport();
    final rower = const RowerChoice.device(_ftms).createSource(transport);
    final simulator = const RowerChoice.simulator(ErgProtocol.ftms).createSource(transport);

    expect(rower, isA<BleRowerSource>());
    expect((simulator as SimulatedSource).protocol, ErgProtocol.ftms);
    expect(const RowerChoice.device(_ftms).isUsedBy(rower), isTrue);
    expect(const RowerChoice.simulator(ErgProtocol.ftms).isUsedBy(simulator), isTrue);
    expect(const RowerChoice.simulator().isUsedBy(simulator), isFalse);
    expect(const RowerChoice.simulator().isUsedBy(rower), isFalse);
  });

  test('remembers the choice in the store', () async {
    final store = MemoryRowerChoiceStore();
    final container = ProviderContainer(overrides: [rowerChoiceStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);

    expect(container.read(chosenRowerProvider), isNull);
    await container.read(chosenRowerProvider.notifier).choose(const RowerChoice.simulator(ErgProtocol.ftms));

    final restarted = ProviderContainer(overrides: [rowerChoiceStoreProvider.overrideWithValue(store)]);
    addTearDown(restarted.dispose);
    expect(restarted.read(chosenRowerProvider), const RowerChoice.simulator(ErgProtocol.ftms));
  });
}
