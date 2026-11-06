import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/statistics/ranking.dart';
import 'package:flutter_test/flutter_test.dart';

/// A lap of session [session] rowed in [ms] over [metres].
RankingEntry _lap(
  int session,
  int ms,
  int metres, {
  DateTime? on,
  int startWallMs = 0,
}) => RankingEntry(
  sessionId: session,
  startedAt: on ?? DateTime(2026, 10, 1, 7),
  lap: 1,
  startWallMs: startWallMs,
  endWallMs: startWallMs + ms,
  startDistanceDm: 0,
  endDistanceDm: metres * 10,
);

void main() {
  test('ranks a distance zone by its time, with date and pace', () {
    final slow = _lap(1, 18900, 100, on: DateTime(2026, 10, 1));
    final fast = _lap(2, 18200, 100, on: DateTime(2026, 10, 5));

    final ranked = rankEntries(CourseAxis.distance, [slow, fast]);

    expect(ranked, [fast, slow]);
    expect(
      [for (final e in ranked) (e.startedAt, e.paceCs)],
      [(DateTime(2026, 10, 5), 9100), (DateTime(2026, 10, 1), 9450)],
    );
  });

  test('ranks a time course by its metres', () {
    final ranked = rankEntries(CourseAxis.time, [
      _lap(1, 240000, 1012),
      _lap(2, 240000, 1030),
    ]);

    expect([for (final e in ranked) e.distanceDm ~/ 10], [1030, 1012]);
  });

  test('leaves a pause out of the time and the pace', () {
    // 4:00 of rowing and 30 s of pause: the lap holds the session time (Change auto-pause).
    final lap = _lap(1, 240000, 1000);

    expect(lap.durationMs, 240000);
    expect(lap.paceCs, 12000);
  });

  test('puts the earlier entry ahead on a tie', () {
    final later = _lap(1, 248000, 1000, on: DateTime(2026, 10, 5));
    final earlier = _lap(2, 248000, 1000, on: DateTime(2026, 10, 1));

    expect(rankEntries(CourseAxis.distance, [later, earlier]), [
      earlier,
      later,
    ]);
  });

  test('puts the earlier lap of a session ahead on a tie', () {
    final second = _lap(1, 248000, 1000, startWallMs: 248000);
    final first = _lap(1, 248000, 1000);

    expect(rankEntries(CourseAxis.distance, [second, first]), [first, second]);
  });

  test('ranks a session by the sum of its laps', () {
    final entry = RankingEntry(
      sessionId: 1,
      startedAt: DateTime(2026, 10, 1),
      startWallMs: 0,
      endWallMs: 744100,
      startDistanceDm: 0,
      endDistanceDm: 30000,
      durationMs: 744100,
      distanceDm: 30000,
    );

    expect((entry.lap, entry.paceCs), (null, 12402));
  });

  test('has no pace without distance', () {
    expect(_lap(1, 1000, 0).paceCs, isNull);
  });

  test('keeps the first places', () {
    final ranking = Ranking(
      axis: CourseAxis.distance,
      length: 1000,
      entries: [for (var i = 0; i < 5; i++) _lap(i, 240000 + i, 1000)],
    );

    expect([for (final e in ranking.top(3).entries) e.sessionId], [0, 1, 2]);
  });
}
