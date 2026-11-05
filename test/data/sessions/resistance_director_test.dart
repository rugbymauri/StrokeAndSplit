import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/sessions/resistance_director.dart';

const _warmUp = CourseSegment(length: 500);
const _sprint = CourseSegment(length: 100, spmMin: 30, spmMax: 34, resistanceLevel: 10, zoneName: 'Sprint');
const _recovery = CourseSegment(length: 200, spmMin: 18, spmMax: 20, resistanceLevel: 3, zoneName: 'Erholung');
const _steady = CourseSegment(length: 200, spmMin: 20, spmMax: 22, zoneName: 'Ausdauer');

ResistanceDirector _director() => ResistanceDirector(range: const ResistanceRange(min: 1, max: 15));

void main() {
  test('rows an interval on the levels of its zones', () {
    fakeAsync((async) {
      final director = _director()..reported(4);

      expect(director.segmentStarted(_warmUp), isNull, reason: 'warm-up stays on 4');
      expect(director.segmentStarted(_sprint), 10);
      director.reported(10);
      expect(director.segmentStarted(_recovery), 3);
    });
  });

  test('returns to the base level in a free part and a zone without level', () {
    fakeAsync((async) {
      final director = _director()..reported(4);
      director.segmentStarted(_sprint);
      director.reported(10);

      expect(director.segmentStarted(_warmUp), 4);
      director.reported(4);
      director.segmentStarted(_sprint);
      director.reported(10);
      expect(director.segmentStarted(_steady), 4);
    });
  });

  test('a new lap starting without level gets the base level', () {
    fakeAsync((async) {
      final director = _director()..reported(4);
      director.segmentStarted(_warmUp);
      director.segmentStarted(_sprint);
      director.reported(10);

      expect(director.segmentStarted(_warmUp), 4);
    });
  });

  test('sends nothing on its own when rowing freely', () {
    fakeAsync((async) {
      final director = _director()..reported(4);
      for (final level in [4, 6, 2]) {
        async.elapse(const Duration(seconds: 5));
        director.reported(level);
      }
      expect(director.target, 2);
      expect(director.reconnected(), 2, reason: 'only after reconnecting');
    });
  });

  test('sends nothing when the next segment asks for the level the rower has', () {
    fakeAsync((async) {
      final director = _director()..reported(10);

      expect(director.segmentStarted(_sprint), isNull);
      expect(director.segmentStarted(_sprint), isNull);
    });
  });

  test('keeps a level within the range of the rower', () {
    fakeAsync((async) {
      final director = _director()..reported(4);

      expect(director.segmentStarted(const CourseSegment(length: 100, spmMin: 20, spmMax: 22, resistanceLevel: 20)), 15);
    });
  });

  test('a level turned up by hand holds until the end of the segment', () {
    fakeAsync((async) {
      final director = _director()..reported(4);
      director.segmentStarted(_sprint);
      director.reported(10);
      async.elapse(const Duration(seconds: 10));

      director.reported(12);
      expect(director.target, 12);
      expect(director.segmentStarted(_recovery), 3);
      director.reported(3);
      expect(director.segmentStarted(_warmUp), 4, reason: 'the base level stays');
    });
  });

  test('a change by hand in a segment without level becomes the base level', () {
    fakeAsync((async) {
      final director = _director()..reported(4);
      director.segmentStarted(_warmUp);
      async.elapse(const Duration(seconds: 10));
      director.reported(5);
      director.segmentStarted(_sprint);
      director.reported(10);

      expect(director.segmentStarted(_warmUp), 5);
      expect(director.baseLevel, 5);
    });
  });

  test('taps on + and − are changes by hand', () {
    fakeAsync((async) {
      final director = _director()..reported(4);
      director.segmentStarted(_warmUp);

      expect(director.step(1), 5);
      director.reported(5);
      director.segmentStarted(_sprint);
      director.reported(10);
      expect(director.step(-1), 9);
      director.reported(9);
      expect(director.segmentStarted(_warmUp), 5);
    });
  });

  test('three quick taps from 6 end on 9', () {
    fakeAsync((async) {
      final director = _director()..reported(6);

      expect([director.step(1), director.step(1), director.step(1)], [7, 8, 9]);
      director.reported(7);
      expect(director.target, 9, reason: 'a level on the way is no change by hand');
    });
  });

  test('no step beyond the range', () {
    fakeAsync((async) {
      final director = _director()..reported(15);

      expect(director.step(1), isNull);
      expect(director.step(-1), 14);
    });
  });

  test('a change during a pause is a change by hand', () {
    fakeAsync((async) {
      final director = _director()..reported(4);
      director.segmentStarted(_sprint);
      director.reported(10);
      async.elapse(const Duration(seconds: 30));

      director.reported(3);

      expect(director.target, 3);
      expect(director.reconnected(), 3);
      expect(director.segmentStarted(_recovery), isNull, reason: 'the rower is on 3 already');
    });
  });

  test('sends the level asked for again after reconnecting', () {
    fakeAsync((async) {
      final director = _director()..reported(4);
      director.segmentStarted(_sprint);
      director.reported(10);

      expect(director.reconnected(), 10);
    });
  });

  test('the old level reported within 3 seconds after sending is no change by hand', () {
    fakeAsync((async) {
      final director = _director()..reported(4);
      director.segmentStarted(_sprint);
      async.elapse(const Duration(seconds: 1));
      director.reported(4);
      async.elapse(const Duration(seconds: 1));
      director.reported(10);

      expect(director.target, 10);
    });
  });

  test('the old level still reported after 3 seconds counts', () {
    fakeAsync((async) {
      final director = _director()..reported(4);
      director.segmentStarted(_sprint);
      async.elapse(const Duration(seconds: 4));
      director.reported(4);

      expect(director.target, 4);
    });
  });

  test('sends nothing more after a refusal until the next segment', () {
    fakeAsync((async) {
      final director = _director()..reported(4);
      expect(director.segmentStarted(_sprint), 10);
      director.failed(10);
      async.elapse(const Duration(seconds: 1));
      director.reported(4);

      expect(director.target, 4);
      expect(director.reconnected(), 4);
      expect(director.segmentStarted(_recovery), 3);
    });
  });

  test('a refused tap leaves the base level', () {
    fakeAsync((async) {
      final director = _director()..reported(4);
      director.segmentStarted(_warmUp);
      director.step(1);
      director.failed(5);

      expect((director.target, director.baseLevel), (4, 4));
    });
  });

  test('a level reported in tenths counts as whole level', () {
    fakeAsync((async) {
      final director = _director()..reported(60);

      expect(director.target, 6);
    });
  });

  test('a segment with level before any report is sent', () {
    fakeAsync((async) {
      final director = _director();

      expect(director.segmentStarted(_warmUp), isNull);
      expect(director.segmentStarted(_sprint), 10);
    });
  });

  test('a new session takes the level the rower has as base level', () {
    fakeAsync((async) {
      final director = _director()..reported(4);
      director.segmentStarted(_sprint);
      director.reported(10);

      director.sessionStarted();

      expect(director.baseLevel, 10);
      expect(director.segmentStarted(_warmUp), isNull);
    });
  });
}
