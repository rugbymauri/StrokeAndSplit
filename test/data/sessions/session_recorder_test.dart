import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm5_protocol/pm5_protocol.dart';

import '../../support/fake_erg_source.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

class _Fixed extends ActiveErgSource {
  _Fixed(this.source);

  final ErgSource source;

  @override
  ErgSource? build() => source;
}

class _Setup {
  _Setup({ErgSourceKind kind = ErgSourceKind.pm5}) : source = FakeErgSource(kind: kind, name: 'PM5 430000001 Row') {
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      activeErgSourceProvider.overrideWith(() => _Fixed(source)),
      recordingFlushIntervalProvider.overrideWithValue(const Duration(milliseconds: 10)),
    ]);
    addTearDown(container.dispose);
  }

  final db = openTestDatabase();
  final FakeErgSource source;
  late final ProviderContainer container;

  SessionRecorder get recorder => container.read(sessionRecorderProvider.notifier);

  Future<void> emitAll(Iterable<RawPacket> packets) async {
    for (final p in packets) {
      source.emit(p);
    }
    await pumpEventQueue();
  }

  Future<SessionRow> session(int id) => (db.select(db.sessions)..where((s) => s.id.equals(id))).getSingle();
}

void main() {
  test('summarises a recorded session', () async {
    final setup = _Setup();
    final packets = loadFixture('just_row').packets;
    final ticks = decodeTicks(packets);

    await setup.recorder.start();
    await setup.emitAll(packets);
    final id = (await setup.recorder.stop())!;
    final session = await setup.session(id);

    final distance = ticks.last.distanceMeters - ticks.first.distanceMeters;
    final duration = ticks.last.elapsed - ticks.first.elapsed;
    expect(session.status, SessionStatus.complete);
    expect(session.source, ErgSourceKind.pm5);
    expect(session.deviceName, 'PM5 430000001 Row');
    expect(session.endedAt, isNotNull);
    expect(session.distanceDm, (distance * 10).round());
    expect(session.durationMs, duration.inMilliseconds);
    expect(session.averagePaceCs, (duration.inMilliseconds / 10 * 500 / distance).round());
    expect(session.strokeCount, greaterThan(0));
    expect(session.averageStrokeRate, closeTo(session.strokeCount * 60000 / session.durationMs, 0.001));
    expect(session.averageWatts, isNotNull);
    expect(await setup.db.select(setup.db.rawPackets).get(), hasLength(packets.length));
    expect(setup.container.read(sessionRecorderProvider), isNull);
  });

  test('counts from zero although the PM5 already shows distance', () async {
    final setup = _Setup();
    final packets = loadFixture('just_row').packets;
    final ticks = decodeTicks(packets);
    final half = packets.length ~/ 2;
    final pm5AtStart = decodeTicks(packets.take(half)).last.distanceMeters;
    expect(pm5AtStart, greaterThan(50), reason: 'the fixture is rowed in its first half');

    await setup.recorder.start();
    await setup.emitAll(packets.skip(half));
    final id = (await setup.recorder.stop())!;
    final first = (await setup.db.select(setup.db.samples).get()).first;

    expect(first.tMs, 0);
    expect(first.distanceDm, 0);
    expect((await setup.session(id)).distanceDm, closeTo((ticks.last.distanceMeters - pm5AtStart) * 10, 30));
  });

  test('keeps counting when the PM5 is reset during the session', () async {
    final setup = _Setup();
    final packets = loadFixture('reset').packets;
    // The PM5 still shows 583 m of an earlier workout at the start, then the
    // user rows three short pieces, each after a reset to 0 m.
    final ticks = decodeTicks(packets);
    var rowed = 0.0;
    var pieceStart = ticks.first.distanceMeters;
    var previous = pieceStart;
    for (final tick in ticks) {
      if (tick.distanceMeters < previous) {
        rowed += previous - pieceStart;
        pieceStart = 0;
      }
      previous = tick.distanceMeters;
    }
    rowed += previous - pieceStart;
    expect(rowed, greaterThan(150));

    await setup.recorder.start();
    await setup.emitAll(packets);
    final id = (await setup.recorder.stop())!;

    final distances = [for (final s in await setup.db.select(setup.db.samples).get()) s.distanceDm];
    for (var i = 1; i < distances.length; i++) {
      expect(distances[i], greaterThanOrEqualTo(distances[i - 1]), reason: 'sample $i');
    }
    expect((await setup.session(id)).distanceDm, (rowed * 10).round());
  });

  test('shows the progress of the running session', () async {
    final setup = _Setup();
    final packets = loadFixture('just_row').packets;

    await setup.recorder.start();
    await setup.emitAll(packets);

    final progress = setup.container.read(sessionRecorderProvider)!.progress;
    expect(progress.distanceMeters, greaterThan(0));
    expect(progress.elapsed, greaterThan(Duration.zero));
  });

  test('writes the rows while recording, not only at the end', () async {
    final setup = _Setup();

    await setup.recorder.start();
    await setup.emitAll(loadFixture('just_row').packets);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(await setup.db.select(setup.db.samples).get(), isNotEmpty);
    expect((await setup.db.select(setup.db.sessions).getSingle()).status, SessionStatus.recording);
  });
}
