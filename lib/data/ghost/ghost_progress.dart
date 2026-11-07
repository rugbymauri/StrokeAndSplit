import '../courses/course.dart';
import '../courses/lap_tracker.dart';
import 'ghost.dart';

/// The ghosts of a running workout, one per track of the progress frame
/// (Change ghost, Design D2); null where a track has no ghost.
typedef LiveGhosts = ({
  GhostTrack? course,
  GhostTrack? lap,
  GhostTrack? segment,
});

/// Where each ghost is on its track, as shares from 0 to 1 like the
/// `FrameGhost` of the progress frame; null where a track has no ghost.
typedef GhostShares = ({double? course, double? lap, double? segment});

/// Where [ghosts] are on the tracks of [definition] at the moment of
/// [progress], as the progress frame places the rower (Design D3).
///
/// The ghost of the workout runs from the start of the first lap, the one of
/// the lap from the start of the current lap and the one of the zone from the
/// start of the current segment (Design D2). With an open number of laps the
/// outer track and with it its ghost is missing.
GhostShares ghostShares(
  LapProgress progress,
  CourseDefinition definition,
  LiveGhosts ghosts,
) {
  final axis = definition.axis;
  double? share(GhostTrack? ghost, Duration time, int length) =>
      ghost == null || length <= 0
      ? null
      : (ghost.positionAt(axis, time.inMilliseconds) / length).clamp(0, 1);

  final laps = progress.plannedLaps;
  return (
    course: laps == null
        ? null
        : share(ghosts.course, progress.courseTime, definition.length * laps),
    lap: share(ghosts.lap, progress.lapTime, definition.length),
    segment: share(
      ghosts.segment,
      progress.segmentTime,
      progress.segmentEnd - progress.segmentStart,
    ),
  );
}

/// How far the rower is from [ghost], the ghost of the workout, at the
/// moment of [progress] on a course with [axis] (Design D4): on a distance
/// axis the difference of the wall-clock times at the rower's distance, on a
/// time axis the difference of the distances at the rower's wall-clock time.
///
/// Null without a ghost and once the rower is further than the ghost ever got.
GhostGap? ghostGap(LapProgress progress, CourseAxis axis, GhostTrack? ghost) {
  if (ghost == null) return null;
  final wallMs = progress.courseTime.inMilliseconds;
  switch (axis) {
    case CourseAxis.distance:
      final ghostWallMs = ghost.wallMsAt(progress.courseDistanceDm);
      if (ghostWallMs == null) return null;
      final behindMs = wallMs - ghostWallMs;
      return GhostGap(
        axis: axis,
        amount: behindMs.abs() / 1000,
        ghostAhead: behindMs > 0,
      );
    case CourseAxis.time:
      final aheadDm = ghost.distanceDmAt(wallMs) - progress.courseDistanceDm;
      return GhostGap(
        axis: axis,
        amount: aheadDm.abs() / 10,
        ghostAhead: aheadDm > 0,
      );
  }
}
