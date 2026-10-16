import 'package:aergrow/data/sessions/first_stroke.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../../support/fixtures.dart';

/// Where [packets] start the session: the index of the first packet the
/// session gets and of the packet with the first movement; null without one.
(int, int)? _start(List<RawPacket> packets, ErgProtocol protocol) {
  final detector = FirstStrokeDetector(protocol);
  for (final (i, packet) in packets.indexed) {
    final early = detector.add(packet);
    if (early == null) continue;
    final first = i + 1 - early.length;
    expect(early, packets.sublist(first, i + 1), reason: 'the packets up to the first movement, in order');
    return (first, i);
  }
  return null;
}

List<RowingEvent> _decode(Iterable<RawPacket> packets, ErgProtocol protocol) {
  final decoder = ErgDecoder.forProtocol(protocol);
  return [for (final p in packets) ...decoder.decode(p)];
}

void main() {
  for (final (fixture, protocol) in const [
    ('just_row', ErgProtocol.pm5),
    ('force_curve', ErgProtocol.pm5),
    ('ftms_just_row', ErgProtocol.ftms),
  ]) {
    test('$fixture: starts from the last status before the first stroke', () {
      final packets = loadFixture(fixture).packets;
      final (first, trigger) = _start(packets, protocol)!;

      final before = _decode(packets.take(first), protocol);
      final idle = before.whereType<StatusTick>();
      expect(idle, isNotEmpty, reason: 'the rower is idle at first');
      expect(before.whereType<Stroke>(), isEmpty);
      expect(idle.every((t) => t.distanceMeters == 0 && t.elapsed == Duration.zero), isTrue);

      // The session gets the base status first: 0 m and 0:00, like the rower.
      final events = _decode(packets.sublist(first, trigger + 1), protocol);
      final base = events.whereType<StatusTick>().first;
      expect((base.distanceMeters, base.elapsed), (0, Duration.zero));
      // ... and the first movement.
      expect(events.any((e) => e is Stroke || e is StatusTick && e.distanceMeters > 0), isTrue);
    });
  }

  test('just_row: the stroke notification starts it before the first metre', () {
    final packets = loadFixture('just_row').packets;
    final (_, trigger) = _start(packets, ErgProtocol.pm5)!;

    final events = _decode(packets.take(trigger + 1), ErgProtocol.pm5);
    expect(events.whereType<Stroke>(), hasLength(1));
    expect(events.whereType<StatusTick>().every((t) => t.distanceMeters == 0), isTrue);
  });

  test('ftms_just_row: the first metres start it before the first stroke', () {
    final packets = loadFixture('ftms_just_row').packets;
    final (first, trigger) = _start(packets, ErgProtocol.ftms)!;

    // One record per second: the base is the record just before.
    expect(trigger - first, 1);
    expect(_decode(packets.take(trigger + 1), ErgProtocol.ftms).whereType<Stroke>(), isEmpty);
  });

  test('pause: the stroke rate of the paused piece does not start it, the next stroke does', () {
    final packets = loadFixture('pause').packets;
    final ticks = decodeTicks(packets);
    expect((ticks.first.strokeRate, ticks.first.isRowing), (28, false), reason: 'paused with the old rate');

    final (first, trigger) = _start(packets, ErgProtocol.pm5)!;

    final waited = decodeTicks(packets.take(first));
    expect(waited.length, greaterThan(10));
    expect(waited.every((t) => t.distanceMeters == ticks.first.distanceMeters), isTrue);
    final events = _decode(packets.sublist(first, trigger + 1), ErgProtocol.pm5);
    expect(events.whereType<StatusTick>().first.distanceMeters, ticks.first.distanceMeters);
  });

  test('reset: the reset rower becomes the base, not the earlier piece', () {
    final packets = loadFixture('reset').packets;
    expect(decodeTicks(packets).first.distanceMeters, greaterThan(500), reason: 'an earlier piece at first');

    final (first, trigger) = _start(packets, ErgProtocol.pm5)!;

    final base = _decode(packets.sublist(first, trigger + 1), ErgProtocol.pm5).whereType<StatusTick>().first;
    expect((base.distanceMeters, base.elapsed), (0, Duration.zero));
  });

  test('without a status before, the first status is the base', () {
    final packets = ftmsRowing(seconds: 5);

    final (first, trigger) = _start(packets, ErgProtocol.ftms)!;

    expect((first, trigger), (0, 1));
  });

  test('keeps waiting while nothing moves', () {
    final idle = loadFixture('ftms_just_row').packets.take(5).toList();

    expect(_start(idle, ErgProtocol.ftms), isNull);
  });
}
