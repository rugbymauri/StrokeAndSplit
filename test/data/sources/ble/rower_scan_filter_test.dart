import 'package:aergrow/data/sources/ble/rower_scan_filter.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const id = 'C0:00:00:00:00:01';
  const rower = [0x01, 0x10, 0x00];
  const bike = [0x01, 0x20, 0x00];

  (String, ErgProtocol)? found(String name, {List<String> services = const [], Map<String, List<int>>? data}) {
    final rower = rowerFromAdvertisement(id: id, name: name, serviceIds: services, serviceData: data ?? const {});
    return rower == null ? null : (rower.name, rower.protocol);
  }

  test('lists a PM5 on a RowErg', () {
    expect(found('PM5 430000001 Row'), ('PM5 430000001 Row', ErgProtocol.pm5));
    expect(found('PM5 430000001'), ('PM5 430000001', ErgProtocol.pm5));
  });

  test('drops a PM5 on a SkiErg or BikeErg', () {
    expect(found('PM5 430000001 Ski'), isNull);
    expect(found('PM5 430000001 Bike'), isNull);
  });

  test('lists a PM5 that also offers FTMS only as a PM5', () {
    expect(
      found('PM5 430000001 Row', services: ['1826'], data: {'1826': rower}),
      ('PM5 430000001 Row', ErgProtocol.pm5),
    );
  });

  test('lists an FTMS rower', () {
    expect(found('AergRow FTMS Rower', services: ['1826'], data: {'1826': rower}),
        ('AergRow FTMS Rower', ErgProtocol.ftms));
    expect(found('Rower', data: {'1826': rower}), ('Rower', ErgProtocol.ftms));
  });

  test('drops an FTMS machine that says it is no rower', () {
    expect(found('Indoor Bike', services: ['1826'], data: {'1826': bike}), isNull);
  });

  test('lists an FTMS machine without service data and checks it when connecting', () {
    expect(found('Rower 42', services: ['1826']), ('Rower 42', ErgProtocol.ftms));
    expect(found('Rower 42', services: ['1826'], data: {'1826': [0x01]}), ('Rower 42', ErgProtocol.ftms));
  });

  test('names an FTMS rower without name by its id', () {
    expect(found('', services: ['1826']), (id, ErgProtocol.ftms));
  });

  test('drops other devices', () {
    expect(found('Headphones'), isNull);
    expect(found('HRM', services: ['180d']), isNull);
    expect(found(''), isNull);
  });
}
