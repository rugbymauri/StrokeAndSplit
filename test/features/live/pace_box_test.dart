import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/app/design_tokens.dart';
import 'package:aergrow/app/widgets/ghost_symbol.dart';
import 'package:aergrow/data/courses/lap_tracker.dart';
import 'package:aergrow/data/ghost/ghost.dart';
import 'package:aergrow/features/live/pace_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/localized_app.dart';

const _tempo = CourseSegment(length: 600, paceFastCs: 12500, paceSlowCs: 13000, zoneId: 1, zoneName: 'Tempo');
const _free = CourseSegment(length: 200);

/// 1000 m with the zone "Tempo" from 200 to 800 m.
const _seerunde = CourseDefinition(axis: CourseAxis.distance, length: 1000, segments: [_free, _tempo, _free]);

/// At [inLap] metres of lap 2 of 3 (or of an open number of laps) in [segment] number [index].
LapProgress _at(
  int inLap, {
  CourseSegment segment = _tempo,
  int index = 1,
  BandStatus pace = BandStatus.inBand,
  int? laps = 3,
}) {
  final start = _seerunde.segmentStarts[index];
  final end = _seerunde.segmentEnds[index];
  return LapProgress(
    lap: 2,
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
}) async {
  await tester.pumpWidget(LocalizedApp(
    locale: locale,
    home: Scaffold(
      body: Center(
        child: SizedBox.fromSize(
          size: size,
          child: PaceBox(progress: progress, course: course, pace: pace, ghostGap: ghostGap),
        ),
      ),
    ),
  ));
}

String _text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

/// The legend line with [key] shows [label] and [value].
void _expectLine(Key key, String label, String value) {
  final line = find.byKey(key);
  expect(find.descendant(of: line, matching: find.text(label)), findsOneWidget);
  expect(find.descendant(of: line, matching: find.text(value)), findsOneWidget);
}

/// The colour of the value in the legend line with [key].
Color? _valueColor(WidgetTester tester, Key key, String value) => tester
    .widget<Text>(find.descendant(of: find.byKey(key), matching: find.text(value)))
    .style
    ?.color;

const _course = CourseDefinition(axis: CourseAxis.time, length: 1000, segments: [_free, _tempo, _free]);

