import 'package:aergrow/features/live/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatPace', () {
    test('shows minutes, seconds and tenths', () {
      expect(formatPace(const Duration(milliseconds: 125300)), '2:05.3');
      expect(formatPace(const Duration(milliseconds: 98040)), '1:38.0');
    });

    test('rounds to tenths, carrying over into the next minute', () {
      expect(formatPace(const Duration(milliseconds: 125349)), '2:05.3');
      expect(formatPace(const Duration(milliseconds: 119960)), '2:00.0');
    });

    test('shows placeholders without a pace', () {
      expect(formatPace(null), '–:––.–');
    });
  });

  group('formatElapsed', () {
    test('shows minutes and seconds below an hour', () {
      expect(formatElapsed(Duration.zero), '0:00');
      expect(formatElapsed(const Duration(minutes: 12, seconds: 34, milliseconds: 999)), '12:34');
    });

    test('adds hours from one hour on', () {
      expect(formatElapsed(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
    });
  });

  test('formatDistance shows whole meters', () {
    expect(formatDistance(0), '0');
    expect(formatDistance(1234.9), '1234');
  });

  test('formatWhole shows a dash for unknown values', () {
    expect(formatWhole(203), '203');
    expect(formatWhole(null), '–');
  });

  test('formatStrokeRate shows one decimal', () {
    expect(formatStrokeRate(22.46), '22.5');
    expect(formatStrokeRate(null), '–');
  });

  test('formatDateTime shows the local date and time', () {
    expect(formatDateTime(DateTime(2026, 10, 5, 8, 7)), '05.10.2026, 08:07');
  });
}
