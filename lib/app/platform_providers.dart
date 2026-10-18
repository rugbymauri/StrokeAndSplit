import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/sources/ble/ble_transport.dart';
import '../data/sources/ble/flutter_blue_plus_transport.dart';
import '../data/sources/ble/heart_rate_transport.dart';

/// The one plugin transport behind [bleTransportProvider] and
/// [heartRateTransportProvider].
final _flutterBluePlusTransportProvider = Provider<FlutterBluePlusTransport>((ref) => FlutterBluePlusTransport());

/// Bluetooth access to rowers; replaced by a fake in tests.
final bleTransportProvider = Provider<BleTransport>((ref) => ref.watch(_flutterBluePlusTransportProvider));

/// Bluetooth access to heart rate straps; replaced by a fake in tests.
final heartRateTransportProvider =
    Provider<HeartRateTransport>((ref) => ref.watch(_flutterBluePlusTransportProvider));

/// Keeps the screen on; replaced by a fake in tests.
final wakelockProvider = Provider<Wakelock>((ref) => const PluginWakelock());

abstract interface class Wakelock {
  Future<void> enable();
  Future<void> disable();
}

class PluginWakelock implements Wakelock {
  const PluginWakelock();

  @override
  Future<void> enable() => WakelockPlus.enable();

  @override
  Future<void> disable() => WakelockPlus.disable();
}

/// Saving and opening session files; replaced by a fake in tests.
final sessionFilesProvider = Provider<SessionFiles>((ref) => const PluginSessionFiles());

abstract interface class SessionFiles {
  /// Hands the file to the user: the share dialog on phones, a save dialog
  /// on desktops. Returns false when the user cancelled.
  Future<bool> save(String fileName, List<int> bytes);

  /// Lets the user pick a file; null when cancelled.
  Future<List<int>?> open();
}

class PluginSessionFiles implements SessionFiles {
  const PluginSessionFiles();

  static bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  // Mobile pickers know no `.strokesplit` type, so they offer all files there.
  // `.aergrow` is the extension of exports from before the rename.
  static List<XTypeGroup> get _typeGroups => _isMobile
      ? const []
      : const [XTypeGroup(label: 'Stroke & Split Session', extensions: ['strokesplit', 'aergrow', 'jsonl'])];

  @override
  Future<bool> save(String fileName, List<int> bytes) async {
    if (_isMobile) {
      final file = File('${(await getTemporaryDirectory()).path}/$fileName');
      await file.writeAsBytes(bytes);
      final result = await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      return result.status != ShareResultStatus.dismissed;
    }
    final location = await getSaveLocation(suggestedName: fileName, acceptedTypeGroups: _typeGroups);
    if (location == null) return false;
    await File(location.path).writeAsBytes(bytes);
    return true;
  }

  @override
  Future<List<int>?> open() async {
    final file = await openFile(acceptedTypeGroups: _typeGroups);
    return file?.readAsBytes();
  }
}
