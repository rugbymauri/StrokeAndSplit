import 'package:pm5_protocol/pm5_protocol.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

RawPacket _packet(String id, List<int> bytes) => RawPacket(time: Duration.zero, characteristicId: id, bytes: bytes);

void main() {
  test('decodes multiplexed notifications like the individual characteristics', () {
    final packets = loadFixture('just_row').packets;
    final multiplexed = [
      for (final p in packets)
        RawPacket(
          time: p.time,
          characteristicId: Pm5Characteristics.multiplexed,
          bytes: [int.parse(p.characteristicId, radix: 16), ...p.bytes],
        ),
    ];

    expect(
      decodeAll(multiplexed).map((e) => e.toString()),
      orderedEquals(decodeAll(packets).map((e) => e.toString())),
    );
  });

  final broken = {
    'too short status': _packet(Pm5Characteristics.generalStatus, [1, 2, 3]),
    'too short stroke data': _packet(Pm5Characteristics.strokeData, List.filled(19, 0)),
    'unknown characteristic': _packet('0099', List.filled(20, 0)),
    'empty multiplexed': _packet(Pm5Characteristics.multiplexed, []),
    'unknown multiplexed id': _packet(Pm5Characteristics.multiplexed, [0x3f, 1, 2]),
  };

  for (final MapEntry(key: name, value: packet) in broken.entries) {
    test('drops and reports a packet with $name', () {
      final warnings = <String>[];
      final decoder = Pm5Decoder(onWarning: warnings.add);

      expect(decoder.decode(packet), isEmpty);
      expect(warnings, hasLength(1));
    });
  }

  test('keeps decoding after a broken packet', () {
    final packets = loadFixture('just_row').packets;
    final withNoise = [
      for (final (i, p) in packets.indexed) ...[
        if (i % 50 == 0) _packet(Pm5Characteristics.generalStatus, [0xff]),
        p,
      ],
    ];
    final warnings = <String>[];

    expect(
      decodeAll(withNoise, warnings: warnings).map((e) => e.toString()),
      orderedEquals(decodeAll(packets).map((e) => e.toString())),
    );
    expect(warnings, isNotEmpty);
  });
}
