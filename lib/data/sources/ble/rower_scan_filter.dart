import 'package:erg_protocol/erg_protocol.dart';

import 'ble_transport.dart';

/// Which rower an advertisement belongs to, or null for any other device
/// (Design D5).
///
/// [serviceIds] and the keys of [serviceData] are short ids in lower case,
/// e.g. `1826`. The platforms ignore the scan filters in part, so every
/// result goes through here.
FoundRower? rowerFromAdvertisement({
  required String id,
  required String name,
  Iterable<String> serviceIds = const [],
  Map<String, List<int>> serviceData = const {},
}) {
  if (name.contains('PM5')) {
    // A PM5 on a SkiErg or BikeErg says so in its name. A PM5 that also
    // offers FTMS is always listed as a PM5.
    if (name.endsWith(' Ski') || name.endsWith(' Bike')) return null;
    return FoundRower(id: id, name: name);
  }
  final data = serviceData[FtmsIds.service];
  if (data == null && !serviceIds.contains(FtmsIds.service)) return null;
  // Service data: flags, then the 16-bit Fitness Machine Type. Without it the
  // check happens when connecting.
  if (data != null && data.length >= 3) {
    final type = data[1] | data[2] << 8;
    if (type & 1 << FtmsIds.rowerTypeBit == 0) return null;
  }
  return FoundRower(
    id: id,
    name: name.isEmpty ? id : name,
    protocol: ErgProtocol.ftms,
  );
}
