import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sessions/session_providers.dart';
import 'ranking.dart';
import 'ranking_repository.dart';

final rankingRepositoryProvider = Provider<RankingRepository>(
  (ref) => RankingRepository(ref.watch(databaseProvider)),
);

/// Places 1–3 of a course per length, the current length first.
final courseRankingsProvider = StreamProvider.family<List<Ranking>, int>((
  ref,
  courseId,
) {
  final repository = ref.watch(rankingRepositoryProvider);
  return repository.watch(
    () async => _podium(await repository.course(courseId)),
  );
});

/// Places 1–3 of a zone per length, the current length first.
final zoneRankingsProvider = StreamProvider.family<List<Ranking>, int>((
  ref,
  zoneId,
) {
  final repository = ref.watch(rankingRepositoryProvider);
  return repository.watch(() async => _podium(await repository.zone(zoneId)));
});

/// Places 1–3 of a workout per course length and number of laps, the
/// current ones first; empty for an open number of laps.
final workoutRankingsProvider = StreamProvider.family<List<Ranking>, int>((
  ref,
  workoutId,
) {
  final repository = ref.watch(rankingRepositoryProvider);
  return repository.watch(
    () async => _podium(await repository.workout(workoutId)),
  );
});

List<Ranking> _podium(List<Ranking> rankings) => [
  for (final r in rankings) r.top(3),
];
