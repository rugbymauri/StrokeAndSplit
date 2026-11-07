import 'package:strokesplit/data/courses/course.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a new course is one segment over its whole length', () {
    final course = CourseDefinition.single(
      axis: CourseAxis.distance,
      length: 1000,
    );

    expect(course.segments, [const CourseSegment(length: 1000)]);
    expect(course.segments.single.isFree, isTrue);
  });

  test('knows where its segments end', () {
    const course = CourseDefinition(
      axis: CourseAxis.distance,
      length: 1000,
      segments: [
        CourseSegment(length: 200),
        CourseSegment(length: 600),
        CourseSegment(length: 200),
      ],
    );

    expect(course.segmentStarts, [0, 200, 800]);
    expect(course.segmentEnds, [200, 800, 1000]);
  });

  test('formats lengths in the unit of the axis', () {
    expect(formatCourseLength(CourseAxis.distance, 1000), '1000 m');
    expect(formatCourseLength(CourseAxis.time, 240), '4:00');
    expect(formatCourseLength(CourseAxis.time, 65), '1:05');
    expect(formatCourseRange(CourseAxis.distance, 500, 600), '500–600 m');
    expect(formatCourseRange(CourseAxis.time, 60, 300), '1:00–5:00');
  });

  test('a segment with only a level is a zone without a band', () {
    const level = CourseSegment(length: 500, resistanceLevel: 12);
    const pace = CourseSegment(
      length: 500,
      paceFastCs: 12500,
      paceSlowCs: 13000,
    );

    expect(level.isFree, isFalse);
    expect(level.hasBand, isFalse);
    expect(pace.isFree, isFalse);
    expect(pace.hasBand, isTrue);
    expect(const CourseSegment(length: 500).isFree, isTrue);
  });
}
