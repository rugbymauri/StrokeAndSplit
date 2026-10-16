import 'dart:async';

import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/lap_tracker.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/data/templates/session_template.dart';
import 'package:aergrow/features/live/live_layout.dart';
import 'package:aergrow/features/live/live_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/fake_erg_source.dart';
import '../../support/localized_app.dart';

class _Fixed extends ActiveErgSource {
  _Fixed(this.source);

  final ErgSource source;

  @override
  ErgSource? build() => source;
}

StatusTick _tick({int? heartRate}) => StatusTick(
      elapsed: const Duration(minutes: 12, seconds: 34),
      distanceMeters: 3021.7,
      workoutType: WorkoutType.justRowSplits,
      workoutState: WorkoutState.workoutRow,
      isRowing: true,
      pace: const Duration(milliseconds: 125300),
      watts: 179,
      strokeRate: 24,
      heartRate: heartRate,
    );

class _Recording extends SessionRecorder {
  _Recording(this.recording);

  final ActiveRecording recording;

  @override
  ActiveRecording? build() => recording;
}

const _band = CourseSegment(
  length: 600,
  paceFastCs: 12500,
  paceSlowCs: 13000,
  spmMin: 20,
  spmMax: 22,
  zoneId: 1,
  zoneName: 'Tempo',
);

/// In lap 2 of "Seerunde x3" at 520 m of the lap, in the zone "Tempo" from 200 to 800 m.
ActiveRecording _onCourse({
  CourseSegment segment = _band,
  BandStatus pace = BandStatus.inBand,
  BandStatus strokeRate = BandStatus.inBand,
}) {
  final course = CourseDefinition(
    axis: CourseAxis.distance,
    length: 1000,
    segments: [const CourseSegment(length: 200), segment.withLength(600), const CourseSegment(length: 200)],
  );
  return ActiveRecording(
    sessionId: 1,
    progress: const SessionProgress(distanceMeters: 1520, elapsed: Duration(minutes: 6, seconds: 20)),
    template: SessionTemplate(
      id: 1,
      name: 'Seerunde x3',
      laps: 3,
      course: Course(id: 1, name: 'Seerunde', versionId: 1, version: 1, definition: course),
    ),
    lap: LapProgress(
      lap: 2,
      plannedLaps: 3,
      segmentIndex: 1,
      segment: course.segments[1],
      segmentStart: 200,
      segmentEnd: 800,
      remaining: 280,
      pace: pace,
      strokeRate: strokeRate,
      lapInZoneShare: segment.isFree ? null : 0.75,
    ),
  );
}

/// The pace, found by [key], is taller on screen than every other text.
void _expectLargestPace(WidgetTester tester, Key key) {
  final pace = tester.getRect(find.byKey(key)).height;
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    if (text.key == key) continue;
    final reason = text.data ?? text.textSpan?.toPlainText();
    expect(tester.getRect(find.byWidget(text)).height, lessThan(pace), reason: reason);
  }
}

class _Harness {
  // Synchronous, so an emitted event is handled before the next frame.
  final events = StreamController<RowingEvent>.broadcast(sync: true);
  final wakelock = FakeWakelock();

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    ActiveRecording? recording,
    Locale locale = const Locale('de'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        activeErgSourceProvider.overrideWith(() => _Fixed(FakeErgSource())),
        ergConnectionStateProvider.overrideWithValue(const AsyncData(ErgConnectionState.connected)),
        rowingEventsProvider.overrideWithValue(events.stream),
        wakelockProvider.overrideWithValue(wakelock),
        if (recording != null) sessionRecorderProvider.overrideWith(() => _Recording(recording)),
      ],
      child: LocalizedApp(locale: locale, home: const LiveScreen()),
    ));
  }

  Future<void> emit(WidgetTester tester, RowingEvent event) async {
    events.add(event);
    await tester.pump();
  }
}

