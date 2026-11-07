import 'dart:convert';

import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ble/ble_rower_source.dart';
import 'ble/ble_transport.dart';
import 'erg_source.dart';
import 'simulated_source.dart';

/// The rower chosen in "Geräte wählen": a rower found over Bluetooth or one
/// of the two simulators (ui-design, Design D6).
class RowerChoice {
  const RowerChoice.device(FoundRower this.device) : protocol = null;

  const RowerChoice.simulator([ErgProtocol this.protocol = ErgProtocol.pm5])
    : device = null;

  /// The rower over Bluetooth; null for a simulator.
  final FoundRower? device;

  /// Protocol of the simulator; null for a rower over Bluetooth.
  final ErgProtocol? protocol;

  bool get isSimulator => device == null;

  /// A new source for this choice, not yet started.
  ErgSource createSource(BleTransport transport) => switch (device) {
    final device? => BleRowerSource(transport: transport, device: device),
    null => SimulatedSource(protocol: protocol!),
  };

  /// Whether [source] is the rower of this choice.
  bool isUsedBy(ErgSource? source) => switch (source) {
    BleRowerSource(:final device) => device == this.device,
    SimulatedSource(:final protocol) =>
      isSimulator && protocol == this.protocol,
    _ => false,
  };

  String encode() => jsonEncode(switch (device) {
    final device? => {
      'id': device.id,
      'name': device.name,
      'protocol': device.protocol.name,
    },
    null => {'simulator': protocol!.name},
  });

  /// The choice stored as [value]; null when there is none or it cannot be read.
  static RowerChoice? decode(String? value) {
    if (value == null) return null;
    try {
      final map = jsonDecode(value) as Map<String, Object?>;
      if (map['simulator'] case final String simulator) {
        return RowerChoice.simulator(ErgProtocol.values.byName(simulator));
      }
      final protocol = ErgProtocol.values.byName(map['protocol']! as String);
      return RowerChoice.device(
        FoundRower(
          // Stored before universal_ble, an id may be an upper-case MAC.
          id: (map['id']! as String).toLowerCase(),
          name: map['name']! as String,
          protocol: protocol,
        ),
      );
    } on Object {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is RowerChoice &&
      other.protocol == protocol &&
      other.device?.id == device?.id;

  @override
  int get hashCode => Object.hash(protocol, device?.id);
}

/// Where the chosen rower is kept.
abstract interface class RowerChoiceStore {
  String? read();

  Future<void> write(String value);
}

/// Keeps the chosen rower in the shared preferences of the platform.
class PreferencesRowerChoiceStore implements RowerChoiceStore {
  PreferencesRowerChoiceStore._(this._preferences);

  static const _key = 'rower';

  final SharedPreferencesWithCache _preferences;

  static Future<PreferencesRowerChoiceStore> open() async {
    const options = SharedPreferencesWithCacheOptions(allowList: {_key});
    return PreferencesRowerChoiceStore._(
      await SharedPreferencesWithCache.create(cacheOptions: options),
    );
  }

  @override
  String? read() => _preferences.getString(_key);

  @override
  Future<void> write(String value) => _preferences.setString(_key, value);
}

/// Keeps the chosen rower in memory only; used in tests and until `main` has
/// opened the preferences.
class MemoryRowerChoiceStore implements RowerChoiceStore {
  MemoryRowerChoiceStore([RowerChoice? choice]) : _value = choice?.encode();

  String? _value;

  @override
  String? read() => _value;

  @override
  Future<void> write(String value) async => _value = value;
}

/// Where the chosen rower is kept; `main` sets the preferences.
final rowerChoiceStoreProvider = Provider<RowerChoiceStore>(
  (ref) => MemoryRowerChoiceStore(),
);

/// The rower chosen last, also across restarts; null before the first choice.
final chosenRowerProvider = NotifierProvider<ChosenRower, RowerChoice?>(
  ChosenRower.new,
);

class ChosenRower extends Notifier<RowerChoice?> {
  @override
  RowerChoice? build() =>
      RowerChoice.decode(ref.watch(rowerChoiceStoreProvider).read());

  /// Makes [choice] the rower for rowing and remembers it.
  Future<void> choose(RowerChoice choice) async {
    state = choice;
    await ref.read(rowerChoiceStoreProvider).write(choice.encode());
  }
}
