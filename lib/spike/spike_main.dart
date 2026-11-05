// BLE spike: connects to a PM5 or an FTMS rower, subscribes to the rowing
// characteristics and records every notification to a JSON lines file.
// On an FTMS rower it also shows whether the resistance can be set and tries
// to set it on the control point, in the encodings devices use.
//
// Run with: flutter run -t lib/spike/spike_main.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../data/sources/ble/ble_transport.dart';
import '../data/sources/ble/rower_scan_filter.dart';
import 'raw_log_writer.dart';

Guid _pm5Uuid(String shortId) => Guid('ce06$shortId-43e5-11e4-916c-0800200c9a66');

final _rowingService = _pm5Uuid('0030');
final _sampleRate = _pm5Uuid('0034');

/// `003d` is the force curve (change `force-curve`); a PM5 without it is
/// reported as missing and the recording continues.
const _subscribedIds = ['0031', '0032', '0033', '0035', '0036', '003d'];

final _ftmsService = Guid(FtmsIds.service);

/// Recorded FTMS characteristics: rower data, machine status and the answers
/// on the control point (Design D12).
const _ftmsIds = [FtmsIds.rowerData, FtmsIds.machineStatus, FtmsIds.controlPoint];

/// Supported Resistance Level Range: minimum and maximum (s16) and increment
/// (u16), each in steps of 0.1.
const _resistanceRangeId = '2ad6';

/// Control point op codes.
const _requestControl = 0x00;
const _setTargetResistance = 0x04;
const _startOrResume = 0x07;
const _responseCode = 0x80;

