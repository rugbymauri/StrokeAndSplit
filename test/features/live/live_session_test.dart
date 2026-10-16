import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/data/sources/simulated_source.dart';
import 'package:aergrow/features/live/live_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/test_database.dart';
import '../../support/localized_app.dart';

class _Fixed extends ActiveErgSource {
  _Fixed(this.source);

  final ErgSource source;

  @override
  ErgSource? build() => source;
}

void main() {
  testWidgets('records a simulated session and shows its summary', (tester) async {
    final db = openTestDatabase();
    final source = SimulatedSource(seed: 1);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        activeErgSourceProvider.overrideWith(() => _Fixed(source)),
        wakelockProvider.overrideWithValue(FakeWakelock()),
      ],
      child: const LocalizedApp(home: LiveScreen()),
    ));
    await source.start();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    final pm5Distance = tester.widget<Text>(find.byKey(const Key('metric-distance'))).textSpan!.toPlainText();
    expect(int.parse(pm5Distance.replaceAll(RegExp(r'\D'), '')), greaterThan(0));

    await tester.tap(find.text('Session starten'));
    await tester.pump();
    expect(find.text('Session beenden'), findsOneWidget);
    // The session counts from zero, not from what the simulator shows.
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.widget<Text>(find.byKey(const Key('metric-elapsed'))).textSpan!.toPlainText(), '0:00');

    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.tap(find.text('Session beenden'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Distanz'), findsOneWidget);
    expect(find.text('Simulator'), findsOneWidget);
    final session = (await tester.runAsync(() => db.select(db.sessions).getSingle()))!;
    expect(session.durationMs, closeTo(30000, 1000));
    expect(session.distanceDm, greaterThan(0));
    expect(find.text('${session.distanceDm ~/ 10} m'), findsOneWidget);

    await source.stop();
    await disposeWidgetsWithDatabase(tester);
  });
}
