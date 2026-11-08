import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/app/design_tokens.dart';
import 'package:strokesplit/app/widgets/ghost_symbol.dart';
import 'package:strokesplit/data/courses/lap_tracker.dart';
import 'package:strokesplit/data/courses/zone_intensity.dart';
import 'package:strokesplit/data/ghost/ghost.dart';
import 'package:strokesplit/features/live/pace_box.dart';
import 'package:strokesplit/features/live/progress_frame.dart';
import 'package:strokesplit/features/live/zone_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/localized_app.dart';

const _tempo = CourseSegment(
  length: 600,
  paceFastCs: 12500,
  paceSlowCs: 13000,
  spmMin: 20,
  spmMax: 22,
  resistanceLevel: 8,
  zoneId: 1,
  zoneName: 'Tempo',
);

const _tempoTargets = 'Tempo · 2:05–2:10 · 20–22 spm · Stufe 8';
const _free = CourseSegment(length: 200);

/// 1000 m with the zone "Tempo" from 200 to 800 m.
const _seerunde = CourseDefinition(
  axis: CourseAxis.distance,
  length: 1000,
  segments: [_free, _tempo, _free],
);

/// At [inLap] metres of lap 2 of 3 (or of an open number of laps) in [segment] number [index].
LapProgress _at(
  int inLap, {
  CourseSegment segment = _tempo,
  int index = 1,
  BandStatus pace = BandStatus.inBand,
  int? laps = 3,
  int lap = 2,
}) {
  final start = _seerunde.segmentStarts[index];
  final end = _seerunde.segmentEnds[index];
  return LapProgress(
    lap: lap,
    plannedLaps: laps,
    segmentIndex: index,
    segment: segment,
    segmentStart: start,
    segmentEnd: end,
    remaining: (end - inLap).toDouble(),
    pace: pace,
    strokeRate: BandStatus.none,
    lapInZoneShare: null,
  );
}

/// The pace box at the size it has in the canvas screen "Live: Vorlage mit Zonen".
Future<void> _pump(
  WidgetTester tester,
  LapProgress progress, {
  Duration? pace = const Duration(minutes: 2, seconds: 7),
  Locale locale = const Locale('de'),
  Size size = const Size(350, 380),
  CourseDefinition course = _seerunde,
  GhostGap? ghostGap,
  Duration? averagePace,
  Duration rowed = Duration.zero,
  Duration? limit,
}) async {
  await tester.pumpWidget(
    LocalizedApp(
      locale: locale,
      home: Scaffold(
        body: Center(
          child: SizedBox.fromSize(
            size: size,
            child: PaceBox(
              progress: progress,
              course: course,
              pace: pace,
              averagePace: averagePace,
              ghostGap: ghostGap,
              rowed: rowed,
              limit: limit,
            ),
          ),
        ),
      ),
    ),
  );
}

