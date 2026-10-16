import 'package:aergrow/data/courses/course.dart';
import 'package:aergrow/data/courses/course_repository.dart';
import 'package:aergrow/data/db/database.dart';
import 'package:aergrow/data/sessions/first_stroke.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/data/sources/replay_source.dart';
import 'package:aergrow/data/templates/session_template.dart';
import 'package:aergrow/data/templates/template_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../../support/fake_erg_source.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

class _Fixed extends ActiveErgSource {
  _Fixed(this.source);

  final ErgSource source;

  @override
  ErgSource? build() => source;
}

/// A template session with [source] (start-on-first-stroke).
class _Setup {
  _Setup(this.db, this.source) {
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      activeErgSourceProvider.overrideWith(() => _Fixed(source)),
      recordingFlushIntervalProvider.overrideWithValue(const Duration(milliseconds: 10)),
    ]);
    addTearDown(container.dispose);
  }

  final AppDatabase db;
  final ErgSource source;
  late final ProviderContainer container;

  SessionRecorder get recorder => container.read(sessionRecorderProvider.notifier);
  ActiveRecording? get recording => container.read(sessionRecorderProvider);

  Future<void> emitAll(Iterable<RawPacket> packets) async {
    for (final p in packets) {
      (source as FakeErgSource).emit(p);
    }
    await pumpEventQueue();
  }
}

/// An open 10 km course, long enough for every fixture.
Future<SessionTemplate> _template(AppDatabase db) async {
  final course =
      await CourseRepository(db).create('Lang', CourseDefinition.single(axis: CourseAxis.distance, length: 10000));
  final templates = TemplateRepository(db);
  return (await templates.get(await templates.create('Lang', courseId: course, laps: null)))!;
}

/// The index of the first packet a session gets from [packets] and of the first movement.
(int, int) _start(List<RawPacket> packets, ErgProtocol protocol) {
  final detector = FirstStrokeDetector(protocol);
  for (final (i, p) in packets.indexed) {
    final early = detector.add(p);
    if (early != null) return (i + 1 - early.length, i);
  }
  throw StateError('No stroke');
}

