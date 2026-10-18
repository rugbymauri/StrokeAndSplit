import 'package:strokesplit/data/sources/ble/heart_rate_scan_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const id = 'A0:9E:1A:12:34:56';

  String? found(String name, {List<String> services = const [], Map<String, List<int>> data = const {}}) =>
      heartRateMonitorFromAdvertisement(id: id, name: name, serviceIds: services, serviceData: data)?.name;

  test('lists a device offering the heart rate service', () {
    expect(found('Polar H10 1A2B3C4D', services: ['180d']), 'Polar H10 1A2B3C4D');
  });

  test('names a strap without name by its id', () {
    expect(found('', services: ['180d']), id);
  });

  test('drops devices without heart rate service', () {
    expect(found('Polar H10 1A2B3C4D'), isNull);
    expect(found('Kopfhörer', services: ['110b']), isNull);
  });

  test('never lists a rower, even one offering the heart rate service', () {
    expect(found('PM5 430000001 Row', services: ['180d']), isNull);
    expect(found('AergRow FTMS Rower', services: ['1826', '180d']), isNull);
    expect(found('Bike', services: ['180d'], data: {'1826': [0x01, 0x20, 0x00]}), isNull);
  });
}
