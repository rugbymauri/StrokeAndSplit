import 'package:flutter/foundation.dart' show immutable;

import '../../data/courses/course.dart';
import '../../data/courses/lap_tracker.dart';

/// One track of the progress frame: how much of it is filled, where its
/// notches sit and which parts of it are zones, all as shares from 0 to 1.
@immutable
class FrameTrack {
  const FrameTrack({
    required this.share,
    required this.boundaries,
    this.zones = const [],
  });

  final double share;
  final List<double> boundaries;

  /// Start and end of each zone on the track, drawn brighter than the free parts.
  final List<(double, double)> zones;
}

/// What the progress frame around the pace shows (ui-design, Design D3):
/// the course over all laps, the lap and the current part of the course,
/// with what is left of each in the unit of the course, metres or seconds.
/// Rowed for a total time, the outer track is that time instead
/// (course-rowing-free, Design D4).
@immutable
class ProgressFrameModel {
  const ProgressFrameModel({
    required this.course,
    required this.lap,
    required this.segment,
    required this.courseDone,
    required this.courseLength,
    required this.lapRemaining,
    required this.segmentRemaining,
    this.timeRemaining,
  });

  /// From the state of the lap tracker on [definition]; with a [limit] the
  /// outer track is the [rowed] time without pauses of that limit.
  factory ProgressFrameModel.of(
    LapProgress progress,
    CourseDefinition definition, {
    Duration rowed = Duration.zero,
    Duration? limit,
  }) {
    final length = definition.length;
    final inLap = (progress.segmentEnd - progress.remaining)
        .clamp(0, length)
        .toDouble();
    final segmentLength = progress.segmentEnd - progress.segmentStart;
    final ends = definition.segmentEnds;
    final lap = FrameTrack(
      share: _share(inLap, length),
      boundaries: [for (final end in ends.take(ends.length - 1)) end / length],
      zones: [
        for (var i = 0; i < definition.segments.length; i++)
          if (!definition.segments[i].isFree)
            (definition.segmentStarts[i] / length, ends[i] / length),
      ],
    );
    final segment = FrameTrack(
      share: segmentLength > 0
          ? _share(inLap - progress.segmentStart, segmentLength)
          : 1,
      boundaries: const [],
    );
    if (limit != null) {
      final left = limit - rowed;
      return ProgressFrameModel(
        // The number of laps is open, so the track has no notches.
        course: FrameTrack(
          share: _share(rowed.inMilliseconds.toDouble(), limit.inMilliseconds),
          boundaries: const [],
        ),
        lap: lap,
        segment: segment,
        courseDone: null,
        courseLength: null,
        lapRemaining: length - inLap,
        segmentRemaining: progress.remaining,
        timeRemaining: left.isNegative ? Duration.zero : left,
      );
    }
    final laps = progress.plannedLaps;
    // With an open number of laps the whole length is unknown.
    if (laps == null) {
      return ProgressFrameModel(
        course: null,
        lap: lap,
        segment: segment,
        courseDone: null,
        courseLength: null,
        lapRemaining: length - inLap,
        segmentRemaining: progress.remaining,
      );
    }
    final total = length * laps;
    final done = ((progress.lap - 1) * length + inLap)
        .clamp(0, total)
        .toDouble();
    return ProgressFrameModel(
      course: FrameTrack(
        share: _share(done, total),
        boundaries: [for (var i = 1; i < laps; i++) i / laps],
      ),
      lap: lap,
      segment: segment,
      courseDone: done,
      courseLength: total,
      lapRemaining: length - inLap,
      segmentRemaining: progress.remaining,
    );
  }

  /// The outer track; null with an open number of laps and no time limit.
  final FrameTrack? course;
  final FrameTrack lap;
  final FrameTrack segment;

  /// Rowed and planned over all laps; null with an open number of laps or a time limit.
  final double? courseDone;
  final int? courseLength;

  final double lapRemaining;
  final double segmentRemaining;

  /// The rowing time left up to the time limit; null without one.
  final Duration? timeRemaining;

  static double _share(double part, int whole) =>
      whole > 0 ? (part / whole).clamp(0, 1).toDouble() : 0;
}
