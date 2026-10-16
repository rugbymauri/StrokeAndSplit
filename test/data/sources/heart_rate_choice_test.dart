import 'package:aergrow/data/sources/ble/heart_rate_transport.dart';
import 'package:aergrow/data/sources/heart_rate_choice.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _polar = FoundHeartRateMonitor(id: '11:22:33:44:55:66', name: 'Polar H10 1A2B3C4D');
const _garmin = FoundHeartRateMonitor(id: '66:55:44:33:22:11', name: 'HRM-Pro');

ProviderContainer _open(HeartRateMonitorStore store) {
  final container = ProviderContainer(overrides: [heartRateMonitorStoreProvider.overrideWithValue(store)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('a strap survives storing with id and name', () {
    final decoded = decodeHeartRateMonitor(encodeHeartRateMonitor(_polar))!;
    expect((decoded.id, decoded.name), (_polar.id, _polar.name));
  });

  test('nothing stored or something unreadable means no strap', () {
    expect(decodeHeartRateMonitor(null), isNull);
    expect(decodeHeartRateMonitor('{"id": "11:22"}'), isNull);
    expect(decodeHeartRateMonitor('not json'), isNull);
  });

  test('remembers the paired strap across reopening the store', () async {
    final store = MemoryHeartRateMonitorStore();
    final container = _open(store);

    expect(container.read(chosenHeartRateMonitorProvider), isNull);
    await container.read(chosenHeartRateMonitorProvider.notifier).pair(_polar);

    expect(_open(store).read(chosenHeartRateMonitorProvider)?.name, _polar.name);
  });

  test('pairing another strap replaces the one paired before', () async {
    final store = MemoryHeartRateMonitorStore(_polar);
    await _open(store).read(chosenHeartRateMonitorProvider.notifier).pair(_garmin);

    expect(_open(store).read(chosenHeartRateMonitorProvider), _garmin);
  });

  test('forgets the strap, also after reopening the store', () async {
    final store = MemoryHeartRateMonitorStore(_polar);
    final container = _open(store);
    expect(container.read(chosenHeartRateMonitorProvider), _polar);

    await container.read(chosenHeartRateMonitorProvider.notifier).forget();

    expect(container.read(chosenHeartRateMonitorProvider), isNull);
    expect(_open(store).read(chosenHeartRateMonitorProvider), isNull);
  });
}