void main() {
  for (final (fixture, protocol, kind) in const [
    ('just_row', ErgProtocol.pm5, ErgSourceKind.pm5),
    ('ftms_just_row', ErgProtocol.ftms, ErgSourceKind.ftms),
  ]) {
    test('$fixture: is ready until the first stroke, then counts from the last status before it', () async {
      final db = openTestDatabase();
      final setup = _Setup(db, FakeErgSource(kind: kind, protocol: protocol));
      final template = await _template(db);
      final packets = loadFixture(fixture).packets;
      final (first, trigger) = _start(packets, protocol);
      final decoder = ErgDecoder.forProtocol(protocol);
      final ticks = [for (final p in packets) ...decoder.decode(p), ...decoder.flush()].whereType<StatusTick>();

      await setup.recorder.start(template: template);
      await setup.emitAll(packets.take(trigger));

      final ready = setup.recording!;
      expect((ready.ready, ready.sessionId, ready.template?.name), (true, null, 'Lang'));
      expect(ready.progress.elapsed, Duration.zero);
      expect((ready.lap!.lap, ready.lap!.courseTime, ready.lap!.courseDistanceDm), (1, Duration.zero, 0));
      expect(await db.select(db.sessions).get(), isEmpty, reason: 'nothing is stored before the first stroke');

      await setup.emitAll(packets.skip(trigger));
      expect(setup.recording!.ready, isFalse);
      expect(setup.recording!.progress.distanceMeters, greaterThan(0));
      final id = (await setup.recorder.stop())!;

      final session = (await db.select(db.sessions).get()).single;
      expect(session.id, id);
      final samples = await db.select(db.samples).get();
      expect((samples.first.tMs, samples.first.distanceDm), (0, 0));
      expect(samples.first.wallMs, lessThan(10), reason: 'the last of the packets of the base status');
      // The rower starts at 0 m and 0:00 itself, so the session has all of it.
      expect(session.distanceDm, (ticks.last.distanceMeters * 10).round());
      expect(session.durationMs, ticks.last.elapsed.inMilliseconds);
      final raw = await db.select(db.rawPackets).get();
      expect(raw, hasLength(packets.length - first), reason: 'raw packets from the base on');
      expect(raw.first.tMs, 0);
      final lap = (await db.select(db.laps).get()).single;
      expect((lap.startWallMs, lap.startDistanceDm), (0, 0));
    });
  }

  test('nothing is stored when ended before the first stroke', () async {
    final db = openTestDatabase();
    final setup = _Setup(db, FakeErgSource());
    final packets = loadFixture('just_row').packets;
    final (_, trigger) = _start(packets, ErgProtocol.pm5);

    await setup.recorder.start(template: await _template(db));
    await setup.emitAll(packets.take(trigger));
    expect(await setup.recorder.stop(), isNull);

    expect(setup.recording, isNull);
    await setup.emitAll(packets.skip(trigger));
    expect(setup.recording, isNull, reason: 'the stroke after ending starts nothing');
    expect(await db.select(db.sessions).get(), isEmpty);
    expect(await db.select(db.rawPackets).get(), isEmpty);
  });

  test('a free session still starts at once', () async {
    final db = openTestDatabase();
    final setup = _Setup(db, FakeErgSource());

    await setup.recorder.start();

    expect(setup.recording!.ready, isFalse);
    expect(await db.select(db.sessions).get(), hasLength(1));
  });

  test('ended in the packets that start it, the session is kept', () async {
    final db = openTestDatabase();
    final setup = _Setup(db, FakeErgSource());
    final packets = loadFixture('just_row').packets;
    final (_, trigger) = _start(packets, ErgProtocol.pm5);

    await setup.recorder.start(template: await _template(db));
    await setup.emitAll(packets.take(trigger));
    (setup.source as FakeErgSource).emit(packets[trigger]);
    // Delivered, but the session is still being created.
    await Future<void>.microtask(() {});
    expect(setup.recording!.ready, isTrue);
    final id = await setup.recorder.stop();

    expect(id, isNotNull);
    expect((await db.select(db.sessions).getSingle()).status, SessionStatus.complete);
  });

  test('import and replay give the same values as the recording', () async {
    final db = openTestDatabase();
    final setup = _Setup(db, FakeErgSource());
    final template = await _template(db);
    await setup.recorder.start(template: template);
    await setup.emitAll(loadFixture('just_row').packets);
    final id = (await setup.recorder.stop())!;
    final repository = setup.container.read(sessionRepositoryProvider);

    Future<List<(int, int, int?)>> samples(int session) async => [
          for (final s in await (db.select(db.samples)..where((s) => s.sessionId.equals(session))).get())
            (s.tMs, s.distanceDm, s.wallMs),
        ];
    Future<List<(int, int, int, bool)>> laps(int session) async => [
          for (final l in await (db.select(db.laps)..where((l) => l.sessionId.equals(session))).get())
            (l.startWallMs, l.startDistanceDm, l.endDistanceDm, l.complete),
        ];

    final imported = await repository.import(await repository.export(id));
    expect(await samples(imported), await samples(id));
    expect(await laps(imported), await laps(id));

    // Played back as a source, the template starts again with the first stroke.
    final replay = ReplaySource(await repository.rawRecording(id), speed: 200);
    final again = _Setup(db, replay);
    await replay.start();
    await again.recorder.start(template: template);
    expect(again.recording!.ready, isTrue);
    await Future<void>.delayed(const Duration(seconds: 1));
    final replayed = (await again.recorder.stop())!;
    // The replay plays faster, so only the rower's values are compared.
    final sameAxis = [for (final (t, d, _) in await samples(id)) (t, d)];
    expect([for (final (t, d, _) in await samples(replayed)) (t, d)], sameAxis);
  });
}
