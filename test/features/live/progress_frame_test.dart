import 'package:strokesplit/app/design_tokens.dart';
import 'package:strokesplit/data/courses/lap_tracker.dart';
import 'package:strokesplit/data/courses/zone_intensity.dart';
import 'package:strokesplit/features/live/progress_frame.dart';
import 'package:strokesplit/features/live/progress_frame_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// All tracks filled to [share], with the notches of three laps on a course
/// whose zone runs from 200 to 800 m of 1000 m.
ProgressFrameModel _filled(double share, {bool openLaps = false}) =>
    ProgressFrameModel(
      course: openLaps
          ? null
          : FrameTrack(share: share, boundaries: const [1 / 3, 2 / 3]),
      lap: FrameTrack(
        share: share,
        boundaries: const [0.2, 0.8],
        zones: const [(0.2, 0.8, ZoneIntensity.medium)],
      ),
      segment: FrameTrack(
        share: share,
        boundaries: const [],
        zones: const [(0.0, 1.0, ZoneIntensity.medium)],
      ),
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
  await tester.pumpWidget(
    Center(
      child: RepaintBoundary(
        key: _frame,
        child: ColoredBox(
          color: AppColors.bg,
          // Room for the boats and a ghost moved out of the outer track, which stick out of the box.
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(width: 350, height: 380, child: frame),
          ),
        ),
      ),
    ),
  );
}

