// BLE spike: connects to a PM5, subscribes to the rowing characteristics and
// records every notification to a JSON lines file.
//
// Run with: flutter run -t lib/spike/spike_main.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'raw_log_writer.dart';

Guid _pm5Uuid(String shortId) => Guid('ce06$shortId-43e5-11e4-916c-0800200c9a66');

final _rowingService = _pm5Uuid('0030');
final _sampleRate = _pm5Uuid('0034');
const _subscribedIds = ['0031', '0032', '0033', '0035', '0036'];

/// PM5 sample rate values: 0 = 1 s, 1 = 500 ms, 2 = 250 ms, 3 = 100 ms.
const _sampleRate250ms = 2;

void main() => runApp(const MaterialApp(home: SpikeScreen()));

class SpikeScreen extends StatefulWidget {
  const SpikeScreen({super.key});

  @override
  State<SpikeScreen> createState() => _SpikeScreenState();
}

class _SpikeScreenState extends State<SpikeScreen> {
  final _log = <String>[];
  final _counts = <String, int>{};
  final _lastHex = <String, String>{};
  final _subscriptions = <StreamSubscription<List<int>>>[];
  final _found = <DeviceIdentifier, BluetoothDevice>{};
  BluetoothDevice? _device;
  RawLogWriter? _writer;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  void _say(String line) => setState(() => _log.insert(0, line));

  // The Linux backend ignores name filters, so filter here for all platforms.
  bool _isPm5(BluetoothDevice device) => device.platformName.startsWith('PM5');

  void _addFound(Iterable<BluetoothDevice> devices) {
    setState(() {
      for (final device in devices.where(_isPm5)) {
        _found[device.remoteId] = device;
      }
    });
  }

  Future<void> _scan() async {
    _say('Suche PM5 …');
    _scanSubscription ??= FlutterBluePlus.scanResults.listen((r) => _addFound(r.map((e) => e.device)));
    try {
      await FlutterBluePlus.startScan(withKeywords: ['PM5'], timeout: const Duration(seconds: 15));
      // The Linux backend only reports devices BlueZ discovers anew; a PM5
      // already in the BlueZ cache would never show up in the scan results.
      if (Platform.isLinux) {
        _addFound(await FlutterBluePlus.systemDevices([]));
      }
    } catch (e) {
      _say('Scan fehlgeschlagen: $e');
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    _say('Verbinde mit ${device.platformName} …');
    try {
      await device.connect(license: License.nonprofit);
      final services = await device.discoverServices();
      final rowing = services.firstWhere((s) => s.uuid == _rowingService);

      final rate = rowing.characteristics.where((c) => c.uuid == _sampleRate).firstOrNull;
      if (rate != null) {
        await rate.write([_sampleRate250ms]);
        _say('Sample Rate auf 250 ms gesetzt');
      } else {
        _say('Sample-Rate-Characteristic nicht gefunden');
      }

      final writer = await RawLogWriter.create(await _logDirectory(), deviceName: device.platformName);
      for (final id in _subscribedIds) {
        final characteristic = rowing.characteristics.where((c) => c.uuid == _pm5Uuid(id)).firstOrNull;
        if (characteristic == null) {
          _say('Characteristic $id fehlt');
          continue;
        }
        _subscriptions.add(characteristic.onValueReceived.listen((bytes) {
          writer.packet(id, bytes);
          setState(() {
            _counts[id] = (_counts[id] ?? 0) + 1;
            _lastHex[id] = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
          });
        }));
        await characteristic.setNotifyValue(true);
      }
      setState(() {
        _device = device;
        _writer = writer;
      });
      _say('Aufnahme läuft: ${writer.file.path}');
    } catch (e) {
      _say('Verbindung fehlgeschlagen: $e');
    }
  }

  Future<void> _stop() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    await _writer?.close();
    await _device?.disconnect();
    _say('Gestoppt. ${_writer?.packetCount ?? 0} Pakete in ${_writer?.file.path}');
    setState(() {
      _device = null;
      _writer = null;
    });
  }

  Future<Directory> _logDirectory() async {
    // On Android, the app-specific external directory is reachable via
    // `adb pull /sdcard/Android/data/ch.aergrow.aergrow/files/`.
    if (Platform.isAndroid) {
      final external = await getExternalStorageDirectory();
      if (external != null) return external;
    }
    return getApplicationDocumentsDirectory();
  }

  void _mark(String text) {
    _writer?.marker(text);
    _say('Marker: $text');
  }

  @override
  Widget build(BuildContext context) {
    final recording = _writer != null;
    return Scaffold(
      appBar: AppBar(title: const Text('PM5 BLE-Spike')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (!recording) FilledButton(onPressed: _scan, child: const Text('PM5 suchen')),
            if (recording) FilledButton(onPressed: _stop, child: const Text('Stopp & trennen')),
            for (final m in ['Start Rudern', 'Stopp Rudern', 'Weiter', 'PM5 Reset', 'Notiz'])
              OutlinedButton(onPressed: recording ? () => _mark(m) : null, child: Text(m)),
          ]),
          if (!recording)
            for (final device in _found.values)
              ListTile(
                title: Text(device.platformName),
                subtitle: Text(device.remoteId.str),
                onTap: () => _connect(device),
              ),
          if (recording)
            for (final id in _subscribedIds)
              ListTile(
                dense: true,
                title: Text('0x$id: ${_counts[id] ?? 0} Pakete'),
                subtitle: Text(_lastHex[id] ?? '–', style: const TextStyle(fontFamily: 'monospace')),
              ),
          const Divider(),
          for (final line in _log) Text(line),
        ],
      ),
    );
  }
}
