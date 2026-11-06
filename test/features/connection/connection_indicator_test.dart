import 'package:strokesplit/app/design_tokens.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/sources/erg_source_providers.dart';
import 'package:strokesplit/features/connection/connection_indicator.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_erg_source.dart';
import '../../support/localized_app.dart';

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
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeErgSourceProvider.overrideWith(
          () =>
              _Fixed(FakeErgSource(kind: kind, name: name, protocol: protocol)),
        ),
        ergConnectionStateProvider.overrideWithValue(AsyncData(state)),
      ],
      child: const LocalizedApp(
        home: Scaffold(
          body: Column(
            children: [
              ConnectionIndicator(),
              ConnectionNotice(),
              SourceBadge(),
            ],
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _dot(WidgetTester tester) =>
    tester
            .widget<Container>(find.byKey(const Key('connection-dot')))
            .decoration!
        as BoxDecoration;

void main() {
  const labels = {
    ErgConnectionState.connected: 'Verbunden',
    ErgConnectionState.connecting: 'Verbinde …',
    ErgConnectionState.scanning: 'Suche …',
    ErgConnectionState.reconnecting: 'Verbindung unterbrochen, verbinde neu …',
    ErgConnectionState.disconnected: 'Getrennt',
  };

  for (final MapEntry(key: state, value: label) in labels.entries) {
    testWidgets('reads the state ${state.name} to screen readers', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, kind: ErgSourceKind.pm5, state: state);

      expect(find.bySemanticsLabel(label), findsOneWidget);
      semantics.dispose();
    });
  }

  testWidgets('shows a connected erg as a filled green dot without text', (
    tester,
  ) async {
    await _pump(
      tester,
      kind: ErgSourceKind.pm5,
      state: ErgConnectionState.connected,
    );

    expect(_dot(tester).color, AppColors.connected);
    expect(find.byKey(const Key('connection-notice')), findsNothing);
    expect(find.text('Verbunden'), findsNothing);
  });

  for (final state in [
    ErgConnectionState.connecting,
    ErgConnectionState.scanning,
    ErgConnectionState.reconnecting,
  ]) {
    testWidgets('shows the state ${state.name} as an orange dot and as text', (
      tester,
    ) async {
      await _pump(tester, kind: ErgSourceKind.pm5, state: state);

      expect(_dot(tester).color, AppColors.zoneOut);
      expect(find.text(labels[state]!), findsOneWidget);
    });
  }

  testWidgets('shows a disconnected erg as an empty grey ring and as text', (
    tester,
  ) async {
    await _pump(
      tester,
      kind: ErgSourceKind.pm5,
      state: ErgConnectionState.disconnected,
    );

    expect(_dot(tester).color, isNull);
    expect(
      _dot(tester).border,
      Border.all(color: AppColors.textMuted, width: 2),
    );
    expect(find.text('Getrennt'), findsOneWidget);
  });

  testWidgets('leaves out the name of a real erg', (tester) async {
    await _pump(
      tester,
      kind: ErgSourceKind.pm5,
      state: ErgConnectionState.connected,
    );

    expect(find.text('PM5 430000001 Row'), findsNothing);
  });

  testWidgets('marks simulated data clearly', (tester) async {
    await _pump(
      tester,
      kind: ErgSourceKind.simulator,
      state: ErgConnectionState.connected,
    );

    expect(find.text('SIMULATOR'), findsOneWidget);
  });

  testWidgets('marks replayed data clearly', (tester) async {
    await _pump(
      tester,
      kind: ErgSourceKind.replay,
      state: ErgConnectionState.connected,
    );

    expect(find.text('REPLAY'), findsOneWidget);
  });

  testWidgets('leaves out the name of an FTMS rower', (tester) async {
    await _pump(
      tester,
      kind: ErgSourceKind.ftms,
      state: ErgConnectionState.connected,
      name: 'Rower 42',
      protocol: ErgProtocol.ftms,
    );

    expect(find.textContaining('Rower 42'), findsNothing);
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