String _text(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

/// The legend line with [key] shows [label] and [value].
void _expectLine(Key key, String label, String value) {
  final line = find.byKey(key);
  expect(find.descendant(of: line, matching: find.text(label)), findsOneWidget);
  expect(find.descendant(of: line, matching: find.text(value)), findsOneWidget);
}

/// The colour of the value in the legend line with [key].
Color? _valueColor(WidgetTester tester, Key key, String value) => tester
    .widget<Text>(
      find.descendant(of: find.byKey(key), matching: find.text(value)),
    )
    .style
    ?.color;

const _course = CourseDefinition(
  axis: CourseAxis.time,
  length: 1000,
  segments: [_free, _tempo, _free],
);

void main() {
  testWidgets('shows the pace in the zone, its targets, the lap and the zone', (
    tester,
  ) async {
    await _pump(tester, _at(460));

    expect(_text(tester, const Key('pace-box-pace')), '2:07');
    expect(find.text('PACE /500 M'), findsOneWidget);
    expect(find.byKey(const Key('pace-box-zone-in')), findsOneWidget);
    expect(_text(tester, const Key('pace-box-status')), 'In der Zone');
    expect(_text(tester, const Key('pace-box-targets')), _tempoTargets);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    _expectLine(const Key('pace-box-course'), 'Gesamt', '1 460 / 3 000 m');
    _expectLine(const Key('pace-box-lap'), 'Runde 2 / 3', 'noch 540 m');
    _expectLine(const Key('pace-box-segment'), 'Tempo', 'noch 340 m');
  });

  testWidgets(
    'shows the average pace of the session, or none before the first metre',
    (tester) async {
      await _pump(
        tester,
        _at(460),
        averagePace: const Duration(minutes: 2, seconds: 11),
      );
      _expectLine(const Key('pace-box-average'), 'Ø Pace', '2:11');

      await _pump(tester, _at(460));
      _expectLine(const Key('pace-box-average'), 'Ø Pace', '–:––');
    },
  );

  testWidgets(
    'asks for a faster pace when too slow, with an arrow and a word',
    (tester) async {
      await _pump(
        tester,
        _at(460, pace: BandStatus.above),
        pace: const Duration(minutes: 2, seconds: 13),
      );

      expect(_text(tester, const Key('pace-box-pace')), '2:13');
      expect(find.byKey(const Key('pace-box-zone-out')), findsOneWidget);
      expect(_text(tester, const Key('pace-box-status')), 'Schneller');
      expect(_text(tester, const Key('pace-box-targets')), _tempoTargets);
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    },
  );

  testWidgets('calls a zone without a name "Zone"', (tester) async {
    const unnamed = CourseSegment(
      length: 600,
      paceFastCs: 12500,
      paceSlowCs: 13000,
    );

    await _pump(tester, _at(460, segment: unnamed));

    _expectLine(const Key('pace-box-segment'), 'Zone', 'noch 340 m');
  });

  testWidgets('shows a free gap without a zone status', (tester) async {
    await _pump(
      tester,
      _at(100, segment: _free, index: 0, pace: BandStatus.none),
    );

    _expectLine(const Key('pace-box-segment'), 'frei', 'noch 100 m');
    expect(_text(tester, const Key('pace-box-targets')), 'frei');
    expect(find.byKey(const Key('pace-box-status')), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byIcon(Icons.arrow_upward), findsNothing);
  });

  testWidgets('names a zone with only a level without a zone status', (
    tester,
  ) async {
    const kraft = CourseSegment(
      length: 600,
      resistanceLevel: 12,
      zoneId: 4,
      zoneName: 'Kraft',
    );

    await _pump(tester, _at(460, segment: kraft, pace: BandStatus.none));

    _expectLine(const Key('pace-box-segment'), 'Kraft', 'noch 340 m');
    expect(_text(tester, const Key('pace-box-targets')), 'Kraft · Stufe 12');
    expect(find.byKey(const Key('pace-box-status')), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets(
    'keeps the pace in place in the zone, out of it and in a free gap',
    (tester) async {
      Rect pace() => tester.getRect(find.byKey(const Key('pace-box-pace')));

      await _pump(tester, _at(460));
      final inZone = pace();
      await _pump(tester, _at(460, pace: BandStatus.above));
      expect(pace(), inZone);
      await _pump(
        tester,
        _at(100, segment: _free, index: 0, pace: BandStatus.none),
      );
      expect(pace(), inZone);
    },
  );

  testWidgets('fits a long zone name into 400 × 400 without overflow', (
    tester,
  ) async {
    const long = CourseSegment(
      length: 600,
      paceFastCs: 12500,
      paceSlowCs: 13000,
      spmMin: 20,
      spmMax: 22,
      resistanceLevel: 8,
      zoneName: 'Langer Schwellenblock vor dem Endspurt',
    );

    await _pump(tester, _at(460, segment: long), size: const Size(400, 400));

    expect(tester.takeException(), isNull);
    expect(
      _text(tester, const Key('pace-box-targets')),
      'Langer Schwellenblock vor dem Endspurt · 2:05–2:10 · 20–22 spm · Stufe 8',
    );
  });

  testWidgets(
    'marks the segment line in the hardness of the zone, grey when free',
    (tester) async {
      Color? dot() =>
          (tester
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: find.byKey(const Key('pace-box-segment')),
                          matching: find.byType(DecoratedBox),
                        ),
                      )
                      .decoration
                  as BoxDecoration)
              .color;

      await _pump(tester, _at(460, pace: BandStatus.above));
      expect(dot(), intensityColor(zoneIntensity(_tempo)));

      await _pump(
        tester,
        _at(100, segment: _free, index: 0, pace: BandStatus.none),
      );
      expect(dot(), AppColors.textMuted);
    },
  );

  testWidgets(
    'tints the box in the zone colour and keeps it plain in a free gap',
    (tester) async {
      BandStatus? boxPace() =>
          tester.widget<ProgressFrame>(find.byType(ProgressFrame)).pace;
      Color? labelColor() =>
          tester.widget<Text>(find.text('PACE /500 M')).style?.color;

      await _pump(tester, _at(460));
      expect(ProgressFramePainter.boxColor(boxPace()), AppColors.zoneInSurface);
      expect(labelColor(), AppColors.zoneInText);
      expect(tester.widget<ZonePill>(find.byType(ZonePill)).filled, isTrue);

      await _pump(tester, _at(460, pace: BandStatus.above));
      expect(
        ProgressFramePainter.boxColor(boxPace()),
        AppColors.zoneOutSurface,
      );
      expect(labelColor(), AppColors.zoneOutText);

      await _pump(
        tester,
        _at(100, segment: _free, index: 0, pace: BandStatus.none),
      );
      expect(ProgressFramePainter.boxColor(boxPace()), AppColors.surface);
      expect(
        labelColor(),
        isNot(anyOf(AppColors.zoneInText, AppColors.zoneOutText)),
      );
    },
  );

  testWidgets(
    'names the lap without a total and leaves out the course with an open number of laps',
    (tester) async {
      await _pump(tester, _at(460, laps: null));

      _expectLine(const Key('pace-box-lap'), 'Runde 2', 'noch 540 m');
      expect(find.byKey(const Key('pace-box-course')), findsNothing);
    },
  );

  testWidgets(
    'shows the rowing time left and the lap without a total with a time limit',
    (tester) async {
      // 30 minutes, after 15:00.4 of rowing time without pauses.
      await _pump(
        tester,
        _at(460, laps: null, lap: 3),
        rowed: const Duration(minutes: 15, milliseconds: 400),
        limit: const Duration(minutes: 30),
      );

      _expectLine(const Key('pace-box-course'), 'Gesamt', 'noch 15:00');
      _expectLine(const Key('pace-box-lap'), 'Runde 3', 'noch 540 m');

      await _pump(
        tester,
        _at(460, laps: null),
        limit: const Duration(minutes: 90),
        locale: const Locale('en'),
      );
      _expectLine(const Key('pace-box-course'), 'Total', '1:30:00 to go');
    },
  );

  testWidgets('shows times on a time course', (tester) async {
    const course = CourseDefinition(
      axis: CourseAxis.time,
      length: 1000,
      segments: [_free, _tempo, _free],
    );

    await _pump(tester, _at(460), course: course);

    _expectLine(const Key('pace-box-course'), 'Gesamt', '24:20 / 50:00');
    _expectLine(const Key('pace-box-lap'), 'Runde 2 / 3', 'noch 9:00');
    _expectLine(const Key('pace-box-segment'), 'Tempo', 'noch 5:40');
  });

  testWidgets('speaks English', (tester) async {
    await _pump(tester, _at(460), locale: const Locale('en'));

    expect(_text(tester, const Key('pace-box-status')), 'In the zone');
    expect(
      _text(tester, const Key('pace-box-targets')),
      'Tempo · 2:05–2:10 · 20–22 spm · Level 8',
    );
    _expectLine(const Key('pace-box-course'), 'Total', '1 460 / 3 000 m');
    _expectLine(const Key('pace-box-lap'), 'Lap 2 / 3', '540 m to go');
    _expectLine(const Key('pace-box-segment'), 'Tempo', '340 m to go');
  });

  testWidgets('shows a dash without a pace', (tester) async {
    await _pump(tester, _at(460, pace: BandStatus.missing), pace: null);

    expect(_text(tester, const Key('pace-box-pace')), '–:––');
    expect(_text(tester, const Key('pace-box-status')), 'Keine Pace');
    expect(_text(tester, const Key('pace-box-targets')), _tempoTargets);
  });

  testWidgets(
    'shows a gap behind the ghost on a distance course in seconds, in orange',
    (tester) async {
      await _pump(
        tester,
        _at(460),
        ghostGap: const GhostGap(
          axis: CourseAxis.distance,
          amount: 7.62,
          ghostAhead: true,
        ),
      );

      const key = Key('pace-box-ghost-behind');
      _expectLine(key, 'Ghost', '7.6 s vor dir');
      expect(_valueColor(tester, key, '7.6 s vor dir'), AppColors.zoneOut);
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(GhostSymbol),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows a lead over the ghost on a time course in metres, in blue',
    (tester) async {
      await _pump(
        tester,
        _at(460),
        course: _course,
        ghostGap: const GhostGap(
          axis: CourseAxis.time,
          amount: 12.3,
          ghostAhead: false,
        ),
      );

      const key = Key('pace-box-ghost-ahead');
      _expectLine(key, 'Ghost', '12 m hinter dir');
      expect(_valueColor(tester, key, '12 m hinter dir'), AppColors.zoneIn);
    },
  );

  testWidgets('shows a gap of a minute and more like a lap time', (
    tester,
  ) async {
    await _pump(
      tester,
      _at(460),
      ghostGap: const GhostGap(
        axis: CourseAxis.distance,
        amount: 72.34,
        ghostAhead: true,
      ),
    );

    _expectLine(const Key('pace-box-ghost-behind'), 'Ghost', '1:12.3 vor dir');
  });

  testWidgets('says level instead of a gap that rounds to nothing', (
    tester,
  ) async {
    await _pump(
      tester,
      _at(460),
      ghostGap: const GhostGap(
        axis: CourseAxis.distance,
        amount: 0.04,
        ghostAhead: true,
      ),
    );

    const key = Key('pace-box-ghost-level');
    _expectLine(key, 'Ghost', 'gleichauf');
    expect(_valueColor(tester, key, 'gleichauf'), AppColors.textMuted);
  });

  testWidgets('speaks English about the ghost', (tester) async {
    await _pump(
      tester,
      _at(460),
      locale: const Locale('en'),
      ghostGap: const GhostGap(
        axis: CourseAxis.distance,
        amount: 2.9,
        ghostAhead: false,
      ),
    );

    _expectLine(const Key('pace-box-ghost-ahead'), 'Ghost', '2.9 s behind you');
  });

  testWidgets('has no ghost line without a ghost of the workout', (
    tester,
  ) async {
    await _pump(tester, _at(460, laps: null));

    expect(find.text('Ghost'), findsNothing);
    expect(find.byType(GhostSymbol), findsNothing);
    _expectLine(const Key('pace-box-lap'), 'Runde 2', 'noch 540 m');
  });

  // Portrait box, landscape box on a phone on its side and a small phone, with and without a ghost.
  for (final (size, gap, limit) in const [
    (Size(350, 380), null, null),
    (Size(330, 320), null, null),
    (Size(300, 280), null, null),
    (
      Size(350, 380),
      GhostGap(axis: CourseAxis.distance, amount: 7.6, ghostAhead: true),
      null,
    ),
    (
      Size(330, 320),
      GhostGap(axis: CourseAxis.distance, amount: 72.3, ghostAhead: true),
      null,
    ),
    (
      Size(300, 280),
      GhostGap(axis: CourseAxis.time, amount: 1234, ghostAhead: false),
      null,
    ),
    (
      Size(240, 220),
      GhostGap(axis: CourseAxis.distance, amount: 7.6, ghostAhead: true),
      null,
    ),
    (
      Size(330, 320),
      GhostGap(axis: CourseAxis.distance, amount: 72.3, ghostAhead: true),
      Duration(minutes: 180),
    ),
    (Size(240, 220), null, Duration(minutes: 180)),
  ]) {
    testWidgets(
      'fits ${size.width.toInt()} × ${size.height.toInt()} ${gap == null ? 'without' : 'with'} a ghost '
      '${limit == null ? '' : 'and a time limit '}with the pace as the largest text',
      (tester) async {
        await _pump(
          tester,
          _at(460, pace: BandStatus.above, laps: limit == null ? 3 : null),
          size: size,
          ghostGap: gap,
          limit: limit,
        );

        expect(tester.takeException(), isNull);
        final pace = tester
            .getRect(find.byKey(const Key('pace-box-pace')))
            .height;
        for (final text in tester.widgetList<Text>(find.byType(Text))) {
          if (text.key == const Key('pace-box-pace')) continue;
          expect(
            tester.getRect(find.byWidget(text)).height,
            lessThan(pace),
            reason: text.data,
          );
        }
      },
    );
  }
}
