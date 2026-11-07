import 'package:strokesplit/app/platform_providers.dart';
import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/sessions/first_stroke.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/sources/erg_source_providers.dart';
import 'package:strokesplit/data/workouts/workout.dart';
import 'package:strokesplit/data/workouts/workout_repository.dart';
import 'package:strokesplit/features/live/live_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/fake_erg_source.dart';
import '../../support/fixtures.dart';
import '../../support/localized_app.dart';
import '../../support/test_database.dart';

import 'package:strokesplit/data/sessions/session_plan.dart';

class _Fixed extends ActiveErgSource {
  _Fixed(this.source);

  final ErgSource source;

  @override
  ErgSource? build() => source;
}

/// The live display of a workout rowed on a PM5 that plays `pause`
/// (Change auto-pause).
class _Harness {
  final db = openTestDatabase();
  final source = FakeErgSource()
    ..connectionState = ErgConnectionState.connected;
  final packets = loadFixture('pause').packets;

  /// The packet with the first stroke.
  late final int trigger = () {
    final detector = FirstStrokeDetector(ErgProtocol.pm5);
    return packets.indexWhere((p) => detector.add(p) != null);
  }();

  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('de'),
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final workout = (await tester.runAsync(() async {
      final course = await CourseRepository(db).create(
        'Seerunde',
        CourseDefinition.single(axis: CourseAxis.distance, length: 5000),
      );
      final workouts = WorkoutRepository(db);
      return workouts.get(
        await workouts.create(
          'Seerunde x3',
          courseIds: [course],
          length: const LapCount(3),
        ),
      );
    }))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          activeErgSourceProvider.overrideWith(() => _Fixed(source)),
          wakelockProvider.overrideWithValue(FakeWakelock()),
        ],
        child: LocalizedApp(locale: locale, home: _Home(workout)),
      ),
    );
    await tester.tap(find.text('Los'));
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(LiveScreen)),
    );
  }

  /// Sends [packets] and lets the recorder store what it needs to.
  Future<void> emit(WidgetTester tester, Iterable<RawPacket> packets) async {
    await tester.runAsync(() async {
      packets.forEach(source.emit);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
  }

  Future<void> end(WidgetTester tester) async {
    await tester.runAsync(
      () => container.read(sessionRecorderProvider.notifier).stop(),
    );
    await disposeWidgetsWithDatabase(tester);
  }
}

class _Home extends StatelessWidget {
  const _Home(this.workout);

  final Workout workout;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LiveScreen(plan: workout.toPlan()),
        ),
      ),
      child: const Text('Los'),
    ),
  );
}

/// The packets that arrived before [ms] on the clock of the recording.
bool _before(RawPacket p, int ms) => p.time.inMilliseconds < ms;

void main() {
  // The rower stops after the stroke at 101.3 s and rows again from 188.3 s.
  testWidgets(
    'shows the pause while the rower sits still, until the next stroke',
    (tester) async {
      final harness = _Harness();
      await harness.pump(tester);
      await harness.emit(
        tester,
        harness.packets.where((p) => _before(p, 100000)),
      );
      expect(
        find.byKey(const Key('pause-hint')),
        findsNothing,
        reason: 'rowing',
      );
      expect(harness.container.read(sessionRecorderProvider)!.paused, isFalse);

      await harness.emit(
        tester,
        harness.packets.where((p) => !_before(p, 100000) && _before(p, 120000)),
      );
      expect(find.text('Pause'), findsOneWidget);
      final paused = harness.container.read(sessionRecorderProvider)!;
      expect(paused.paused, isTrue);

      await harness.emit(
        tester,
        harness.packets.where((p) => !_before(p, 120000) && _before(p, 180000)),
      );
      expect(find.text('Pause'), findsOneWidget);
      final still = harness.container.read(sessionRecorderProvider)!;
      expect(
        still.progress.elapsed,
        paused.progress.elapsed,
        reason: 'the session time stands still',
      );
      expect(still.lap!.lapTime, paused.lap!.lapTime);

      await harness.emit(
        tester,
        harness.packets.where((p) => !_before(p, 180000) && _before(p, 192000)),
      );
      expect(find.byKey(const Key('pause-hint')), findsNothing);
      final rowing = harness.container.read(sessionRecorderProvider)!;
      expect(rowing.paused, isFalse);
      expect(rowing.progress.elapsed, greaterThan(still.progress.elapsed));

      await harness.end(tester);
    },
  );

  testWidgets('says it in English', (tester) async {
    final harness = _Harness();
    await harness.pump(tester, locale: const Locale('en'));
    await harness.emit(
      tester,
      harness.packets.where((p) => _before(p, 100000)),
    );
    await harness.emit(
      tester,
      harness.packets.where((p) => !_before(p, 100000) && _before(p, 120000)),
    );

    expect(find.text('Paused'), findsOneWidget);
    await harness.end(tester);
  });
}
