import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/features/connection/connection_indicator.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_erg_source.dart';

class _Fixed extends ActiveErgSource {
  _Fixed(this.source);

  final ErgSource source;

  @override
  ErgSource? build() => source;
}

Future<void> _pump(
  WidgetTester tester, {
  required ErgSourceKind kind,
  required ErgConnectionState state,
  String name = 'PM5 430000001 Row',
  ErgProtocol protocol = ErgProtocol.pm5,
}) {
  return tester.pumpWidget(ProviderScope(
    overrides: [
      activeErgSourceProvider.overrideWith(() => _Fixed(FakeErgSource(kind: kind, name: name, protocol: protocol))),
      ergConnectionStateProvider.overrideWithValue(AsyncData(state)),
    ],
    child: const MaterialApp(home: Scaffold(body: ConnectionIndicator())),
  ));
}

void main() {
  const labels = {
    ErgConnectionState.connected: 'Verbunden',
    ErgConnectionState.connecting: 'Verbinde …',
    ErgConnectionState.scanning: 'Suche …',
    ErgConnectionState.reconnecting: 'Verbindung unterbrochen, verbinde neu …',
    ErgConnectionState.disconnected: 'Getrennt',
  };

  for (final MapEntry(key: state, value: label) in labels.entries) {
    testWidgets('shows the state ${state.name}', (tester) async {
      await _pump(tester, kind: ErgSourceKind.pm5, state: state);

      expect(find.text(label), findsOneWidget);
    });
  }

  testWidgets('names the connected PM5', (tester) async {
    await _pump(tester, kind: ErgSourceKind.pm5, state: ErgConnectionState.connected);

    expect(find.text('PM5 430000001 Row'), findsOneWidget);
  });

  testWidgets('marks simulated data clearly', (tester) async {
    await _pump(tester, kind: ErgSourceKind.simulator, state: ErgConnectionState.connected);

    expect(find.text('SIMULATOR'), findsOneWidget);
  });

  testWidgets('marks replayed data clearly', (tester) async {
    await _pump(tester, kind: ErgSourceKind.replay, state: ErgConnectionState.connected);

    expect(find.text('REPLAY'), findsOneWidget);
  });

  testWidgets('names an FTMS rower and marks it as FTMS', (tester) async {
    await _pump(
      tester,
      kind: ErgSourceKind.ftms,
      state: ErgConnectionState.connected,
      name: 'Rower 42',
      protocol: ErgProtocol.ftms,
    );

    expect(find.text('Rower 42 · FTMS'), findsOneWidget);
  });

  testWidgets('marks the simulator in FTMS mode', (tester) async {
    await _pump(
      tester,
      kind: ErgSourceKind.simulator,
      state: ErgConnectionState.connected,
      protocol: ErgProtocol.ftms,
    );

    expect(find.text('SIMULATOR (FTMS)'), findsOneWidget);
  });
}
