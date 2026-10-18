import 'package:aergrow/features/live/formatters.dart';
import 'package:aergrow/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  final de = lookupAppLocalizations(const Locale('de'));
  final en = lookupAppLocalizations(const Locale('en'));

  // The app loads the date symbols with its localizations; plain tests do it here.
  setUpAll(initializeDateFormatting);

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

  test('formatStrokeRate shows one decimal with the decimal mark of the language', () {
    expect(formatStrokeRate(de, 22.46), '22,5');
    expect(formatStrokeRate(en, 22.46), '22.5');
    expect(formatStrokeRate(de, null), '–');
  });

  test('formatDriveLength shows whole centimeters', () {
    expect(formatDriveLength(de, 1.06), '106 cm');
    expect(formatDriveLength(en, 1.06), '106 cm');
    expect(formatDriveLength(de, 0.6), '60 cm');
    // A length of 0.01 m units from the PM5, e.g. 106 for 1.06 m, without rounding errors.
    expect(formatDriveLength(de, 106 * 0.01), '106 cm');
    expect(formatDriveLength(de, 0.995), '100 cm');
  });

  test('formatDriveLength leaves out a missing length instead of showing 0 cm', () {
    expect(formatDriveLength(de, null), isNull);
    expect(formatDriveLength(en, 0), isNull);
  });

  test('formatDateTime shows the local date and time in the format of the language', () {
    expect(formatDateTime(de, DateTime(2026, 10, 15, 18, 30)), '15.10.2026, 18:30');
    expect(formatDateTime(en, DateTime(2026, 10, 15, 18, 30)), 'Oct 15, 2026, 18:30');
    expect(formatDateTime(de, DateTime(2026, 10, 5, 8, 7)), '05.10.2026, 08:07');
  });

  test('keeps pace and times the same in every language', () {
    // They take no language: the PM5 shows them the same way everywhere (Design D5).
    expect(formatPace(const Duration(milliseconds: 125300)), '2:05.3');
    expect(formatLapTime(const Duration(milliseconds: 239400)), '3:59.4');
  });
}
