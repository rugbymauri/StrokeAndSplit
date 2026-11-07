import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../courses/course.dart';
import '../courses/lap_tracker.dart';
import '../sessions/session_providers.dart';
import '../statistics/ranking.dart';
import '../statistics/ranking_providers.dart';
import '../sessions/session_plan.dart';
import 'ghost.dart';
import 'ghost_progress.dart';
import 'ghost_repository.dart';

final ghostRepositoryProvider = Provider<GhostRepository>(
  (ref) => GhostRepository(ref.watch(databaseProvider)),
);

/// The course of a ranking entry, loaded once per entry while it is in use.
final ghostTrackProvider = FutureProvider.autoDispose
    .family<GhostTrack?, RankingEntry>(
      (ref, entry) => ref.watch(ghostRepositoryProvider).track(entry),
    );

/// The ranking of a workout with this order of course lengths, joined by
/// commas so the key compares by value, and number of laps.
typedef WorkoutGhostKey = ({
  int workoutId,
  CourseAxis axis,
  int length,
  String chain,
  int laps,
});

/// The ranking of a course or a zone with this length.
typedef LengthGhostKey = ({int id, CourseAxis axis, int length});

/// The ghost of the outer track: place 1 of the workout with the length and
/// number of laps rowed now (Change ghost, Design D2). Null without such an
/// entry, without its course and while either is loading.
final workoutGhostProvider = Provider.autoDispose
    .family<GhostTrack?, WorkoutGhostKey>((ref, key) {
      final rankings = ref.watch(workoutRankingsProvider(key.workoutId)).value;
      return _placeOne(
        ref,
        rankings,
        key.axis,
        key.length,
        laps: key.laps,
        chain: key.chain,
      );
    });

/// The ghost of the lap track: place 1 of the course with the length rowed
/// now (Design D2).
final courseGhostProvider = Provider.autoDispose
    .family<GhostTrack?, LengthGhostKey>((ref, key) {
      final rankings = ref.watch(courseRankingsProvider(key.id)).value;
      return _placeOne(ref, rankings, key.axis, key.length);
    });

/// The ghost of the segment track: place 1 of the zone with the length it
/// has in the course rowed now (Design D2).
final zoneGhostProvider = Provider.autoDispose
    .family<GhostTrack?, LengthGhostKey>((ref, key) {
      final rankings = ref.watch(zoneRankingsProvider(key.id)).value;
      return _placeOne(ref, rankings, key.axis, key.length);
    });

/// What decides the ghosts of a running plan; see [liveGhostsKey]. Without
/// a workout there is no ghost of the workout (course-rowing-free, Design D5).
typedef LiveGhostsKey = ({
  int? workoutId,
  int? courseId,
  CourseAxis axis,
  int length,
  String chain,
  int? laps,
  int? zoneId,
  int segmentLength,
});

/// The key of [liveGhostsProvider] for [plan] at the moment of [progress];
/// it only changes from one segment to the next.
LiveGhostsKey liveGhostsKey(SessionPlan plan, LapProgress progress) => (
  workoutId: plan.workout?.id,
  // A lap of a chain runs several courses (Change workout-course-chain, D5).
  courseId: plan.courses.length == 1 ? plan.courses.single.id : null,
  axis: plan.axis,
  length: plan.definition.length,
  chain: plan.courses.map((c) => c.definition.length).join(','),
  laps: plan.plannedLaps,
  zoneId: progress.segment.zoneId,
  segmentLength: progress.segmentEnd - progress.segmentStart,
);

/// The three ghosts of a running workout, each place 1 of the ranking of its
/// track (Design D2): none outside with an open number of laps, none inside
/// in a free segment.
///
/// They follow the rankings live (Design D6). A lap or zone run of the running
/// session enters its ranking only once its lap is complete, so a new best
/// becomes the ghost in the next lap or run. Where the session comes from does
/// not matter, so the ghosts run in the simulator too; simulated sessions are
/// never ranked and so never ghosts.
final liveGhostsProvider = Provider.autoDispose
    .family<LiveGhosts, LiveGhostsKey>((ref, key) {
      final (workoutId, laps, zoneId) = (key.workoutId, key.laps, key.zoneId);
      final courseId = key.courseId;
      final workout = workoutId == null || laps == null
          ? null
          : (
              workoutId: workoutId,
              axis: key.axis,
              length: key.length,
              chain: key.chain,
              laps: laps,
            );
      return (
        course: workout == null
            ? null
            : ref.watch(workoutGhostProvider(workout)),
        lap: courseId == null
            ? null
            : ref.watch(
                courseGhostProvider((
                  id: courseId,
                  axis: key.axis,
                  length: key.length,
                )),
              ),
        segment: zoneId == null
            ? null
            : ref.watch(
                zoneGhostProvider((
                  id: zoneId,
                  axis: key.axis,
                  length: key.segmentLength,
                )),
              ),
      );
    });

/// The course of place 1 of the ranking in [rankings] with [axis], [length]
/// and [laps]; not simply the first ranking, which is the current length only
/// once that has entries.
GhostTrack? _placeOne(
  Ref ref,
  List<Ranking>? rankings,
  CourseAxis axis,
  int length, {
  int? laps,
  String? chain,
}) {
  final ranking = rankings
      ?.where(
        (r) =>
            r.axis == axis &&
            r.length == length &&
            r.laps == laps &&
            r.courseLengths?.join(',') == chain,
      )
      .firstOrNull;
  final entry = ranking?.entries.firstOrNull;
  return entry == null ? null : ref.watch(ghostTrackProvider(entry)).value;
}
