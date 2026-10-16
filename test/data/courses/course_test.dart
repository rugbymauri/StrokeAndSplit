import 'package:aergrow/data/courses/course.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a new course is one segment over its whole length', () {
    final course = CourseDefinition.single(axis: CourseAxis.distance, length: 1000);

    expect(course.segments, [const CourseSegment(length: 1000)]);
    expect(course.segments.single.isFree, isTrue);
    expect(courseErrors(course), isEmpty);
  });

  test('knows where its segments end', () {
    const course = CourseDefinition(axis: CourseAxis.distance, length: 1000, segments: [
      CourseSegment(length: 200),
      CourseSegment(length: 600),
      CourseSegment(length: 200),
    ]);

    expect(course.segmentEnds, [200, 800, 1000]);
  });

  test('formats lengths in the unit of the axis', () {
    expect(formatCourseLength(CourseAxis.distance, 1000), '1000 m');
    expect(formatCourseLength(CourseAxis.time, 240), '4:00');
    expect(formatCourseLength(CourseAxis.time, 65), '1:05');
  });

  group('rejects', () {
    test('a length of zero', () {
      final course = CourseDefinition.single(axis: CourseAxis.distance, length: 0);

      expect(courseErrors(course), ['Die Länge fehlt.']);
    });

    test('segments that do not add up to the length', () {
      const course = CourseDefinition(axis: CourseAxis.distance, length: 1000, segments: [
        CourseSegment(length: 300),
        CourseSegment(length: 600),
      ]);

      expect(courseErrors(course), ['Die Segmente ergeben 900 m, das sind 100 m zu wenig.']);
    });

    test('segments longer than a time course', () {
      const course = CourseDefinition(axis: CourseAxis.time, length: 240, segments: [
        CourseSegment(length: 120),
        CourseSegment(length: 150),
      ]);

      expect(courseErrors(course), ['Die Segmente ergeben 4:30, das sind 0:30 zu viel.']);
    });

    test('a pace band with the slower pace as the fastest bound', () {
      const course = CourseDefinition(axis: CourseAxis.distance, length: 1000, segments: [
        CourseSegment(length: 1000, paceFastCs: 13000, paceSlowCs: 12500),
      ]);

      expect(courseErrors(course), ['Segment 1: Die schnellste Pace ist langsamer als die langsamste.']);
    });

    test('a stroke rate band the wrong way round', () {
      const course = CourseDefinition(axis: CourseAxis.distance, length: 1000, segments: [
        CourseSegment(length: 1000, spmMin: 24, spmMax: 20),
      ]);

      expect(courseErrors(course), ['Segment 1: Die niedrigste Schlagzahl liegt über der höchsten.']);
    });

    test('a band with only one bound', () {
      const course = CourseDefinition(axis: CourseAxis.distance, length: 1000, segments: [
        CourseSegment(length: 1000, paceFastCs: 12500),
      ]);

      expect(courseErrors(course), ['Segment 1: Für das Pace-Band fehlt eine Grenze.']);
    });
  });

  test('accepts segments with both bands', () {
    const course = CourseDefinition(axis: CourseAxis.distance, length: 1000, segments: [
      CourseSegment(length: 200),
      CourseSegment(length: 600, paceFastCs: 12500, paceSlowCs: 13000, spmMin: 20, spmMax: 22),
      CourseSegment(length: 200),
    ]);

    expect(courseErrors(course), isEmpty);
    expect(course.segments[1].isFree, isFalse);
  });
}
