import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/lap_tracker.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sessions/session_accumulator.dart';
import 'package:strokesplit/data/sessions/session_repository.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

/// Records [fixture] into a new session, on [course] when given.
Future<(AppDatabase, int)> _record(
  String fixture, {
  CourseDefinition? course,
  int? plannedLaps,
}) async {
  final db = openTestDatabase();
  final repository = SessionRepository(db);
  final id = await repository.create(
    startedAt: DateTime(2026, 10, 16),
    source: ErgSourceKind.pm5,
  );
  final accumulator = SessionAccumulator(
    id,
    course: course,
    plannedLaps: plannedLaps,
  );
  for (final p in loadFixture(fixture).packets) {
    accumulator.add(p);
    // Written in several batches, like while recording.
    if (accumulator.lastTick != null && p.time.inMilliseconds % 2000 < 50) {
      await repository.write(accumulator.takeBatch());
    }
  }
  accumulator.finish();
  await repository.write(accumulator.takeBatch());
  return (db, id);
}

void main() {
  test(
    'stores the wall-clock time, which keeps running while the PM5 pauses',
    () async {
      final course = CourseDefinition.single(
        axis: CourseAxis.time,
        length: 3600,
      );
      final (db, _) = await _record('pause', course: course);
      final samples = await db.select(db.samples).get();

      // The longest stretch in which the PM5 clock stands still.
      var longestPause = 0;
      var start = samples.first;
      for (final s in samples) {
        if (s.tMs != start.tMs) start = s;
        longestPause = s.wallMs! - start.wallMs! > longestPause
            ? s.wallMs! - start.wallMs!
            : longestPause;
      }
      expect(longestPause, greaterThan(5000));
      expect(
        samples.last.wallMs! - samples.last.tMs,
        greaterThanOrEqualTo(longestPause),
      );
    },
  );

  test('a free session keeps leaving out the samples of a pause', () async {
    final (db, _) = await _record('pause');
    final samples = await db.select(db.samples).get();

    final values = {for (final s in samples) (s.tMs, s.distanceDm, s.activeMs)};
    expect(values, hasLength(samples.length));
    expect(
      samples.every((s) => s.wallMs != null && s.activeMs! <= s.wallMs!),
      isTrue,
    );
    expect(await db.select(db.laps).get(), isEmpty);
  });

  test(
    'stores the same laps as the tracker gives on the stored samples',
    () async {
      final probe = await _record('just_row');
      final rowed =
          (await probe.$1.select(probe.$1.samples).get()).last.distanceDm ~/ 10;
      expect(rowed, greaterThan(60));
      // Three laps and a bit, with a band in the middle segment.
      final lap = rowed ~/ 3 - 1;
      final course = CourseDefinition(
        axis: CourseAxis.distance,
        length: lap,
        segments: [
          CourseSegment(length: lap ~/ 2),
          CourseSegment(
            length: lap - lap ~/ 2,
            paceFastCs: 10000,
            paceSlowCs: 20000,
            spmMin: 15,
            spmMax: 40,
          ),
        ],
      );

      final (db, id) = await _record('just_row', course: course);
      final samples = await (db.select(
        db.samples,
      )..orderBy([(s) => OrderingTerm.asc(s.rowId)])).get();
      final tracker = LapTracker(course);
      for (final s in samples) {
        tracker.add(
          TrackPoint(
            wallMs: s.activeMs!,
            distanceDm: s.distanceDm,
            paceCs: s.paceCs,
            strokeRate: s.strokeRate,
          ),
        );
      }
      tracker.finish();

      final laps = await (db.select(
        db.laps,
      )..where((l) => l.sessionId.equals(id))).get();
      final expected = tracker.takeLaps();
      expect(
        [
          for (final l in laps)
            (
              l.lapNo,
              l.startWallMs,
              l.endWallMs,
              l.endDistanceDm,
              l.complete,
              l.inZoneShare,
            ),
        ],
        [
          for (final l in expected)
            (
              l.lap,
              l.startWallMs,
              l.endWallMs,
              l.endDistanceDm,
              l.complete,
              l.inZoneShare,
            ),
        ],
      );
      expect(laps.where((l) => l.complete), hasLength(3));
      expect(laps.last.complete, isFalse);
      expect(
        await db.select(db.lapSegments).get(),
        hasLength(tracker.takeSegments().length),
      );
    },
  );
}