const _resultNames = {
  0x01: 'Erfolg',
  0x02: 'nicht unterstützt',
  0x03: 'ungültiger Wert',
  0x04: 'fehlgeschlagen',
  0x05: 'Steuerung nicht erlaubt',
};

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
  final _found = <String, FoundRower>{};
  BluetoothDevice? _device;
  var _recordedIds = _subscribedIds;
  RawLogWriter? _writer;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  BluetoothCharacteristic? _controlPoint;
  var _level = 5;
  int? _reportedLevel;

  void _say(String line) => setState(() => _log.insert(0, line));

  // Same filter as the app: PM5 by name, FTMS rowers by service.
  void _addFound(Iterable<FoundRower?> rowers) {
    setState(() {
      for (final rower in rowers.nonNulls) {
        _found[rower.id] = rower;
      }
    });
  }

  Future<void> _scan() async {
    _say('Suche Rudergeräte …');
    _scanSubscription ??= FlutterBluePlus.scanResults.listen(
      (results) => _addFound(
        results.map((r) {
          final data = r.advertisementData;
          return rowerFromAdvertisement(
            id: r.device.remoteId.str,
            name: r.device.platformName.isNotEmpty ? r.device.platformName : data.advName,
            serviceIds: [for (final uuid in data.serviceUuids) uuid.str.toLowerCase()],
            serviceData: {for (final MapEntry(:key, :value) in data.serviceData.entries) key.str.toLowerCase(): value},
          );
        }),
      ),
    );
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      // The Linux backend only reports devices BlueZ discovers anew; a PM5
      // already in the BlueZ cache would never show up in the scan results.
      if (Platform.isLinux) {
        final cached = await FlutterBluePlus.systemDevices([]);
        _addFound(cached.map((d) => rowerFromAdvertisement(id: d.remoteId.str, name: d.platformName)));
      }
    } catch (e) {
      _say('Scan fehlgeschlagen: $e');
    }
  }

  Future<void> _connect(FoundRower rower) async {
    await FlutterBluePlus.stopScan();
    final device = BluetoothDevice.fromId(rower.id);
    _say('Verbinde mit ${rower.name} …');
    try {
      await device.connect(license: License.nonprofit);
      final services = await device.discoverServices();
      final writer = await RawLogWriter.create(
        await _logDirectory(),
        deviceName: rower.name,
        protocol: rower.protocol.name,
      );
      switch (rower.protocol) {
        case ErgProtocol.pm5:
          await _recordPm5(services, writer);
        case ErgProtocol.ftms:
          await _recordFtms(services, writer);
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

  Future<void> _recordPm5(List<BluetoothService> services, RawLogWriter writer) async {
    final rowing = services.firstWhere((s) => s.uuid == _rowingService);
    final rate = rowing.characteristics.where((c) => c.uuid == _sampleRate).firstOrNull;
    if (rate != null) {
      await rate.write([_sampleRate250ms]);
      _say('Sample Rate auf 250 ms gesetzt');
    } else {
      _say('Sample-Rate-Characteristic nicht gefunden');
    }
    _recordedIds = _subscribedIds;
    for (final id in _subscribedIds) {
      await _record(rowing.characteristics.where((c) => c.uuid == _pm5Uuid(id)).firstOrNull, id, writer);
    }
  }

  Future<void> _recordFtms(List<BluetoothService> services, RawLogWriter writer) async {
    final ftms = services.firstWhere((s) => s.uuid == _ftmsService);
    BluetoothCharacteristic? characteristic(String id) =>
        ftms.characteristics.where((c) => c.uuid == Guid(id)).firstOrNull;

    final feature = characteristic(FtmsIds.feature);
    if (feature != null) {
      final bytes = await feature.read();
      writer.marker('Fitness Machine Feature: ${_hex(bytes)}');
      _say('Feature: ${_hex(bytes)}');
      if (bytes.length >= 8) {
        final machine = _u32(bytes, 0);
        final target = _u32(bytes, 4);
        _say(
          'Stufe wird gemeldet: ${_yesNo(machine & (1 << 7) != 0)}, '
          'Stufe setzbar: ${_yesNo(target & (1 << 2) != 0)}',
        );
      }
    }
    final range = characteristic(_resistanceRangeId);
    if (range == null) {
      _say('Stufenbereich (0x$_resistanceRangeId) fehlt');
    } else {
      final bytes = await range.read();
      writer.marker('Supported Resistance Level Range: ${_hex(bytes)}');
      if (bytes.length >= 6) {
        _say(
          'Stufenbereich: ${_s16(bytes, 0) / 10} bis ${_s16(bytes, 2) / 10}, '
          'Schritt ${_u16(bytes, 4) / 10} (${_hex(bytes)})',
        );
      } else {
        _say('Stufenbereich: ${_hex(bytes)}');
      }
    }
    _recordedIds = _ftmsIds;
    for (final id in _ftmsIds) {
      await _record(characteristic(id), id, writer);
    }
    // Same requests as the app: Request Control, then Start or Resume (D7).
    final controlPoint = characteristic(FtmsIds.controlPoint);
    if (controlPoint != null) {
      await controlPoint.write([_requestControl]);
      await Future<void>.delayed(const Duration(seconds: 1));
      await controlPoint.write([_startOrResume]);
      _say('Control Point: Request Control und Start gesendet');
    } else {
      _say('Control Point fehlt, die Stufe lässt sich nicht setzen');
    }
    setState(() => _controlPoint = controlPoint);
  }

  /// Writes [bytes] to the control point; the answer shows up in the log.
  Future<void> _send(String what, List<int> bytes) async {
    final controlPoint = _controlPoint;
    if (controlPoint == null) return;
    _writer?.marker('$what: ${_hex(bytes)}');
    _say('Sende $what: ${_hex(bytes)}');
    try {
      await controlPoint.write(bytes);
    } catch (e) {
      _say('Schreiben fehlgeschlagen: $e');
    }
  }

  /// The encodings of Set Target Resistance Level seen in the wild: FTMS 1.0
  /// has a u8 in steps of 0.1, later versions an s16; some rowers take the
  /// level as it is.
  List<(String, List<int>)> _resistanceVariants(int level) {
    final tenths = level * 10;
    return [
      ('u8 ×10', [_setTargetResistance, tenths & 0xFF]),
      ('s16 ×10', [_setTargetResistance, tenths & 0xFF, tenths >> 8 & 0xFF]),
      ('u8 Stufe', [_setTargetResistance, level & 0xFF]),
      ('s16 Stufe', [_setTargetResistance, level & 0xFF, level >> 8 & 0xFF]),
    ];
  }

  void _onPacket(String id, List<int> bytes) {
    switch (id) {
      case FtmsIds.rowerData:
        final level = RowerData.parse(Uint8List.fromList(bytes))?.resistanceLevel;
        if (level != null && level != _reportedLevel) setState(() => _reportedLevel = level);
      case FtmsIds.controlPoint when bytes.length >= 3 && bytes[0] == _responseCode:
        final result = _resultNames[bytes[2]] ?? 'Code ${bytes[2]}';
        _say('Antwort auf 0x${bytes[1].toRadixString(16).padLeft(2, '0')}: $result (${_hex(bytes)})');
      case FtmsIds.machineStatus:
        _say('Machine Status: ${_hex(bytes)}');
    }
  }

  Future<void> _record(BluetoothCharacteristic? characteristic, String id, RawLogWriter writer) async {
    if (characteristic == null) {
      _say('Characteristic $id fehlt');
      return;
    }
    _subscriptions.add(
      characteristic.onValueReceived.listen((bytes) {
        writer.packet(id, bytes);
        _onPacket(id, bytes);
        setState(() {
          _counts[id] = (_counts[id] ?? 0) + 1;
          _lastHex[id] = _hex(bytes);
        });
      }),
    );
    await characteristic.setNotifyValue(true);
  }

  static String _hex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  static int _u16(List<int> b, int i) => b[i] | b[i + 1] << 8;
  static int _s16(List<int> b, int i) => _u16(b, i).toSigned(16);
  static int _u32(List<int> b, int i) => _u16(b, i) | _u16(b, i + 2) << 16;
  static String _yesNo(bool value) => value ? 'ja' : 'nein';

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
      _controlPoint = null;
      _reportedLevel = null;
    });
  }

  Future<Directory> _logDirectory() async {
    // On Android, the app-specific external directory is reachable via
    // `adb pull /sdcard/Android/data/ch.strokesplit.strokesplit/files/`.
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
      appBar: AppBar(title: const Text('BLE-Spike')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!recording) FilledButton(onPressed: _scan, child: const Text('Rudergerät suchen')),
              if (recording) FilledButton(onPressed: _stop, child: const Text('Stopp & trennen')),
              for (final m in ['Start Rudern', 'Stopp Rudern', 'Weiter', 'PM5 Reset', 'Notiz'])
                OutlinedButton(onPressed: recording ? () => _mark(m) : null, child: Text(m)),
            ],
          ),
          if (!recording)
            for (final rower in _found.values)
              ListTile(
                title: Text(rower.name),
                subtitle: Text('${rower.protocol.name.toUpperCase()} · ${rower.id}'),
                onTap: () => _connect(rower),
              ),
          if (recording && _controlPoint != null) ..._resistanceControls(),
          if (recording)
            for (final id in _recordedIds)
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

  List<Widget> _resistanceControls() => [
    const Divider(),
    Text('Widerstand (gemeldet: ${_reportedLevel ?? '–'})', style: Theme.of(context).textTheme.titleMedium),
    Row(
      children: [
        IconButton(onPressed: _level > 1 ? () => setState(() => _level--) : null, icon: const Icon(Icons.remove)),
        Text('Stufe $_level'),
        IconButton(onPressed: () => setState(() => _level++), icon: const Icon(Icons.add)),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => _send('Request Control', [_requestControl]),
          child: const Text('Request Control'),
        ),
      ],
    ),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (name, bytes) in _resistanceVariants(_level))
          FilledButton.tonal(
            onPressed: () => _send('Stufe $_level als $name', bytes),
            child: Text('$name (${_hex(bytes)})'),
          ),
      ],
    ),
  ];
}
