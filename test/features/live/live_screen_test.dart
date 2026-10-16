import 'dart:async';

import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/courses/lap_tracker.dart';
import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/data/templates/session_template.dart';
import 'package:aergrow/data/templates/template_repository.dart';
import 'package:aergrow/data/zones/zone.dart';
import 'package:aergrow/data/zones/zone_repository.dart';
import 'package:aergrow/features/live/live_layout.dart';
import 'package:aergrow/features/live/live_screen.dart';
import 'package:aergrow/features/live/pace_box.dart';
import 'package:aergrow/features/live/progress_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/fake_erg_source.dart';
import '../../support/ghost_sessions.dart';
import '../../support/localized_app.dart';
import '../../support/rowed_sessions.dart';
import '../../support/test_database.dart';

class _Fixed extends ActiveErgSource {
  _Fixed(this.source);

  final ErgSource source;

  @override
  ErgSource? build() => source;
}

const _elapsed = Duration(minutes: 12, seconds: 34);

StatusTick _tick({int? heartRate, Duration elapsed = _elapsed}) => StatusTick(
      elapsed: elapsed,
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
      lapTime: const Duration(minutes: 2, seconds: 31),
    ),
  );
}

/// The pace, found by [key], is taller on screen than every other text in [view] but the buttons.
void _expectLargestPace(WidgetTester tester, Finder view, Key key) {
  final pace = tester.getRect(find.byKey(key)).height;
  final buttons = tester.widgetList<Text>(find.descendant(of: find.byType(FilledButton), matching: find.byType(Text)));
  for (final text in tester.widgetList<Text>(find.descendant(of: view, matching: find.byType(Text)))) {
    if (text.key == key || buttons.contains(text)) continue;
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
    ErgConnectionState state = ErgConnectionState.connected,
    AppDatabase? db,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        activeErgSourceProvider.overrideWith(() => _Fixed(FakeErgSource())),
        ergConnectionStateProvider.overrideWithValue(AsyncData(state)),
        rowingEventsProvider.overrideWithValue(events.stream),
        wakelockProvider.overrideWithValue(wakelock),
        if (recording != null) sessionRecorderProvider.overrideWith(() => _Recording(recording)),
        if (db != null) databaseProvider.overrideWithValue(db),
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
    expect(find.text('Ø Pace 2:04.8'), findsOneWidget);
  });

  testWidgets('hides the heart rate without a monitor', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    await harness.emit(tester, _tick());

    expect(find.byKey(const Key('metric-hr')), findsNothing);
    expect(find.textContaining('Puls'), findsNothing);
  });

  group('RR interval', () {
    HeartBeatIntervals beats(List<int> intervalsMs) =>
        HeartBeatIntervals(elapsed: _elapsed, time: const Duration(seconds: 754), intervalsMs: intervalsMs);

    for (final template in [false, true]) {
      testWidgets('shows the last one at the heart rate${template ? ' on a template' : ''}', (tester) async {
        final harness = _Harness();
        await harness.pump(tester, recording: template ? _onCourse() : null);
        await harness.emit(tester, _tick(heartRate: 151));
        await harness.emit(tester, beats([790, 812]));

        expect(find.byKey(const Key('metric-hr')), findsOneWidget);
        expect(find.text('812 ms'), findsOneWidget);
        expect(find.text('790 ms'), findsNothing);
      });
    }

    testWidgets('shows none with the heart rate only from the rower, and no source of it', (tester) async {
      final harness = _Harness();
      await harness.pump(tester);
      await harness.emit(tester, _tick(heartRate: 151));

      expect(find.text('Puls 151'), findsOneWidget);
      expect(find.byKey(const Key('metric-rr')), findsNothing);
      expect(find.textContaining('ms'), findsNothing);
      expect(find.textContaining('Gurt'), findsNothing);
    });

    testWidgets('hides an RR interval more than 3 seconds older than the latest tick', (tester) async {
      final harness = _Harness();
      await harness.pump(tester);
      await harness.emit(tester, _tick(heartRate: 151));
      await harness.emit(tester, beats([812]));

      await harness.emit(tester, _tick(heartRate: 151, elapsed: _elapsed + const Duration(seconds: 3)));
      expect(find.text('812 ms'), findsOneWidget);

      await harness.emit(tester, _tick(heartRate: 151, elapsed: _elapsed + const Duration(milliseconds: 3100)));
      expect(find.text('812 ms'), findsNothing);
      expect(find.text('Puls 151'), findsOneWidget);
    });
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
    for (final (template, state) in const [
      (false, ErgConnectionState.connected),
      (true, ErgConnectionState.connected),
      (true, ErgConnectionState.reconnecting),
    ]) {
      final what = '${template ? ' with a template' : ''}'
          '${state == ErgConnectionState.connected ? '' : ' while ${state.name}'}';
      testWidgets('fits all values without overflow on a $name$what', (tester) async {
        final harness = _Harness();
        await harness.pump(
          tester,
          size: size,
          recording: template ? _onCourse(pace: BandStatus.above) : null,
          state: state,
        );
        await harness.emit(tester, _tick(heartRate: 151));
        await harness.emit(tester, HeartBeatIntervals(elapsed: _elapsed, time: Duration.zero, intervalsMs: [812]));

        // Overflows would be reported as exceptions and fail the test.
        final view = find.byKey(ValueKey(LiveLayout.of(size)));
        _expectLargestPace(tester, view, Key(template ? 'pace-box-pace' : 'metric-pace'));
        if (template) {
          // Room for a ghost moved out of the outer track (Change ghost, Design D5).
          final box = tester.getRect(find.byType(PaceBox));
          expect(box.top - tester.getRect(view).top, greaterThanOrEqualTo(ProgressFramePainter.overhang));
          for (final key in const [
            'pace-box-course',
            'pace-box-lap',
            'pace-box-segment',
            'pace-box-status',
            'stroke-card-status',
            'metric-spm',
            'metric-lap-time',
            'metric-watts',
            'metric-hr',
            'metric-rr',
            'metric-zone-share',
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
    /// The legend line with [key] in the pace box shows [label] and [value].
    void expectLine(String key, String label, String value) {
      final line = find.byKey(Key(key));
      expect(find.descendant(of: line, matching: find.text(label)), findsOneWidget, reason: key);
      expect(find.descendant(of: line, matching: find.text(value)), findsOneWidget, reason: key);
    }

    testWidgets('shows lap, zone and rest in the pace box, the bands and the share in the zone', (tester) async {
      final harness = _Harness();
      await harness.pump(tester, recording: _onCourse());
      await harness.emit(tester, _tick());

      expectLine('pace-box-course', 'Gesamt', '1\u00A0520 / 3\u00A0000 m');
      expectLine('pace-box-lap', 'Runde 2 / 3', 'noch 480 m');
      expectLine('pace-box-segment', 'Tempo', 'noch 280 m');
      expect(find.text('In der Zone · 2:05–2:10'), findsOneWidget);
      expect(find.text('In der Zone · 20–22 spm'), findsOneWidget);
      expect(find.text('24 spm'), findsOneWidget);
      expect(find.text('2:31'), findsOneWidget);
      expect(find.text('75 %'), findsOneWidget);
      // The range of the segment is left to the progress frame.
      expect(find.text('200–800 m'), findsNothing);
    });

    testWidgets('shows the course and the values in English', (tester) async {
      final harness = _Harness();
      await harness.pump(
        tester,
        recording: _onCourse(pace: BandStatus.above, strokeRate: BandStatus.below),
        locale: const Locale('en'),
      );
      await harness.emit(tester, _tick(heartRate: 151));

      expectLine('pace-box-lap', 'Lap 2 / 3', '480 m to go');
      expectLine('pace-box-segment', 'Tempo', '280 m to go');
      expect(find.text('Faster · 2:05–2:10'), findsOneWidget);
      expect(find.text('More strokes · 20–22 spm'), findsOneWidget);
      for (final label in ['Lap', 'Watts', 'Heart rate', 'In zone', 'PACE /500 M', 'STROKE RATE', 'End session']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      // The pace keeps the PM5 format in every language.
      expect(find.text('2:05.3'), findsOneWidget);
    });

    testWidgets('marks pace and stroke rate in the zone', (tester) async {
      final harness = _Harness();
      await harness.pump(tester, recording: _onCourse());
      await harness.emit(tester, _tick());

      expect(find.byKey(const Key('pace-box-zone-in')), findsOneWidget);
      expect(find.byKey(const Key('stroke-card-zone-in')), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    });

    testWidgets('shows in which direction a value is off, not by colour alone', (tester) async {
      final harness = _Harness();
      await harness.pump(tester, recording: _onCourse(pace: BandStatus.above, strokeRate: BandStatus.below));
      await harness.emit(tester, _tick());

      expect(find.byKey(const Key('pace-box-zone-out')), findsOneWidget);
      expect(find.byKey(const Key('stroke-card-zone-out')), findsOneWidget);
      expect(find.text('Schneller · 2:05–2:10'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsNWidgets(2));
      expect(find.text('Mehr Schläge · 20–22 spm'), findsOneWidget);
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

      expectLine('pace-box-segment', 'frei', 'noch 280 m');
      expect(find.byKey(const Key('pace-box-status')), findsNothing);
      expect(find.byKey(const Key('stroke-card-status')), findsNothing);
      expect(find.byKey(const Key('pace-box-zone-in')), findsNothing);
      expect(find.byKey(const Key('stroke-card-zone-in')), findsNothing);
      expect(find.byKey(const Key('stroke-card-zone-out')), findsNothing);
      expect(find.text('–'), findsOneWidget);
    });

    testWidgets('ends the session with a short button in landscape', (tester) async {
      final harness = _Harness();
      await harness.pump(tester, size: const Size(844, 390), recording: _onCourse());
      await harness.emit(tester, _tick());

      expect(find.text('Beenden'), findsOneWidget);
    });
  });

  group('app bar', () {
    testWidgets('names the template being rowed', (tester) async {
      final harness = _Harness();
      await harness.pump(tester, recording: _onCourse());

      expect(find.descendant(of: find.byType(AppBar), matching: find.text('Seerunde x3')), findsOneWidget);
    });

    testWidgets('names free rowing without a template', (tester) async {
      final harness = _Harness();
      await harness.pump(tester);

      expect(find.descendant(of: find.byType(AppBar), matching: find.text('Frei rudern')), findsOneWidget);
    });

    testWidgets('shows the connection as a dot and not as text', (tester) async {
      final harness = _Harness();
      await harness.pump(tester);

      expect(find.descendant(of: find.byType(AppBar), matching: find.byKey(const Key('connection-dot'))), findsOne);
      expect(find.text('Verbunden'), findsNothing);
    });

    testWidgets('shows a lost connection as text', (tester) async {
      final harness = _Harness();
      await harness.pump(tester, state: ErgConnectionState.reconnecting);

      expect(find.text('Verbindung unterbrochen, verbinde neu …'), findsOneWidget);
    });

    testWidgets('keeps disconnecting within reach', (tester) async {
      final harness = _Harness();
      await harness.pump(tester);

      expect(find.byTooltip('Trennen'), findsOneWidget);
    });
  });

  testWidgets('shows no pace box on a free session', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    await harness.emit(tester, _tick());

    expect(find.byType(PaceBox), findsNothing);
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

  group('with ghosts', () {
    late AppDatabase db;

    setUp(() => db = openTestDatabase());

    /// Stores [definition] as "Seerunde" and a template with [laps] on it.
    Future<SessionTemplate> templateOn(WidgetTester tester, CourseDefinition definition, {required int? laps}) async {
      return (await tester.runAsync(() async {
        final course = await CourseRepository(db).create('Seerunde', definition);
        final templates = TemplateRepository(db);
        return (await templates.get(await templates.create('Seerunde x$laps', courseId: course, laps: laps)))!;
      }))!;
    }

    /// Rowing [template] at [inLap] metres of lap [lap], with the given wall-clock
    /// times in seconds and [courseMetres] since the start.
    ActiveRecording rowing(
      SessionTemplate template, {
      int lap = 1,
      required int inLap,
      required int lapSeconds,
      required int courseSeconds,
      required int segmentSeconds,
      required int courseMetres,
    }) {
      final definition = template.course.definition;
      final index = definition.segmentEnds.indexWhere((end) => end > inLap);
      return ActiveRecording(
        sessionId: 99,
        progress: SessionProgress(distanceMeters: courseMetres.toDouble(), elapsed: Duration(seconds: courseSeconds)),
        template: template,
        lap: LapProgress(
          lap: lap,
          plannedLaps: template.laps,
          segmentIndex: index,
          segment: definition.segments[index],
          segmentStart: definition.segmentStarts[index],
          segmentEnd: definition.segmentEnds[index],
          remaining: (definition.segmentEnds[index] - inLap).toDouble(),
          pace: BandStatus.none,
          strokeRate: BandStatus.none,
          lapInZoneShare: null,
          lapTime: Duration(seconds: lapSeconds),
          courseTime: Duration(seconds: courseSeconds),
          segmentTime: Duration(seconds: segmentSeconds),
          courseDistanceDm: courseMetres * 10.0,
        ),
      );
    }

    /// Shows [recording] and lets the ghosts load from the database.
    Future<void> show(WidgetTester tester, ActiveRecording recording, {Size size = const Size(390, 844)}) async {
      final harness = _Harness();
      await harness.pump(tester, size: size, recording: recording, db: db);
      await harness.emit(tester, _tick());
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        await tester.pump();
      }
    }

    PaceBox paceBox(WidgetTester tester) => tester.widget<PaceBox>(find.byType(PaceBox));

    for (final MapEntry(key: name, value: size) in const {
      'portrait': Size(390, 844),
      'landscape': Size(844, 390),
    }.entries) {
      testWidgets('Runde 2: the lap ghost in the frame and the gap in the box, $name', (tester) async {
        final template =
            await templateOn(tester, CourseDefinition.single(axis: CourseAxis.distance, length: 1000), laps: 3);
        // The best so far: three laps of 3:50 each.
        await tester.runAsync(() => storeRowedSessionWithSamples(db, template: template, laps: [
              for (var i = 0; i < 3; i++) RowedLap.single(230000, 1000),
            ]));

        // 1 460 m after 6:05, 115 s into lap 2.
        await show(
          tester,
          rowing(template,
              lap: 2, inLap: 460, lapSeconds: 115, courseSeconds: 365, segmentSeconds: 115, courseMetres: 1460),
          size: size,
        );

        final box = paceBox(tester);
        // Halfway through its lap and at 365 s of its 690 s session.
        expect(box.ghost!.lap, closeTo(0.5, 0.005));
        expect(box.ghost!.course, closeTo(365 / 690, 0.005));
        // The ghost passed 1 460 m after 335.8 s.
        expect(box.ghostGap!.ghostAhead, isTrue);
        expect(box.ghostGap!.amount, closeTo(29.2, 0.1));
        final line = find.byKey(const Key('pace-box-ghost-behind'));
        expect(find.descendant(of: line, matching: find.text('29.2 s vor dir')), findsOneWidget);
        await disposeWidgetsWithDatabase(tester);
      });
    }

    testWidgets('Offene Rundenzahl: no gap in the box, the lap ghost in the frame', (tester) async {
      final template =
          await templateOn(tester, CourseDefinition.single(axis: CourseAxis.distance, length: 1000), laps: null);
      await tester.runAsync(() => storeRowedSessionWithSamples(db, template: template, laps: [
            RowedLap.single(250000, 1000),
            RowedLap.single(248000, 1000),
          ]));

      await show(
        tester,
        rowing(template,
            lap: 3, inLap: 500, lapSeconds: 124, courseSeconds: 624, segmentSeconds: 124, courseMetres: 2500),
      );

      final box = paceBox(tester);
      expect(box.ghost!.course, isNull);
      expect(box.ghost!.lap, closeTo(0.5, 0.005));
      expect(box.ghostGap, isNull);
      expect(find.textContaining('Ghost'), findsNothing);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('Freier Abschnitt: no ghost on the segment track', (tester) async {
      const sprint = Zone(name: 'Sprint', axis: CourseAxis.distance, length: 100, paceFastCs: 9000, paceSlowCs: 10000);
      final sprintId = (await tester.runAsync(() => ZoneRepository(db).create(sprint)))!;
      final definition = CourseDefinition(axis: CourseAxis.distance, length: 1000, segments: [
        sprint.copyWith(id: sprintId).segment,
        const CourseSegment(length: 900),
      ]);
      final template = await templateOn(tester, definition, laps: 1);
      await tester.runAsync(() => storeRowedSessionWithSamples(db, template: template, laps: [
            const RowedLap([(20000, 100), (210000, 900)]),
          ]));

      await show(
        tester,
        rowing(template, inLap: 300, lapSeconds: 60, courseSeconds: 60, segmentSeconds: 40, courseMetres: 300),
      );

      final box = paceBox(tester);
      expect(box.ghost!.segment, isNull);
      expect(box.ghost!.lap, isNotNull);
      expect(box.ghost!.course, isNotNull);
      expect(box.ghostGap, isNotNull);
      await disposeWidgetsWithDatabase(tester);
    });

    testWidgets('rowing free shows no ghost', (tester) async {
      final template =
          await templateOn(tester, CourseDefinition.single(axis: CourseAxis.distance, length: 1000), laps: 1);
      await tester.runAsync(
          () => storeRowedSessionWithSamples(db, template: template, laps: [RowedLap.single(230000, 1000)]));

      await show(
        tester,
        const ActiveRecording(
          sessionId: 99,
          progress: SessionProgress(distanceMeters: 460, elapsed: Duration(seconds: 115)),
        ),
      );

      expect(find.byType(PaceBox), findsNothing);
      expect(find.byType(ProgressFrame), findsNothing);
      expect(find.textContaining('Ghost'), findsNothing);
      await disposeWidgetsWithDatabase(tester);
    });
  });
}
