import 'package:erg_protocol/erg_protocol.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  final recording = loadFixture('just_row');
  final strokes = decodeAll(recording.packets).whereType<Stroke>().toList();

  test('emits exactly one stroke per stroke number', () {
    final strokeNumbers = recording.packets
        .where((p) => p.characteristicId == Pm5Characteristics.strokeData)
        .map((p) => p.bytes[18] | p.bytes[19] << 8)
        .toSet();

    expect(
      strokes.map((s) => s.strokeNumber),
      orderedEquals(strokeNumbers.toList()..sort()),
    );
  });

  test('numbers strokes consecutively', () {
    for (final (i, stroke) in strokes.indexed.skip(1)) {
      expect(stroke.strokeNumber, strokes[i - 1].strokeNumber + 1);
    }
  });

  test('completes a stroke with the recovery time sent after the recovery', () {
    final stroke = strokes.firstWhere((s) => s.strokeNumber == 7);

    expect(stroke.elapsed, const Duration(milliseconds: 13540));
    expect(stroke.driveLengthMeters, 0.68);
    expect(stroke.driveTime, const Duration(milliseconds: 750));
    // The opening notification of stroke 7 still carried 1.45 s.
    expect(stroke.recoveryTime, const Duration(milliseconds: 1320));
    expect(stroke.peakForceNewtons, closeTo(38.8 * 4.44822, 0.01));
    expect(stroke.averageForceNewtons, closeTo(25.4 * 4.44822, 0.01));
    expect(stroke.watts, 34);
  });

  test('emits a stroke without closing notification once the rower stops', () {
    const encoder = Pm5Encoder();
    const stroke = Stroke(
      elapsed: Duration(seconds: 10),
      strokeNumber: 5,
      distanceMeters: 40,
      driveLengthMeters: 1.2,
      driveTime: Duration(milliseconds: 800),
      recoveryTime: Duration(milliseconds: 1500),
      peakForceNewtons: 500,
      averageForceNewtons: 300,
    );
    const idle = StatusTick(
      elapsed: Duration(seconds: 11),
      distanceMeters: 44,
      workoutType: WorkoutType.justRowSplits,
      workoutState: WorkoutState.workoutRow,
      isRowing: false,
    );
    final decoder = Pm5Decoder();

    final atDriveEnd = [
      for (final p in encoder.encodeDriveEnd(stroke, at: Duration.zero))
        ...decoder.decode(p),
    ];
    final atStop = [
      for (final p in encoder.encodeStatus(idle, at: Duration.zero))
        ...decoder.decode(p),
    ];
    final lateClosing = decoder.decode(
      encoder.encodeRecoveryEnd(stroke, at: Duration.zero),
    );

    expect(atDriveEnd, isEmpty);
    expect(atStop.whereType<Stroke>().single.strokeNumber, 5);
    expect(lateClosing, isEmpty);
  });
}
