import 'package:aergrow/app/design_tokens.dart';
import 'package:aergrow/data/courses/lap_tracker.dart';
import 'package:aergrow/features/live/progress_frame.dart';
import 'package:aergrow/features/live/progress_frame_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// All tracks filled to [share], with the notches of three laps on a course
/// whose zone runs from 200 to 800 m of 1000 m.
ProgressFrameModel _filled(double share, {bool openLaps = false}) => ProgressFrameModel(
      course: openLaps ? null : FrameTrack(share: share, boundaries: const [1 / 3, 2 / 3]),
      lap: FrameTrack(share: share, boundaries: const [0.2, 0.8]),
      segment: FrameTrack(share: share, boundaries: const []),
      courseDone: openLaps ? null : share * 3000,
      courseLength: openLaps ? null : 3000,
      lapRemaining: 1000 - share * 1000,
      segmentRemaining: 600 - share * 600,
    );

const _frame = Key('frame');

/// The size of the pace box in the canvas screen "Live: Vorlage mit Zonen".
Future<void> _pump(WidgetTester tester, Widget frame) async {
  tester.view.physicalSize = const Size(400, 430);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(Center(
    child: RepaintBoundary(
      key: _frame,
      child: ColoredBox(
        color: AppColors.bg,
        // Room for the boats and a ghost moved out of the outer track, which stick out of the box.
        child: Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: 350, height: 380, child: frame)),
      ),
    ),
  ));
}

void main() {
  // 46 % lies on the bottom edge and 38 % in the bottom right corner of every track.
  for (final percent in [0, 46, 38, 100]) {
    for (final openLaps in [false, true]) {
      final name = 'progress_frame_$percent${openLaps ? '_open' : ''}';
      testWidgets('paints $percent %${openLaps ? ' without the course track' : ''}', (tester) async {
        await _pump(
          tester,
          ProgressFrame(model: _filled(percent / 100, openLaps: openLaps), pace: BandStatus.inBand),
        );

        await expectLater(find.byKey(_frame), matchesGoldenFile('goldens/$name.png'));
      });
    }
  }

  testWidgets('paints the ghosts beside the boats and the pace out of the zone', (tester) async {
    await _pump(
      tester,
      ProgressFrame(
        model: _filled(0.46),
        pace: BandStatus.above,
        ghost: const FrameGhost(course: 0.48, lap: 0.47, segment: 0.5),
      ),
    );

    await expectLater(find.byKey(_frame), matchesGoldenFile('goldens/progress_frame_ghost.png'));
  });

  // Where the ghost would cover the rower's boat, it moves out across its track (ghost, Design D5).
  for (final (name, ghost, share) in [
    ('lap', const FrameGhost(lap: 0.465), 0.46),
    ('course', const FrameGhost(course: 0.462), 0.46),
    ('corner', const FrameGhost(segment: 0.372), 0.38),
    ('clear', const FrameGhost(lap: 0.478), 0.46),
  ]) {
    testWidgets('places the ghost near the boat: $name', (tester) async {
      await _pump(tester, ProgressFrame(model: _filled(share), pace: BandStatus.inBand, ghost: ghost));

      await expectLater(find.byKey(_frame), matchesGoldenFile('goldens/progress_frame_ghost_$name.png'));
    });
  }

  test('colours the segment track by the zone status of the pace', () {
    expect(ProgressFramePainter.segmentColor(BandStatus.inBand), AppColors.zoneIn);
    expect(ProgressFramePainter.segmentColor(BandStatus.above), AppColors.zoneOut);
    expect(ProgressFramePainter.segmentColor(BandStatus.below), AppColors.zoneOut);
    expect(ProgressFramePainter.segmentColor(BandStatus.none), AppColors.textMuted);
    expect(ProgressFramePainter.segmentColor(null), AppColors.textMuted);
  });

  testWidgets('keeps the child inside the tracks', (tester) async {
    await _pump(tester, ProgressFrame(model: _filled(0.46), child: const SizedBox.expand(key: Key('inside'))));

    final frame = tester.getRect(find.byType(ProgressFrame));
    final inside = tester.getRect(find.byKey(const Key('inside')));
    final width = ProgressFramePainter.frameWidth(3);
    expect(inside.left - frame.left, greaterThan(width));
    expect(frame.bottom - inside.bottom, greaterThan(width));
  });
}
