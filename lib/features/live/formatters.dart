/// Display formats as rowers know them from the PM5; date and decimals
/// follow the language of the app (Change translations, Design D5).
library;

import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';

const _noValue = '–';

/// Pace per 500 m with tenths, e.g. `2:05.3`.
String formatPace(Duration? pace) {
  if (pace == null) return '–:––.–';
  final tenths = (pace.inMilliseconds / 100).round();
  final minutes = tenths ~/ 600;
  final seconds = (tenths % 600) ~/ 10;
  return '$minutes:${_two(seconds)}.${tenths % 10}';
}

/// Elapsed time, e.g. `12:34` or `1:02:03`.
String formatElapsed(Duration elapsed) {
  final totalSeconds = elapsed.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = totalSeconds % 3600 ~/ 60;
  final seconds = totalSeconds % 60;
  return hours > 0 ? '$hours:${_two(minutes)}:${_two(seconds)}' : '$minutes:${_two(seconds)}';
}

/// A lap time with tenths, e.g. `3:59.4` or `1:02:03.4`.
String formatLapTime(Duration time) {
  final tenths = (time.inMilliseconds / 100).round();
  return '${formatElapsed(Duration(seconds: tenths ~/ 10))}.${tenths % 10}';
}

/// Distance in whole meters, e.g. `1234`.
String formatDistance(double meters) => meters.floor().toString();

/// Whole numbers with thousands separated by a no-break space, as in the canvas, e.g. `3 021`.
String formatGrouped(int value) => value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => '\u00A0');

/// Whole numbers like watts or strokes per minute; a dash when unknown.
String formatWhole(int? value) => value?.toString() ?? _noValue;

/// An RR interval in whole milliseconds, e.g. "812 ms".
String formatRrInterval(int milliseconds) => '$milliseconds ms';

/// Average stroke rate with one decimal, e.g. `22,5` in German, `22.5` in English.
String formatStrokeRate(AppLocalizations l10n, double? strokeRate) =>
    strokeRate == null ? _noValue : NumberFormat('0.0', l10n.localeName).format(strokeRate);

/// A drive length in whole centimeters, e.g. `106 cm`;
/// null without a length or for 0, so that nothing is shown instead of "0 cm".
String? formatDriveLength(AppLocalizations l10n, double? meters) =>
    meters == null || meters <= 0 ? null : '${NumberFormat('0', l10n.localeName).format(meters * 100)} cm';

/// Local date and time, e.g. `15.10.2026, 18:30` in German, `Oct 15, 2026, 18:30` in English.
String formatDateTime(AppLocalizations l10n, DateTime time) =>
    DateFormat(l10n.dateTimePattern, l10n.localeName).format(time.toLocal());

String _two(int value) => value.toString().padLeft(2, '0');
