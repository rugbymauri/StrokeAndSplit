import 'package:pm5_protocol/pm5_protocol.dart';
import 'package:test/test.dart';

Duration _s(int seconds) => Duration(seconds: seconds);

void main() {
  test('starts at zero when the PM5 already shows progress', () {
    final offset = SessionOffset.start(pm5Distance: 500, pm5Elapsed: _s(120));

    expect(offset.current, SessionProgress(distanceMeters: 0, elapsed: Duration.zero));
    expect(
      offset.update(pm5Distance: 650, pm5Elapsed: _s(150)),
      SessionProgress(distanceMeters: 150, elapsed: _s(30)),
    );
  });

  test('keeps counting when the PM5 is reset mid-session', () {
    final offset = SessionOffset.start(pm5Distance: 0, pm5Elapsed: Duration.zero);
    offset.update(pm5Distance: 1200, pm5Elapsed: _s(300));

    expect(
      offset.update(pm5Distance: 0, pm5Elapsed: Duration.zero),
      SessionProgress(distanceMeters: 1200, elapsed: _s(300)),
    );
    expect(
      offset.update(pm5Distance: 100, pm5Elapsed: _s(25)),
      SessionProgress(distanceMeters: 1300, elapsed: _s(325)),
    );
  });

  test('detects a reset when only one counter goes backwards', () {
    final offset = SessionOffset.start(pm5Distance: 0, pm5Elapsed: Duration.zero);
    offset.update(pm5Distance: 400, pm5Elapsed: _s(100));

    expect(
      offset.update(pm5Distance: 400, pm5Elapsed: _s(2)),
      SessionProgress(distanceMeters: 800, elapsed: _s(102)),
    );
  });

  test('survives several resets including one at the start offset', () {
    final offset = SessionOffset.start(pm5Distance: 300, pm5Elapsed: _s(60));
    offset.update(pm5Distance: 800, pm5Elapsed: _s(180));
    offset.update(pm5Distance: 0, pm5Elapsed: Duration.zero);
    offset.update(pm5Distance: 1000, pm5Elapsed: _s(240));
    offset.update(pm5Distance: 0, pm5Elapsed: Duration.zero);

    expect(
      offset.update(pm5Distance: 50, pm5Elapsed: _s(10)),
      SessionProgress(distanceMeters: 1550, elapsed: _s(370)),
    );
  });

  test('explicit reset carries progress over', () {
    final offset = SessionOffset.start(pm5Distance: 0, pm5Elapsed: Duration.zero);
    offset.update(pm5Distance: 200, pm5Elapsed: _s(50));
    offset.reset();

    expect(
      offset.update(pm5Distance: 30, pm5Elapsed: _s(8)),
      SessionProgress(distanceMeters: 230, elapsed: _s(58)),
    );
  });
}
