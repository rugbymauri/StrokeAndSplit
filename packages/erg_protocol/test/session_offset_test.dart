import 'package:erg_protocol/erg_protocol.dart';
import 'package:test/test.dart';

Duration _s(int seconds) => Duration(seconds: seconds);

void main() {
  test('starts at zero when the PM5 already shows progress', () {
    final offset = SessionOffset.start(
      deviceDistance: 500,
      deviceElapsed: _s(120),
    );

    expect(
      offset.current,
      SessionProgress(distanceMeters: 0, elapsed: Duration.zero),
    );
    expect(
      offset.update(deviceDistance: 650, deviceElapsed: _s(150)),
      SessionProgress(distanceMeters: 150, elapsed: _s(30)),
    );
  });

  test('keeps counting when the PM5 is reset mid-session', () {
    final offset = SessionOffset.start(
      deviceDistance: 0,
      deviceElapsed: Duration.zero,
    );
    offset.update(deviceDistance: 1200, deviceElapsed: _s(300));

    expect(
      offset.update(deviceDistance: 0, deviceElapsed: Duration.zero),
      SessionProgress(distanceMeters: 1200, elapsed: _s(300)),
    );
    expect(
      offset.update(deviceDistance: 100, deviceElapsed: _s(25)),
      SessionProgress(distanceMeters: 1300, elapsed: _s(325)),
    );
  });

  test('detects a reset when only one counter goes backwards', () {
    final offset = SessionOffset.start(
      deviceDistance: 0,
      deviceElapsed: Duration.zero,
    );
    offset.update(deviceDistance: 400, deviceElapsed: _s(100));

    expect(
      offset.update(deviceDistance: 400, deviceElapsed: _s(2)),
      SessionProgress(distanceMeters: 800, elapsed: _s(102)),
    );
  });

  test('survives several resets including one at the start offset', () {
    final offset = SessionOffset.start(
      deviceDistance: 300,
      deviceElapsed: _s(60),
    );
    offset.update(deviceDistance: 800, deviceElapsed: _s(180));
    offset.update(deviceDistance: 0, deviceElapsed: Duration.zero);
    offset.update(deviceDistance: 1000, deviceElapsed: _s(240));
    offset.update(deviceDistance: 0, deviceElapsed: Duration.zero);

    expect(
      offset.update(deviceDistance: 50, deviceElapsed: _s(10)),
      SessionProgress(distanceMeters: 1550, elapsed: _s(370)),
    );
  });

  test('explicit reset carries progress over', () {
    final offset = SessionOffset.start(
      deviceDistance: 0,
      deviceElapsed: Duration.zero,
    );
    offset.update(deviceDistance: 200, deviceElapsed: _s(50));
    offset.reset();

    expect(
      offset.update(deviceDistance: 30, deviceElapsed: _s(8)),
      SessionProgress(distanceMeters: 230, elapsed: _s(58)),
    );
  });
}
