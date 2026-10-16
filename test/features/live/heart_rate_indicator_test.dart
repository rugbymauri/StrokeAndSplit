import 'package:aergrow/app/design_tokens.dart';
import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/sources/ble/ble_rower_source.dart';
import 'package:aergrow/data/sources/ble/ble_transport.dart';
import 'package:aergrow/data/sources/ble/heart_rate_transport.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/data/sources/heart_rate_choice.dart';
import 'package:aergrow/features/live/live_screen.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/fake_erg_source.dart';
import '../../support/fake_heart_rate_transport.dart';
import '../../support/localized_app.dart';

const _pm5 = FoundRower(id: 'C0:00:00:00:00:01', name: 'PM5 430000001 Row');
const _ftms = FoundRower(id: 'AA:BB:CC:DD:EE:FF', name: 'AergRow FTMS Rower', protocol: ErgProtocol.ftms);
const _h10 = FoundHeartRateMonitor(id: 'A0:9E:1A:12:34:56', name: 'Polar H10 1A2B3C4D');
const _busy = HeartRateConnectException(HeartRateConnectError.failed, message: 'busy');

class _Fixed extends ActiveErgSource {
  _Fixed(this.source);

  final ErgSource source;

  @override
  ErgSource? build() => source;
}

final _dot = find.byKey(const Key('heart-rate-dot'));
final _notice = find.byKey(const Key('heart-rate-notice'));

Color? _dotColor(WidgetTester tester) => (tester.widget<Container>(_dot).decoration! as BoxDecoration).color;

/// The live display with [source] and, unless [paired] is false, the strap H10 paired.
Future<FakeHeartRateTransport> _pump(
  WidgetTester tester,
  ErgSource source, {
  bool paired = true,
  HeartRateConnectException? connectError,
}) async {
  final straps = FakeHeartRateTransport(connectError: connectError);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      activeErgSourceProvider.overrideWith(() => _Fixed(source)),
      heartRateTransportProvider.overrideWithValue(straps),
      heartRateMonitorStoreProvider.overrideWithValue(MemoryHeartRateMonitorStore(paired ? _h10 : null)),
      wakelockProvider.overrideWithValue(FakeWakelock()),
    ],
    child: const LocalizedApp(home: LiveScreen()),
  ));
  await tester.pump();
  return straps;
}

Future<BleRowerSource> _rower([FoundRower device = _pm5]) async {
  final source = BleRowerSource(transport: FakeBleTransport(), device: device);
  await source.start();
  return source;
}

void main() {
  for (final device in [_pm5, _ftms]) {
    testWidgets('shows the strap as connected next to the ${device.protocol.name} rower', (tester) async {
      final semantics = tester.ensureSemantics();
      final straps = await _pump(tester, await _rower(device));

      expect(straps.attempts, [_h10]);
      expect(find.descendant(of: find.byKey(const Key('live-status')), matching: _dot), findsOneWidget);
      expect(find.byKey(const Key('connection-dot')), findsOneWidget);
      expect(_dotColor(tester), AppColors.connected);
      expect(find.bySemanticsLabel('Pulsgurt: Verbunden'), findsOneWidget);
      expect(_notice, findsNothing);
      semantics.dispose();
    });
  }

  testWidgets('shows the strap as reconnecting and the rower still as connected', (tester) async {
    final straps = await _pump(tester, await _rower());

    straps.connectError = _busy;
    straps.links.single.drop();
    await tester.pump();

    expect(_dotColor(tester), AppColors.zoneOut);
    expect(find.text('Pulsgurt: Verbindung unterbrochen, verbinde neu …'), findsOneWidget);
    expect(find.byKey(const Key('connection-notice')), findsNothing);

    // After 30 seconds without the strap it gives up and offers to try again.
    await tester.pump(const Duration(seconds: 31));
    expect(find.textContaining('Verbindung zum Pulsgurt verloren'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });

  testWidgets('explains a failed connection and tries again on request', (tester) async {
    final straps = await _pump(tester, await _rower(), connectError: _busy);

    expect(_dotColor(tester), isNull);
    expect(find.textContaining('nur eine oder zwei Bluetooth-Verbindungen'), findsOneWidget);
    expect(find.byKey(const Key('connection-dot')), findsOneWidget);

    straps.connectError = null;
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pump();

    expect(straps.attempts, [_h10, _h10]);
    expect(_dotColor(tester), AppColors.connected);
    expect(_notice, findsNothing);
  });

  testWidgets('shows no strap with the simulator, even with a paired strap', (tester) async {
    final straps = await _pump(tester, FakeErgSource(kind: ErgSourceKind.simulator));

    expect(_dot, findsNothing);
    expect(_notice, findsNothing);
    expect(straps.attempts, isEmpty);
  });

  testWidgets('shows no strap without a paired one', (tester) async {
    final straps = await _pump(tester, await _rower(), paired: false);

    expect(_dot, findsNothing);
    expect(straps.attempts, isEmpty);
  });
}
