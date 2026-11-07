import 'dart:convert';

import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/lap_tracker.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sessions/first_stroke.dart';
import 'package:strokesplit/data/sessions/session_accumulator.dart';
import 'package:strokesplit/data/sessions/session_repository.dart';
import 'package:strokesplit/data/sources/erg_source.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

const _pace = Duration(minutes: 2, seconds: 5);

/// One FTMS record per second: rows for [rowS] seconds at 4 m/s and 24
/// strokes per minute, sits still for [sitS] seconds, then rows for [againS]
/// seconds.
List<RawPacket> _rowSitRow({int rowS = 60, int sitS = 30, int againS = 60}) {
  const encoder = FtmsEncoder();
  final packets = <RawPacket>[];
  var distance = 0;
  var rowedS = 0;
  for (var s = 0; s <= rowS + sitS + againS; s++) {
    final rowing = s <= rowS || s > rowS + sitS;
    if (rowing && s > 0) {
      rowedS++;
      distance += 4;
    }
    packets.add(
      encoder.encode(
        RowerData(
          strokeRate: rowing ? 24 : 0,
          strokeCount: rowedS * 2 ~/ 5,
          totalDistance: distance,
          pace: _pace,
          power: 179,
          totalEnergy: 0,
          energyPerHour: RowerData.energyNotAvailable,
          energyPerMinute: 0xFF,
          elapsedTime: Duration(seconds: s),
        ),
        at: Duration(seconds: s),
      ),
    );
  }
  return packets;
}

SessionAccumulator _accumulate(
  List<RawPacket> packets, {
  CourseDefinition? course,
}) {
  final accumulator = SessionAccumulator(
    1,
    protocol: ErgProtocol.ftms,
    course: course,
  );
  packets.forEach(accumulator.add);
  accumulator.finish();
  return accumulator;
}

