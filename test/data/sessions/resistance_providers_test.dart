import 'package:erg_protocol/erg_protocol.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strokesplit/data/courses/course_layout.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sessions/resistance_providers.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/sources/erg_source_providers.dart';
import 'package:strokesplit/data/sources/resistance_control.dart';
import 'package:strokesplit/data/sources/simulated_source.dart';
import 'package:strokesplit/data/templates/session_template.dart';
import 'package:strokesplit/data/templates/template_repository.dart';
import 'package:strokesplit/data/zones/zone.dart';
import 'package:strokesplit/data/zones/zone_repository.dart';

import '../../support/fake_erg_source.dart';
import '../../support/test_database.dart';

class _Fixed extends ActiveErgSource {
  _Fixed(this.source);

  final ErgSource source;

  @override
  ErgSource? build() => source;
}

/// Refuses every level and counts the attempts.
class _Refusing implements ResistanceControl {
  final levels = <int>[];

  @override
  ResistanceRange get range => const ResistanceRange(min: 1, max: 15);

  @override
  Future<ResistanceResult> setLevel(int level) async {
    levels.add(level);
    return ResistanceResult.rejected;
  }
}

T _run<T>(FakeAsync async, Future<T> Function() body) {
  late T result;
  body().then((value) => result = value);
  async.flushMicrotasks();
  return result;
}

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());

  ProviderContainer container(ErgSource source) {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        activeErgSourceProvider.overrideWith(() => _Fixed(source)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(resistanceProvider, (_, _) {});
    return container;
  }

  /// 100 m free, then a 100 m sprint on level 10, once.
  Future<SessionTemplate> sprintTemplate() async {
    final zoneId = await ZoneRepository(db).create(
      const Zone(
        name: 'Sprint',
        axis: CourseAxis.distance,
        length: 100,
        spmMin: 20,
        spmMax: 34,
        resistanceLevel: 10,
      ),
    );
    final zone = (await ZoneRepository(db).get(zoneId))!;
    final layout = resolveCourse(
      axis: CourseAxis.distance,
      length: 200,
      placements: [ZonePlacement(zoneId: zoneId, start: 100)],
      zones: {zoneId: zone},
    );
    final course = await CourseRepository(db)
        .create('Sprint', layout.definition!);
    final templates = TemplateRepository(db);
    return (await templates.get(
      await templates.create('Sprint', courseId: course, laps: 1),
    ))!;
  }

  test(
    'the simulator rows the sprint on level 10 and back on the base level',
    () {
      fakeAsync((async) {
        final source = SimulatedSource(seed: 1, protocol: ErgProtocol.ftms);
        final c = container(source);
        final template = _run(async, sprintTemplate);
        _run(async, () async {
          await source.start();
          await c
              .read(sessionRecorderProvider.notifier)
              .start(template: template);
        });
        async.elapse(const Duration(seconds: 3));
        expect(
          c.read(resistanceProvider).range,
          const ResistanceRange(min: 1, max: 15),
        );
        expect(source.resistanceLevel, SimulatedSource.ftmsResistanceLevel);

        // 100 m at 2:10 /500 m take 26 s.
        async.elapse(const Duration(seconds: 30));
        expect(
          c.read(sessionRecorderProvider)!.lap!.segment.resistanceLevel,
          10,
        );
        expect(source.resistanceLevel, 10);
        async.elapse(const Duration(seconds: 2));
        expect(c.read(resistanceProvider).level, 10);
        source.stop();
      });
    },
  );

  test('+ raises the level of the simulator while rowing freely', () {
    fakeAsync((async) {
      final source = SimulatedSource(seed: 1, protocol: ErgProtocol.ftms);
      final c = container(source);
      _run(async, source.start);
      async.elapse(const Duration(seconds: 2));

      c.read(resistanceProvider.notifier).step(1);
      c.read(resistanceProvider.notifier).step(1);
      async.elapse(const Duration(seconds: 2));

      expect(source.resistanceLevel, 7);
      expect(
        (c.read(resistanceProvider).level, c.read(resistanceProvider).target),
        (7, 7),
      );
      source.stop();
    });
  });

  test('a PM5 offers no level', () {
    fakeAsync((async) {
      final source = SimulatedSource(seed: 1);
      final c = container(source);
      _run(async, source.start);
      async.elapse(const Duration(seconds: 2));

      expect(c.read(resistanceProvider).canSet, isFalse);
      expect(c.read(resistanceProvider).level, isNull);
      source.stop();
    });
  });

  test('a refusal shows for a moment and is not repeated', () {
    fakeAsync((async) {
      final control = _Refusing();
      final source = FakeErgSource(
        kind: ErgSourceKind.ftms,
        protocol: ErgProtocol.ftms,
      )..resistanceControl = control;
      final c = container(source);
      _run(async, source.start);
      source.emit(
        const FtmsEncoder().encodeStatus(
          const StatusTick(
            elapsed: Duration(seconds: 1),
            distanceMeters: 5,
            workoutType: WorkoutType.justRowSplits,
            workoutState: WorkoutState.workoutRow,
            isRowing: true,
            pace: Duration(minutes: 2),
            resistanceLevel: 6,
          ),
          strokeCount: 1,
          at: const Duration(seconds: 1),
        ),
      );
      async.flushMicrotasks();
      expect(c.read(resistanceProvider).target, 6);

      c.read(resistanceProvider.notifier).step(1);
      async.flushMicrotasks();

      expect(control.levels, [7]);
      expect(
        (c.read(resistanceProvider).refused, c.read(resistanceProvider).target),
        (true, 6),
      );
      async.elapse(const Duration(seconds: 3));
      expect(c.read(resistanceProvider).refused, isFalse);
      expect(control.levels, [7]);
    });
  });
}
