import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strokesplit/app/design_tokens.dart';
import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/lap_tracker.dart';
import 'package:strokesplit/features/live/pace_box.dart';
import 'package:strokesplit/features/live/stroke_rate_card.dart';
import 'package:strokesplit/features/live/upcoming_zone.dart';

import '../../support/localized_app.dart';

const _warmUp = CourseSegment(length: 300, paceFastCs: 13500, paceSlowCs: 14000, spmMin: 18, spmMax: 20, zoneId: 1);
const _sprint = CourseSegment(length: 200, paceFastCs: 11500, paceSlowCs: 12000, spmMin: 26, spmMax: 30, zoneId: 2);
const _spmOnly = CourseSegment(length: 200, spmMin: 24, spmMax: 26, zoneId: 3);
const _free = CourseSegment(length: 100);
const _pace = Duration(minutes: 2);

/// In segment [index] of [course] with [remaining] left of it, in lap [lap] of [laps].
LapProgress _at(CourseDefinition course, int index, double remaining, {int lap = 1, int? laps = 2}) => LapProgress(
      lap: lap,
      plannedLaps: laps,
      segmentIndex: index,
      segment: course.segments[index],
      segmentStart: course.segmentStarts[index],
      segmentEnd: course.segmentEnds[index],
      remaining: remaining,
      pace: BandStatus.inBand,
      strokeRate: BandStatus.inBand,
      lapInZoneShare: null,
    );

CourseDefinition _course(List<CourseSegment> segments, {CourseAxis axis = CourseAxis.distance}) => CourseDefinition(
      axis: axis,
      length: segments.fold(0, (sum, s) => sum + s.length),
      segments: segments,
    );

void main() {
  group('upcomingZone', () {
    final course = _course([_warmUp, _sprint, _free]);

    test('announces the next zone from 10 seconds before it on a distance course', () {
      // 41 m at 2:00 are 9.84 s, 42 m are 10.08 s.
      expect(upcomingZone(_at(course, 0, 41), course, _pace), _sprint);
      expect(upcomingZone(_at(course, 0, 42), course, _pace), isNull);
    });

    test('needs a pace on a distance course', () {
      expect(upcomingZone(_at(course, 0, 10), course, null), isNull);
      expect(upcomingZone(_at(course, 0, 10), course, Duration.zero), isNull);
    });

    test('counts seconds on a time course, whatever the pace', () {
      final timed = _course([_warmUp, _sprint], axis: CourseAxis.time);
      expect(upcomingZone(_at(timed, 0, 10), timed, null), _sprint);
      expect(upcomingZone(_at(timed, 0, 10.5), timed, null), isNull);
      expect(upcomingZone(_at(timed, 0, 0), timed, null), isNull);
    });

    test('announces no free gap', () {
      expect(upcomingZone(_at(course, 1, 5), course, _pace), isNull);
    });

    test('announces no zone with the same bands', () {
      final same = _course([_sprint, _sprint.withLength(100)]);
      expect(upcomingZone(_at(same, 0, 5), same, _pace), isNull);
    });

    test('announces the first zone of the next lap, but none after the last lap', () {
      final laps = _course([_warmUp, _sprint]);
      expect(upcomingZone(_at(laps, 1, 5), laps, _pace), _warmUp);
      expect(upcomingZone(_at(laps, 1, 5, laps: null, lap: 4), laps, _pace), _warmUp);
      expect(upcomingZone(_at(laps, 1, 5, lap: 2), laps, _pace), isNull);
    });
  });

  group('UpcomingPill', () {
    Future<void> pump(WidgetTester tester, {bool disableAnimations = false}) => tester.pumpWidget(LocalizedApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: const Scaffold(body: Center(child: UpcomingPill(text: 'Gleich 1:55–2:00'))),
          ),
        ));

    double opacity(WidgetTester tester) =>
        tester.widget<Opacity>(find.descendant(of: find.byType(UpcomingPill), matching: find.byType(Opacity))).opacity;

    testWidgets('blinks in yellow', (tester) async {
      await pump(tester);
      final fill = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(UpcomingPill), matching: find.byType(DecoratedBox)),
      );
      expect((fill.decoration as BoxDecoration).color, AppColors.upcoming);
      expect(opacity(tester), 1);
      await tester.pump(const Duration(milliseconds: 700));
      expect(opacity(tester), lessThan(1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(opacity(tester), 1);
    });

    testWidgets('stays lit when the platform asks for less motion', (tester) async {
      await pump(tester, disableAnimations: true);
      await tester.pump(const Duration(milliseconds: 700));
      expect(opacity(tester), 1);
    });
  });

  group('in place of the zone status', () {
    final course = _course([_warmUp, _spmOnly]);

    testWidgets('the pace box keeps its status when the next zone has no pace band', (tester) async {
      await tester.pumpWidget(LocalizedApp(
        home: Scaffold(
          body: SizedBox(
            width: 350,
            height: 380,
            child: PaceBox(progress: _at(course, 0, 10), course: course, pace: _pace, upcoming: _spmOnly),
          ),
        ),
      ));
      expect(find.byKey(const Key('pace-box-upcoming')), findsNothing);
      expect(find.byKey(const Key('pace-box-status')), findsOneWidget);
    });

    for (final landscape in [false, true]) {
      testWidgets('the stroke rate card shows the next band${landscape ? ' in landscape' : ''}', (tester) async {
        await tester.pumpWidget(LocalizedApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: landscape ? 220 : 320,
                height: landscape ? 200 : 80,
                child: StrokeRateCard(
                  strokeRate: 19,
                  status: BandStatus.inBand,
                  segment: _warmUp,
                  fontSize: 48,
                  landscape: landscape,
                  upcoming: _spmOnly,
                ),
              ),
            ),
          ),
        ));
        expect(tester.widget<Text>(find.byKey(const Key('stroke-card-upcoming-band'))).data, 'Gleich 24–26 spm');
        expect(find.byKey(const Key('stroke-card-status')), findsNothing);
      });
    }
  });
}
