import 'package:erg_protocol/erg_protocol.dart';

import 'heart_rate_transport.dart';

/// Which strap an advertisement belongs to, or null for any other device.
///
/// [serviceIds] and the keys of [serviceData] are short ids in lower case,
/// e.g. `180d`. A PM5 or a fitness machine that also offers the Heart Rate
/// service is no strap, so rowers never show up among the straps. The
/// platforms ignore the scan filters in part, so every result goes through
/// here.
FoundHeartRateMonitor? heartRateMonitorFromAdvertisement({
  required String id,
  required String name,
  Iterable<String> serviceIds = const [],
  Map<String, List<int>> serviceData = const {},
}) {
  if (!serviceIds.contains(HeartRateIds.service)) return null;
  if (name.contains('PM5')) return null;
  if (serviceIds.contains(FtmsIds.service) || serviceData.containsKey(FtmsIds.service)) return null;
  return FoundHeartRateMonitor(id: id, name: name.isEmpty ? id : name);
}