void main() {
  test('the session time stands still in a pause and the pause is in the batch', () {
    final accumulator = SessionAccumulator(1, protocol: ErgProtocol.ftms);
    final packets = _rowSitRow();
    var paused = false;
    var pausedAt = Duration.zero;
    for (final p in packets) {
      accumulator.add(p);
      if (accumulator.paused && !paused) {
        pausedAt = accumulator.progress.elapsed;
      }
      paused = paused || accumulator.paused;
      if (accumulator.paused) {
        expect(accumulator.progress.elapsed, pausedAt, reason: 'stands still');
      }
    }
    expect(paused, isTrue);
    expect(accumulator.paused, isFalse, reason: 'rows again');
    // At 24 strokes per minute the next stroke is overdue 3 s after it was due.
    expect(
      pausedAt.inMilliseconds,
      inInclusiveRange(60000, 60000 + 3000 + 6000),
    );
    accumulator.finish();

    final batch = accumulator.takeBatch();
    final pause = batch.pauses.single;
    expect(
      pause.endWallMs.value - pause.startWallMs.value,
      inInclusiveRange(20000, 30000),
    );
    final last = batch.samples.last;
    expect(
      last.wallMs.value! - last.activeMs.value!,
      pause.endWallMs.value - pause.startWallMs.value,
    );
    expect(accumulator.progress.elapsed.inMilliseconds, last.activeMs.value);
  });

  test('a time course and its lap time run on the session time', () {
    final accumulator = _accumulate(
      _rowSitRow(againS: 90),
      course: CourseDefinition.single(axis: CourseAxis.time, length: 90),
    );
    final batch = accumulator.takeBatch();
    final lap = batch.laps.first;
    expect((lap.lapNo.value, lap.complete.value), (1, true));
    expect(
      lap.endWallMs.value - lap.startWallMs.value,
      90000,
      reason: '90 s of session time',
    );

    final pause = batch.pauses.single;
    final pausedMs = pause.endWallMs.value - pause.startWallMs.value;
    // The lap ends 90 s of session time after its start: later on the wall clock by the pause.
    final end = batch.samples.firstWhere((s) => s.activeMs.value! >= 90000);
    expect(end.wallMs.value! - end.activeMs.value!, pausedMs);
  });

  test('a distance lap leaves out the pause', () {
    final accumulator = _accumulate(
      _rowSitRow(rowS: 60, sitS: 30, againS: 60),
      course: CourseDefinition.single(axis: CourseAxis.distance, length: 400),
    );
    final lap = accumulator.takeBatch().laps.first;
    expect(lap.complete.value, isTrue);
    // 400 m at 4 m/s is 100 s of rowing, plus the time until the pause began.
    expect(
      lap.endWallMs.value - lap.startWallMs.value,
      inInclusiveRange(100000, 100000 + 9000),
    );
  });

  test('the pause counts neither in nor out of the zone', () {
    final course = CourseDefinition(
      axis: CourseAxis.distance,
      length: 400,
      segments: [
        CourseSegment(length: 400, paceFastCs: 12000, paceSlowCs: 13000),
      ],
    );
    final share = _accumulate(
      _rowSitRow(),
      course: course,
    ).takeBatch().laps.first.inZoneShare.value!;
    // Only the seconds until the pause began, when the rower already sat still, count as out.
    expect(share, greaterThan(0.9));
    expect(share, lessThan(1));
  });

  test('the live state shows the lap standing still in a pause', () {
    final accumulator = SessionAccumulator(
      1,
      protocol: ErgProtocol.ftms,
      course: CourseDefinition.single(axis: CourseAxis.time, length: 600),
    );
    LapProgress? atPause;
    for (final p in _rowSitRow()) {
      accumulator.add(p);
      if (!accumulator.paused) continue;
      atPause ??= accumulator.lapProgress;
      expect(accumulator.lapProgress!.remaining, atPause!.remaining);
      expect(accumulator.lapProgress!.courseTime, atPause.courseTime);
    }
    expect(atPause, isNotNull);
  });

  group('stored', () {
    late AppDatabase db;
    late SessionRepository repository;

    setUp(() {
      db = openTestDatabase();
      repository = SessionRepository(db);
    });

    tearDown(() => db.close());

    Future<int> record(List<RawPacket> packets) async {
      final id = await repository.create(
        startedAt: DateTime(2026, 10, 18),
        source: ErgSourceKind.ftms,
      );
      final accumulator = SessionAccumulator(id, protocol: ErgProtocol.ftms);
      packets.forEach(accumulator.add);
      accumulator.finish();
      await repository.write(accumulator.takeBatch());
      await repository.finish(id);
      return id;
    }

    test(
      'the summary has the duration without the pauses and the pauses',
      () async {
        final id = await record(_rowSitRow());
        final session = (await repository.get(id))!;
        final pauses = await repository.pauses(id);
        expect(pauses, hasLength(1));
        expect(
          (session.pauseCount, session.pausedMs),
          (1, pauses.single.endWallMs - pauses.single.startWallMs),
        );
        expect(
          session.durationMs + session.pausedMs,
          150000,
          reason: 'the wall clock of the session',
        );
        expect(
          session.averagePaceCs,
          (session.durationMs / 10 * 5000 / session.distanceDm).round(),
        );
      },
    );

    test('a pause running at the end is dropped', () async {
      final id = await record(_rowSitRow(rowS: 60, sitS: 60, againS: 0));
      final session = (await repository.get(id))!;
      expect(await repository.pauses(id), isEmpty);
      expect((session.pauseCount, session.pausedMs), (0, 0));
      expect(
        session.durationMs,
        inInclusiveRange(60000, 60000 + 9000),
        reason: 'ends where the pause began',
      );
    });

    test('deleting a session deletes its pauses', () async {
      final id = await record(_rowSitRow());
      await repository.delete(id);
      expect(await db.select(db.pauses).get(), isEmpty);
    });

    test('a recording without a stop imports as before auto-pause, without a pause', () async {
      // From the first movement on, as a session on a workout stores it.
      final recording = loadFixture('force_curve');
      final detector = FirstStrokeDetector(ErgProtocol.pm5);
      final packets = <RawPacket>[];
      for (final p in recording.packets) {
        if (packets.isNotEmpty) {
          packets.add(p);
        } else {
          packets.addAll(detector.add(p) ?? const []);
        }
      }
      final file = RawRecording(
        metadata: recording.metadata,
        packets: packets,
      ).toLines().join('\n');

      final id = await repository.import(utf8.encode(file));
      final session = (await repository.get(id))!;
      expect((session.pauseCount, session.pausedMs), (0, 0));
      // Without a pause the session time is the wall clock the laps ran on before.
      final samples = await (db.select(
        db.samples,
      )..where((s) => s.sessionId.equals(id))).get();
      // A slow stroke reported late may hold the session time back for a moment (Design D1),
      // but without a pause it ends on the wall clock.
      expect(samples.every((s) => s.activeMs! <= s.wallMs!), isTrue);
      expect(samples.last.activeMs, samples.last.wallMs);
      expect(session.distanceDm, samples.last.distanceDm);
      // The duration was the monitor's time; both start at the first stroke.
      expect((session.durationMs - samples.last.tMs).abs(), lessThan(1000));
    });
  });
}
