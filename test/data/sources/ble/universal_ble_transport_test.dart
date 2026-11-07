import 'package:strokesplit/data/sources/ble/ble_transport.dart';
import 'package:strokesplit/data/sources/ble/universal_ble_transport.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ble/universal_ble.dart';

void main() {
  group('readinessForScanError', () {
    UniversalBleException error(UniversalBleErrorCode code) =>
        UniversalBleException(code: code, message: code.name);

    test('treats a refused Bluetooth access as a missing permission', () {
      expect(
        readinessForScanError(
          error(UniversalBleErrorCode.bluetoothUnauthorized),
        ),
        BluetoothReadiness.unauthorized,
      );
      expect(
        readinessForScanError(error(UniversalBleErrorCode.bluetoothNotAllowed)),
        BluetoothReadiness.unauthorized,
      );
    });

    test('treats a disabled adapter as Bluetooth off', () {
      expect(
        readinessForScanError(error(UniversalBleErrorCode.bluetoothNotEnabled)),
        BluetoothReadiness.off,
      );
      expect(
        readinessForScanError(
          error(UniversalBleErrorCode.bluetoothNotAvailable),
        ),
        BluetoothReadiness.off,
      );
    });

    test('reads the Android permission error from the message', () {
      expect(
        readinessForScanError(
          UniversalBleException(
            code: UniversalBleErrorCode.scanFailed,
            message: 'Permission android.permission.BLUETOOTH_SCAN required to scan devices',
          ),
        ),
        BluetoothReadiness.unauthorized,
      );
      expect(
        readinessForScanError(
          PlatformException(
            code: 'startScan',
            message: 'Permission android.permission.BLUETOOTH_SCAN required to scan devices',
          ),
        ),
        BluetoothReadiness.unauthorized,
      );
    });

    test('treats a switched-off adapter message as Bluetooth off', () {
      expect(
        readinessForScanError(
          PlatformException(
            code: 'startScan',
            message: 'Bluetooth must be turned on',
          ),
        ),
        BluetoothReadiness.off,
      );
    });

    test('leaves other errors alone', () {
      expect(
        readinessForScanError(error(UniversalBleErrorCode.failed)),
        isNull,
      );
      expect(
        readinessForScanError(
          PlatformException(code: 'startScan', message: 'something else'),
        ),
        isNull,
      );
      expect(readinessForScanError(StateError('busy')), isNull);
    });
  });

  group('shortCharacteristicId', () {
    test('takes the PM5 id from its own base UUID', () {
      expect(
        shortCharacteristicId('ce060031-43e5-11e4-916c-0800200c9a66'),
        '0031',
      );
    });

    test('takes the standard id from the Bluetooth base UUID', () {
      expect(
        shortCharacteristicId('00002ad1-0000-1000-8000-00805f9b34fb'),
        '2ad1',
      );
      expect(shortCharacteristicId('2A37'), '2a37');
    });
  });

  group('shortServiceId', () {
    test('shortens a UUID on the Bluetooth base UUID', () {
      expect(shortServiceId('0000180d-0000-1000-8000-00805f9b34fb'), '180d');
      expect(shortServiceId('1826'), '1826');
    });

    test('keeps a vendor UUID in full and in lower case', () {
      expect(
        shortServiceId('CE060030-43E5-11E4-916C-0800200C9A66'),
        'ce060030-43e5-11e4-916c-0800200c9a66',
      );
    });
  });
}
