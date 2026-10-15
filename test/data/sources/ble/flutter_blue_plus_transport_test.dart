import 'package:aergrow/data/sources/ble/ble_transport.dart';
import 'package:aergrow/data/sources/ble/flutter_blue_plus_transport.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('treats the Android permission error of a scan as a missing permission', () {
    final error = PlatformException(
      code: 'startScan',
      message: 'Permission android.permission.BLUETOOTH_SCAN required to scan devices',
    );

    expect(readinessForScanError(error), BluetoothReadiness.unauthorized);
  });

  test('treats a switched-off adapter as Bluetooth off', () {
    final error = PlatformException(code: 'startScan', message: 'Bluetooth must be turned on');

    expect(readinessForScanError(error), BluetoothReadiness.off);
  });

  test('leaves other errors alone', () {
    expect(readinessForScanError(PlatformException(code: 'startScan', message: 'something else')), isNull);
    expect(readinessForScanError(StateError('busy')), isNull);
  });
}
