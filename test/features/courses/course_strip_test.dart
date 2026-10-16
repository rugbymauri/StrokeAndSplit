import 'package:aergrow/app/design_tokens.dart';
import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/features/courses/course_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/localized_app.dart';

Future<void> _pump(WidgetTester tester, CourseStrip strip) =>
    tester.pumpWidget(LocalizedApp(home: Scaffold(body: SizedBox(width: 400, child: strip))));

Finder _segment(int i) => find.byKey(ValueKey('course-strip-segment-$i'));

Color? _colorOf(WidgetTester tester, int i) =>
    (tester.widget<Container>(_segment(i)).decoration! as BoxDecoration).color;

CourseDefinition _course(List<CourseSegment> segments) => CourseDefinition(
      axis: CourseAxis.distance,
      length: segments.fold(0, (sum, s) => sum + s.length),
      segments: segments,
    );

void main() {
  testWidgets('a free course is one grey segment over the whole width', (tester) async {
    await _pump(tester, CourseStrip(definition: CourseDefinition.single(axis: CourseAxis.distance, length: 2000)));

    expect(_colorOf(tester, 0), AppColors.line);
    expect(tester.getSize(find.byType(CourseStrip)), const Size(400, CourseStrip.listHeight));
    expect(_segment(1), findsNothing);
  });

  testWidgets('a placed zone is blue, as wide as it is long, with its name', (tester) async {
    final strip = CourseStrip(
      definition: _course(const [
        CourseSegment(length: 200),
        CourseSegment(length: 600, paceFastCs: 12500, paceSlowCs: 13000, zoneId: 1, zoneName: 'Tempo'),
        CourseSegment(length: 200),
      ]),
      height: CourseStrip.namedHeight,
      showNames: true,
      selected: 1,
    );
    await _pump(tester, strip);

    expect([for (final i in [0, 1, 2]) _colorOf(tester, i)], [AppColors.line, AppColors.zoneIn, AppColors.line]);
    expect(tester.getSize(_segment(1)).width, closeTo(400 * 0.6, 0.01));
    expect(tester.getSize(_segment(1)).height, CourseStrip.namedHeight);
    expect(find.text('Tempo'), findsOneWidget);
    final outline = tester.widget<Container>(_segment(1)).foregroundDecoration! as BoxDecoration;
    expect(outline.border, Border.all(color: AppColors.text, width: 2));
    expect(tester.widget<Container>(_segment(0)).foregroundDecoration, isNull);
  });

  testWidgets('a zone without a name is called Zone, free gaps stay unlabelled', (tester) async {
    await _pump(
      tester,
      CourseStrip(
        definition: _course(const [CourseSegment(length: 500), CourseSegment(length: 500, spmMin: 20, spmMax: 24)]),
        showNames: true,
      ),
    );

    expect(find.text('Zone'), findsOneWidget);
    expect(find.text('frei'), findsNothing);
  });

  testWidgets('faster pace bands are brighter, stroke-rate bands stay zoneIn', (tester) async {
    await _pump(
      tester,
      CourseStrip(
        definition: _course(const [
          CourseSegment(length: 100, paceFastCs: 13000, paceSlowCs: 13500),
          CourseSegment(length: 100, paceFastCs: 12000, paceSlowCs: 12500),
          CourseSegment(length: 100, paceFastCs: 12500, paceSlowCs: 13000),
          CourseSegment(length: 100, paceFastCs: 12000, paceSlowCs: 12500),
          CourseSegment(length: 100, spmMin: 18, spmMax: 20),
          CourseSegment(length: 100),
        ]),
      ),
    );

    final middle = Color.lerp(CourseStrip.fastestPace, CourseStrip.slowestPace, 0.5);
    expect([for (final i in [0, 1, 2, 3, 4, 5]) _colorOf(tester, i)], [
      CourseStrip.slowestPace,
      CourseStrip.fastestPace,
      middle,
      CourseStrip.fastestPace,
      AppColors.zoneIn,
      AppColors.line,
    ]);
  });

  testWidgets('tapping a segment reports its index', (tester) async {
    int? tapped;
    await _pump(
      tester,
      CourseStrip(
        definition: _course(const [CourseSegment(length: 500), CourseSegment(length: 500, spmMin: 20, spmMax: 24)]),
        height: CourseStrip.namedHeight,
        onSegmentTap: (i) => tapped = i,
      ),
    );

    await tester.tap(_segment(1));
    expect(tapped, 1);
  });
}