void main() {
  testWidgets('shows the core values in PM5 format', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    await harness.emit(tester, _tick(heartRate: 151));

    expect(find.text('2:05.3'), findsOneWidget);
    expect(find.text('12:34'), findsOneWidget);
    expect(find.text('3\u00A0021 m'), findsOneWidget);
    expect(find.text('179'), findsOneWidget);
    expect(find.text('24 spm'), findsOneWidget);
    expect(find.text('Puls 151'), findsOneWidget);
    // 12:34 over 3021.7 m.
    expect(find.text('⌀ Pace 2:04.8'), findsOneWidget);
  });

  testWidgets('hides the heart rate without a monitor', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    await harness.emit(tester, _tick());

    expect(find.byKey(const Key('metric-hr')), findsNothing);
    expect(find.textContaining('Puls'), findsNothing);
  });

  testWidgets('leaves out the force curve without data', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    await harness.emit(tester, _tick());

    expect(find.byKey(const Key('force-curve')), findsNothing);
  });

  for (final (size, layout) in const [
    (Size(1200, 700), LiveLayout.landscape),
    (Size(390, 844), LiveLayout.portrait),
  ]) {
    testWidgets('chooses the ${layout.name} layout at ${size.width.toInt()} × ${size.height.toInt()}', (tester) async {
      final harness = _Harness();
      await harness.pump(tester, size: size);

      expect(find.byKey(ValueKey(layout)), findsOneWidget);
    });
  }

  final layouts = {
    'phone portrait': const Size(390, 844),
    'phone landscape': const Size(844, 390),
    'desktop window': const Size(1280, 800),
    'small desktop window': const Size(640, 480),
  };
  for (final MapEntry(key: name, value: size) in layouts.entries) {
    for (final template in [false, true]) {
      testWidgets('fits all values without overflow on a $name${template ? ' with a template' : ''}', (tester) async {
        final harness = _Harness();
        await harness.pump(tester, size: size, recording: template ? _onCourse(pace: BandStatus.above) : null);
        await harness.emit(tester, _tick(heartRate: 151));

        // Overflows would be reported as exceptions and fail the test.
        if (!template) _expectLargestPace(tester, const Key('metric-pace'));
        if (template) {
          final pace = tester.getSize(find.byKey(const Key('metric-pace')));
          for (final key in ['metric-elapsed', 'metric-distance', 'metric-watts', 'metric-spm', 'metric-hr']) {
            final other = tester.getSize(find.byKey(Key(key)));
            expect(pace.width * pace.height, greaterThan(other.width * other.height), reason: key);
          }
          for (final key in const [
            'course-lap',
            'course-segment',
            'course-range',
            'course-rest',
            'course-bands',
            'course-zone',
          ]) {
            final rect = tester.getRect(find.byKey(Key(key)));
            expect(rect.bottom, lessThanOrEqualTo(size.height), reason: key);
            expect(rect.right, lessThanOrEqualTo(size.width), reason: key);
          }
        }
      });
    }
  }

  group('on a template', () {
    testWidgets('shows lap, zone, rest, bands and the share in the zone', (tester) async {
      final harness = _Harness();
      await harness.pump(tester, recording: _onCourse());
      await harness.emit(tester, _tick());

      expect(find.text('Runde 2 von 3'), findsOneWidget);
      expect(find.text('Tempo'), findsOneWidget);
      expect(find.text('200–800 m'), findsOneWidget);
      expect(find.text('noch 280 m'), findsOneWidget);
      expect(find.text('2:05–2:10 · 20–22 spm'), findsOneWidget);
      expect(find.text('Zone 75 %'), findsOneWidget);
    });

    testWidgets('shows the course and the values in English', (tester) async {
      final harness = _Harness();
      await harness.pump(
        tester,
        recording: _onCourse(pace: BandStatus.above, strokeRate: BandStatus.below),
        locale: const Locale('en'),
      );
      await harness.emit(tester, _tick(heartRate: 151));

      expect(find.text('Lap 2 of 3'), findsOneWidget);
      expect(find.text('280 m to go'), findsOneWidget);
      expect(find.text('faster'), findsOneWidget);
      expect(find.text('more strokes'), findsOneWidget);
      for (final label in ['Time', 'Distance', 'Watts', 'Stroke rate', 'Heart rate', 'Pace /500 m', 'End session']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      // The pace keeps the PM5 format in every language.
      expect(find.text('2:05.3'), findsOneWidget);
    });

    testWidgets('marks pace and stroke rate in the zone', (tester) async {
      final harness = _Harness();
      await harness.pump(tester, recording: _onCourse());
      await harness.emit(tester, _tick());

      expect(find.byKey(const Key('zone-in')), findsNWidgets(2));
      expect(find.text('in der Zone'), findsNWidgets(2));
    });

    testWidgets('shows in which direction a value is off, not by colour alone', (tester) async {
      final harness = _Harness();
      await harness.pump(tester, recording: _onCourse(pace: BandStatus.above, strokeRate: BandStatus.below));
      await harness.emit(tester, _tick());

      expect(find.byKey(const Key('zone-out')), findsNWidgets(2));
      expect(find.text('schneller'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsNWidgets(2));
      expect(find.text('mehr Schläge'), findsOneWidget);
    });

    testWidgets('shows a free gap without bands', (tester) async {
      final harness = _Harness();
      await harness.pump(
        tester,
        recording: _onCourse(
          segment: const CourseSegment(length: 600),
          pace: BandStatus.none,
          strokeRate: BandStatus.none,
        ),
      );
      await harness.emit(tester, _tick());

      expect(find.text('frei'), findsOneWidget);
      expect(find.text('noch 280 m'), findsOneWidget);
      expect(find.byKey(const Key('course-bands')), findsNothing);
      expect(find.byKey(const Key('zone-in')), findsNothing);
      expect(find.byKey(const Key('zone-out')), findsNothing);
      expect(find.textContaining('Zone'), findsNothing);
    });
  });

  testWidgets('shows no course bar on a free session', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    await harness.emit(tester, _tick());

    expect(find.byKey(const Key('course-lap')), findsNothing);
  });

  testWidgets('marks the values as outdated after 3 seconds without data', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    await harness.emit(tester, _tick());

    await tester.pump(const Duration(milliseconds: 2900));
    expect(find.textContaining('veraltet'), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('veraltet'), findsOneWidget);

    await harness.emit(tester, _tick());
    expect(find.textContaining('veraltet'), findsNothing);
  });

  testWidgets('keeps the screen on while connected and releases it afterwards', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    expect(harness.wakelock.enabled, isTrue);

    await tester.pumpWidget(const SizedBox());
    expect(harness.wakelock.enabled, isFalse);
  });
}