void main() {
  // 46 % lies on the bottom edge and 38 % in the bottom right corner of every track.
  for (final percent in [0, 46, 38, 100]) {
    for (final openLaps in [false, true]) {
      final name = 'progress_frame_$percent${openLaps ? '_open' : ''}';
      testWidgets(
        'paints $percent %${openLaps ? ' without the course track' : ''}',
        (tester) async {
          await _pump(
            tester,
            ProgressFrame(
              model: _filled(percent / 100, openLaps: openLaps),
              pace: BandStatus.inBand,
            ),
          );

          await expectLater(
            find.byKey(_frame),
            matchesGoldenFile('goldens/$name.png'),
          );
        },
      );
    }
  }

  testWidgets(
    'paints half of a time limit on the course track without notches',
    (tester) async {
      final model = _filled(0.46);
      await _pump(
        tester,
        ProgressFrame(
          model: ProgressFrameModel(
            course: const FrameTrack(share: 0.5, boundaries: []),
            lap: model.lap,
            segment: model.segment,
            courseDone: null,
            courseLength: null,
            lapRemaining: model.lapRemaining,
            segmentRemaining: model.segmentRemaining,
            timeRemaining: const Duration(minutes: 15),
          ),
          pace: BandStatus.inBand,
        ),
      );

      await expectLater(
        find.byKey(_frame),
        matchesGoldenFile('goldens/progress_frame_time_limit.png'),
      );
    },
  );

  testWidgets(
    'paints the ghosts beside the boats and the pace out of the zone',
    (tester) async {
      await _pump(
        tester,
        ProgressFrame(
          model: _filled(0.46),
          pace: BandStatus.above,
          ghost: const FrameGhost(course: 0.48, lap: 0.47, segment: 0.5),
        ),
      );

      await expectLater(
        find.byKey(_frame),
        matchesGoldenFile('goldens/progress_frame_ghost.png'),
      );
    },
  );

  // Where the ghost would cover the rower's boat, it moves out across its track (ghost, Design D5).
  for (final (name, ghost, share) in [
    ('lap', const FrameGhost(lap: 0.465), 0.46),
    ('course', const FrameGhost(course: 0.462), 0.46),
    ('corner', const FrameGhost(segment: 0.372), 0.38),
    ('clear', const FrameGhost(lap: 0.478), 0.46),
  ]) {
    testWidgets('places the ghost near the boat: $name', (tester) async {
      await _pump(
        tester,
        ProgressFrame(
          model: _filled(share),
          pace: BandStatus.inBand,
          ghost: ghost,
        ),
      );

      await expectLater(
        find.byKey(_frame),
        matchesGoldenFile('goldens/progress_frame_ghost_$name.png'),
      );
    });
  }

  // Every zone in the colour of its hardness, here an easy, a medium and a hard zone and,
  // on the segment track, a zone with only a level that fills in its hardness (live-zone-targets, D2/D3).
  testWidgets('paints the zones in the colours of their hardness', (
    tester,
  ) async {
    const zones = [
      (0.1, 0.3, ZoneIntensity.easy),
      (0.4, 0.6, ZoneIntensity.medium),
      (0.7, 0.9, ZoneIntensity.hard),
    ];
    await _pump(
      tester,
      ProgressFrame(
        model: ProgressFrameModel(
          course: const FrameTrack(
            share: 0.55,
            boundaries: [0.5],
            zones: [
              (0.05, 0.15, ZoneIntensity.easy),
              (0.2, 0.3, ZoneIntensity.medium),
              (0.35, 0.45, ZoneIntensity.hard),
              (0.55, 0.65, ZoneIntensity.easy),
              (0.7, 0.8, ZoneIntensity.medium),
              (0.85, 0.95, ZoneIntensity.hard),
            ],
          ),
          lap: const FrameTrack(
            share: 0.65,
            boundaries: [0.1, 0.3, 0.4, 0.6, 0.7, 0.9],
            zones: zones,
          ),
          segment: const FrameTrack(
            share: 0.5,
            boundaries: [],
            zones: [(0.0, 1.0, ZoneIntensity.hard)],
          ),
          courseDone: 1100,
          courseLength: 2000,
          lapRemaining: 350,
          segmentRemaining: 100,
        ),
        pace: BandStatus.none,
      ),
    );

    await expectLater(
      find.byKey(_frame),
      matchesGoldenFile('goldens/progress_frame_intensity.png'),
    );
  });

  test('fills the segment track in the zone status, or the hardness of a zone without a pace band', () {
    const hard = FrameTrack(
      share: 0.5,
      boundaries: [],
      zones: [(0.0, 1.0, ZoneIntensity.hard)],
    );
    const free = FrameTrack(share: 0.5, boundaries: []);
    expect(
      ProgressFramePainter.segmentFill(hard, BandStatus.inBand),
      AppColors.zoneIn,
    );
    expect(
      ProgressFramePainter.segmentFill(hard, BandStatus.above),
      AppColors.zoneOut,
    );
    expect(
      ProgressFramePainter.segmentFill(hard, BandStatus.none),
      AppColors.intensityHard,
    );
    expect(
      ProgressFramePainter.segmentFill(free, BandStatus.none),
      AppColors.textMuted,
    );
  });

  test('colours the segment track by the zone status of the pace', () {
    expect(
      ProgressFramePainter.segmentColor(BandStatus.inBand),
      AppColors.zoneIn,
    );
    expect(
      ProgressFramePainter.segmentColor(BandStatus.above),
      AppColors.zoneOut,
    );
    expect(
      ProgressFramePainter.segmentColor(BandStatus.below),
      AppColors.zoneOut,
    );
    expect(
      ProgressFramePainter.segmentColor(BandStatus.none),
      AppColors.textMuted,
    );
    expect(ProgressFramePainter.segmentColor(null), AppColors.textMuted);
  });

  test('tints the box like the stroke rate card in a band and leaves it plain in a free gap', () {
    expect(
      ProgressFramePainter.boxColor(BandStatus.inBand),
      AppColors.zoneInSurface,
    );
    expect(
      ProgressFramePainter.boxColor(BandStatus.above),
      AppColors.zoneOutSurface,
    );
    expect(
      ProgressFramePainter.boxColor(BandStatus.below),
      AppColors.zoneOutSurface,
    );
    expect(
      ProgressFramePainter.boxColor(BandStatus.missing),
      AppColors.zoneOutSurface,
    );
    expect(ProgressFramePainter.boxColor(BandStatus.none), AppColors.surface);
    expect(ProgressFramePainter.boxColor(null), AppColors.surface);
  });

  testWidgets('keeps the child inside the tracks', (tester) async {
    await _pump(
      tester,
      ProgressFrame(
        model: _filled(0.46),
        child: const SizedBox.expand(key: Key('inside')),
      ),
    );

    final frame = tester.getRect(find.byType(ProgressFrame));
    final inside = tester.getRect(find.byKey(const Key('inside')));
    final width = ProgressFramePainter.frameWidth(3);
    expect(inside.left - frame.left, greaterThan(width));
    expect(frame.bottom - inside.bottom, greaterThan(width));
  });
}