void main() {
  testWidgets('shows the pace in the zone with its band, the lap and the zone', (tester) async {
    await _pump(tester, _at(460));

    expect(_text(tester, const Key('pace-box-pace')), '2:07.0');
    expect(find.text('PACE /500 M'), findsOneWidget);
    expect(find.byKey(const Key('pace-box-zone-in')), findsOneWidget);
    expect(_text(tester, const Key('pace-box-status')), 'In der Zone · 2:05–2:10');
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    _expectLine(const Key('pace-box-course'), 'Gesamt', '1 460 / 3 000 m');
    _expectLine(const Key('pace-box-lap'), 'Runde 2 / 3', 'noch 540 m');
    _expectLine(const Key('pace-box-segment'), 'Tempo', 'noch 340 m');
  });

  testWidgets('asks for a faster pace when too slow, with an arrow and a word', (tester) async {
    await _pump(tester, _at(460, pace: BandStatus.above), pace: const Duration(minutes: 2, seconds: 13));

    expect(_text(tester, const Key('pace-box-pace')), '2:13.0');
    expect(find.byKey(const Key('pace-box-zone-out')), findsOneWidget);
    expect(_text(tester, const Key('pace-box-status')), 'Schneller · 2:05–2:10');
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });

  testWidgets('calls a zone without a name "Zone"', (tester) async {
    const unnamed = CourseSegment(length: 600, paceFastCs: 12500, paceSlowCs: 13000);

    await _pump(tester, _at(460, segment: unnamed));

    _expectLine(const Key('pace-box-segment'), 'Zone', 'noch 340 m');
  });

  testWidgets('shows a free gap without a zone status', (tester) async {
    await _pump(tester, _at(100, segment: _free, index: 0, pace: BandStatus.none));

    _expectLine(const Key('pace-box-segment'), 'frei', 'noch 100 m');
    expect(find.byKey(const Key('pace-box-status')), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byIcon(Icons.arrow_upward), findsNothing);
  });

  testWidgets('names the lap without a total and leaves out the course with an open number of laps', (tester) async {
    await _pump(tester, _at(460, laps: null));

    _expectLine(const Key('pace-box-lap'), 'Runde 2', 'noch 540 m');
    expect(find.byKey(const Key('pace-box-course')), findsNothing);
  });

  testWidgets('shows times on a time course', (tester) async {
    const course = CourseDefinition(axis: CourseAxis.time, length: 1000, segments: [_free, _tempo, _free]);

    await _pump(tester, _at(460), course: course);

    _expectLine(const Key('pace-box-course'), 'Gesamt', '24:20 / 50:00');
    _expectLine(const Key('pace-box-lap'), 'Runde 2 / 3', 'noch 9:00');
    _expectLine(const Key('pace-box-segment'), 'Tempo', 'noch 5:40');
  });

  testWidgets('speaks English', (tester) async {
    await _pump(tester, _at(460), locale: const Locale('en'));

    expect(_text(tester, const Key('pace-box-status')), 'In the zone · 2:05–2:10');
    _expectLine(const Key('pace-box-course'), 'Total', '1 460 / 3 000 m');
    _expectLine(const Key('pace-box-lap'), 'Lap 2 / 3', '540 m to go');
    _expectLine(const Key('pace-box-segment'), 'Tempo', '340 m to go');
  });

  testWidgets('shows a dash without a pace', (tester) async {
    await _pump(tester, _at(460, pace: BandStatus.missing), pace: null);

    expect(_text(tester, const Key('pace-box-pace')), '–:––.–');
    expect(_text(tester, const Key('pace-box-status')), 'Keine Pace · 2:05–2:10');
  });

  testWidgets('shows a gap behind the ghost on a distance course in seconds, in orange', (tester) async {
    await _pump(tester, _at(460),
        ghostGap: const GhostGap(axis: CourseAxis.distance, amount: 7.62, ghostAhead: true));

    const key = Key('pace-box-ghost-behind');
    _expectLine(key, 'Ghost', '7.6 s vor dir');
    expect(_valueColor(tester, key, '7.6 s vor dir'), AppColors.zoneOut);
    expect(find.descendant(of: find.byKey(key), matching: find.byType(GhostSymbol)), findsOneWidget);
  });

  testWidgets('shows a lead over the ghost on a time course in metres, in blue', (tester) async {
    await _pump(tester, _at(460),
        course: _course, ghostGap: const GhostGap(axis: CourseAxis.time, amount: 12.3, ghostAhead: false));

    const key = Key('pace-box-ghost-ahead');
    _expectLine(key, 'Ghost', '12 m hinter dir');
    expect(_valueColor(tester, key, '12 m hinter dir'), AppColors.zoneIn);
  });

  testWidgets('shows a gap of a minute and more like a lap time', (tester) async {
    await _pump(tester, _at(460),
        ghostGap: const GhostGap(axis: CourseAxis.distance, amount: 72.34, ghostAhead: true));

    _expectLine(const Key('pace-box-ghost-behind'), 'Ghost', '1:12.3 vor dir');
  });

  testWidgets('says level instead of a gap that rounds to nothing', (tester) async {
    await _pump(tester, _at(460),
        ghostGap: const GhostGap(axis: CourseAxis.distance, amount: 0.04, ghostAhead: true));

    const key = Key('pace-box-ghost-level');
    _expectLine(key, 'Ghost', 'gleichauf');
    expect(_valueColor(tester, key, 'gleichauf'), AppColors.textMuted);
  });

  testWidgets('speaks English about the ghost', (tester) async {
    await _pump(tester, _at(460),
        locale: const Locale('en'),
        ghostGap: const GhostGap(axis: CourseAxis.distance, amount: 2.9, ghostAhead: false));

    _expectLine(const Key('pace-box-ghost-ahead'), 'Ghost', '2.9 s behind you');
  });

  testWidgets('has no ghost line without a ghost of the template', (tester) async {
    await _pump(tester, _at(460, laps: null));

    expect(find.text('Ghost'), findsNothing);
    expect(find.byType(GhostSymbol), findsNothing);
    _expectLine(const Key('pace-box-lap'), 'Runde 2', 'noch 540 m');
  });

  // Portrait box, landscape box on a phone on its side and a small phone, with and without a ghost.
  for (final (size, gap) in const [
    (Size(350, 380), null),
    (Size(330, 320), null),
    (Size(300, 280), null),
    (Size(350, 380), GhostGap(axis: CourseAxis.distance, amount: 7.6, ghostAhead: true)),
    (Size(330, 320), GhostGap(axis: CourseAxis.distance, amount: 72.3, ghostAhead: true)),
    (Size(300, 280), GhostGap(axis: CourseAxis.time, amount: 1234, ghostAhead: false)),
    (Size(240, 220), GhostGap(axis: CourseAxis.distance, amount: 7.6, ghostAhead: true)),
  ]) {
    testWidgets(
        'fits ${size.width.toInt()} × ${size.height.toInt()} ${gap == null ? 'without' : 'with'} a ghost '
        'with the pace as the largest text', (tester) async {
      await _pump(tester, _at(460, pace: BandStatus.above), size: size, ghostGap: gap);

      expect(tester.takeException(), isNull);
      final pace = tester.getRect(find.byKey(const Key('pace-box-pace'))).height;
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        if (text.key == const Key('pace-box-pace')) continue;
        expect(tester.getRect(find.byWidget(text)).height, lessThan(pace), reason: text.data);
      }
    });
  }
}
