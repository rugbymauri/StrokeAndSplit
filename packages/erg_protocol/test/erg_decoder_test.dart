import 'package:erg_protocol/erg_protocol.dart';
import 'package:test/test.dart';

void main() {
  test(
    'creates the PM5 decoder for the PM5 protocol, with chest strap support',
    () {
      expect(
        ErgDecoder.forProtocol(ErgProtocol.pm5),
        isA<HeartRateDecoder>().having(
          (d) => d.inner,
          'inner',
          isA<Pm5Decoder>(),
        ),
      );
    },
  );

  test('reads a stored protocol and treats a missing one as PM5', () {
    expect(ErgProtocol.parse('ftms'), ErgProtocol.ftms);
    expect(ErgProtocol.parse('pm5'), ErgProtocol.pm5);
    expect(ErgProtocol.parse(null), ErgProtocol.pm5);
    expect(() => ErgProtocol.parse('ant'), throwsFormatException);
  });
}
