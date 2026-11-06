import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sessions/session_providers.dart';
import 'zone.dart';
import 'zone_repository.dart';

final zoneRepositoryProvider = Provider<ZoneRepository>(
  (ref) => ZoneRepository(ref.watch(databaseProvider)),
);

/// All zones that are not deleted, by axis and name, with their usage.
final zonesProvider = StreamProvider<List<ZoneUsage>>(
  (ref) => ref.watch(zoneRepositoryProvider).watchAllWithUsage(),
);
