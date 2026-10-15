/// Display formats as rowers know them from the PM5.
library;

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

/// Distance in whole meters, e.g. `1234`.
String formatDistance(double meters) => meters.floor().toString();

/// Whole numbers like watts or strokes per minute; a dash when unknown.
String formatWhole(int? value) => value?.toString() ?? _noValue;

/// Average stroke rate with one decimal, e.g. `22.5`.
String formatStrokeRate(double? strokeRate) => strokeRate?.toStringAsFixed(1) ?? _noValue;

/// Local date and time, e.g. `15.10.2026, 18:30`.
String formatDateTime(DateTime time) {
  final t = time.toLocal();
  return '${_two(t.day)}.${_two(t.month)}.${t.year}, ${_two(t.hour)}:${_two(t.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
