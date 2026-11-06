import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:strokesplit/app/app_language.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/health/health_export.dart';
import 'package:strokesplit/data/health/health_platform.dart';
import 'package:strokesplit/data/health/health_workout.dart';
import 'package:strokesplit/data/sessions/session_accumulator.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/sources/erg_source_providers.dart';

import '../../support/fake_erg_source.dart';
import '../../support/fake_health_platform.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

class _Fixed extends ActiveErgSource {
  _Fixed(this.source);

  final ErgSource source;

  @override
  ErgSource? build() => source;
}

class _Setup {
  _Setup({bool enabled = true, bool available = true, ErgSource? source})
    : store = MemoryHealthExportStore(enabled) {
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        healthPlatformProvider.overrideWithValue(health),
        healthExportStoreProvider.overrideWithValue(store),
        healthExportAvailableProvider.overrideWithValue(available),
        if (source != null)
          activeErgSourceProvider.overrideWith(() => _Fixed(source)),
        recordingFlushIntervalProvider.overrideWithValue(
          const Duration(milliseconds: 10),
        ),
      ],
    );
    addTearDown(container.dispose);
  }

  final db = openTestDatabase();
  final health = FakeHealthPlatform(granted: HealthKind.values.toSet());
  final MemoryHealthExportStore store;
  late final ProviderContainer container;

  HealthExporter get exporter => container.read(healthExporterProvider);

  /// A stored session of 2 000 m from [source], without a template.
  Future<int> session({ErgSourceKind source = ErgSourceKind.pm5}) async {
    final repository = container.read(sessionRepositoryProvider);
    final id = await repository.create(
      startedAt: DateTime.utc(2026, 11, 2, 18),
      source: source,
    );
    await repository.write(
      SessionBatch(
        samples: [
          SamplesCompanion.insert(
            sessionId: id,
            tMs: 1000,
            distanceDm: 40,
            wallMs: const Value(1000),
            watts: const Value(150),
            paceCs: const Value(12500),
          ),
        ],
        strokes: const [],
        rawPackets: const [],
      ),
    );
    await repository.finish(id, endedAt: DateTime.utc(2026, 11, 2, 18, 8));
    await (db.update(db.sessions)..where((s) => s.id.equals(id))).write(
      const SessionsCompanion(distanceDm: Value(20000)),
    );
    return id;
  }

  Future<DateTime?> exportedAt(int id) async => (await (db.select(
    db.sessions,
  )..where((s) => s.id.equals(id))).getSingle()).healthExportedAt;
}

void main() {
  test('writes a session and remembers when', () async {
    final setup = _Setup();
    final id = await setup.session();

    expect(await setup.exporter.export(id), isNull);

    final workout = setup.health.workouts.values.single;
    expect(workout.title, 'Freies Rudern');
    expect(workout.meters, 2000);
    expect(workout.start, DateTime.utc(2026, 11, 2, 18));
    expect(await setup.exportedAt(id), isNotNull);
  });

  test('names free rowing in the language of the app', () async {
    final setup = _Setup();
    await setup.container
        .read(appLanguageProvider.notifier)
        .choose(AppLanguage.en);

    await setup.exporter.export(await setup.session());

    expect(setup.health.workouts.values.single.title, 'Free rowing');
  });

  test('replaces an earlier write of the same session', () async {
    final setup = _Setup();
    final id = await setup.session();

    await setup.exporter.export(id);
    await setup.exporter.export(id);

    expect(setup.health.writes, 2);
    expect(setup.health.workouts, hasLength(1));
  });

  test(
    'a failed write leaves the session not written and gives the reason',
    () async {
      final setup = _Setup();
      final id = await setup.session();
      await setup.exporter.export(id);

      setup.health.failure = HealthFailure.failed;
      expect(await setup.exporter.export(id), HealthFailure.failed);

      expect(await setup.exportedAt(id), isNull);
    },
  );

  test('a missing permission is the reason', () async {
    final setup = _Setup();
    setup.health.granted = {};

    expect(
      await setup.exporter.export(await setup.session()),
      HealthFailure.permission,
    );
  });

  group('after a session ended', () {
    test('writes a session from a rower and reports nothing', () async {
      final setup = _Setup();
      final id = await setup.session(source: ErgSourceKind.ftms);

      await setup.exporter.sessionFinished(id);

      expect(setup.health.workouts, hasLength(1));
      expect(setup.container.read(healthExportFailureProvider), isNull);
    });

    for (final source in [ErgSourceKind.simulator, ErgSourceKind.replay]) {
      test('writes nothing from the ${source.name}', () async {
        final setup = _Setup();

        await setup.exporter.sessionFinished(
          await setup.session(source: source),
        );

        expect(setup.health.writes, 0);
      });
    }

    test('writes nothing while the export is off', () async {
      final setup = _Setup(enabled: false);

      await setup.exporter.sessionFinished(await setup.session());

      expect(setup.health.writes, 0);
    });

    test(
      'writes nothing without Health Connect, even when switched on before',
      () async {
        final setup = _Setup(available: false);

        await setup.exporter.sessionFinished(await setup.session());

        expect(setup.health.writes, 0);
      },
    );

    test('reports a failure', () async {
      final setup = _Setup();
      setup.health.failure = HealthFailure.unavailable;
      final id = await setup.session();

      await setup.exporter.sessionFinished(id);

      expect(setup.container.read(healthExportFailureProvider), (
        sessionId: id,
        reason: HealthFailure.unavailable,
      ));
      expect(await setup.exportedAt(id), isNull);
    });

    test('follows a stop of the recording', () async {
      final source = FakeErgSource(
        kind: ErgSourceKind.pm5,
        name: 'PM5',
        protocol: ErgProtocol.pm5,
      );
      final setup = _Setup(source: source);
      final recorder = setup.container.read(sessionRecorderProvider.notifier);

      await recorder.start();
      for (final packet in loadFixture('just_row').packets) {
        source.emit(packet);
      }
      await pumpEventQueue();
      final id = (await recorder.stop())!;
      await pumpEventQueue();

      expect(setup.health.workouts, hasLength(1));
      expect(await setup.exportedAt(id), isNotNull);
    });
  });

  group('setting', () {
    test('is off at first and switches on', () async {
      final setup = _Setup(enabled: false);
      expect(setup.container.read(healthExportEnabledProvider), isFalse);

      await setup.container
          .read(healthExportEnabledProvider.notifier)
          .set(true);

      expect(setup.container.read(healthExportEnabledProvider), isTrue);
      expect(setup.store.read(), isTrue);
    });

    test('outlasts opening the preferences again', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();

      expect((await PreferencesHealthExportStore.open()).read(), isFalse);
      await (await PreferencesHealthExportStore.open()).write(true);

      expect((await PreferencesHealthExportStore.open()).read(), isTrue);
    });
  });
}
