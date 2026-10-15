import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/sessions/session_accumulator.dart';
import 'package:aergrow/data/sessions/session_providers.dart';
import 'package:aergrow/data/sessions/session_repository.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/features/sessions/sessions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

class _Setup {
  final db = openTestDatabase();
  late final repository = SessionRepository(db);
  late final container = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db),
    wakelockProvider.overrideWithValue(FakeWakelock()),
  ]);

  /// Stores a finished session, recorded from [fixture] when given.
  Future<int> addSession(WidgetTester tester, DateTime startedAt, {String? fixture}) async {
    return (await tester.runAsync(() async {
      final id = await repository.create(startedAt: startedAt, source: ErgSourceKind.pm5, deviceName: 'PM5 Test');
      if (fixture != null) {
        final accumulator = SessionAccumulator(id);
        loadFixture(fixture).packets.forEach(accumulator.add);
        accumulator.finish();
        await repository.write(accumulator.takeBatch());
      }
      await repository.finish(id);
      return id;
    }))!;
  }

  Future<void> pump(WidgetTester tester) async {
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MaterialApp(home: SessionsScreen())),
    );
    await tester.pump();
  }

  Future<void> tearDown(WidgetTester tester) async {
    await container.read(activeErgSourceProvider.notifier).clear();
    await disposeWidgetsWithDatabase(tester);
  }
}

void main() {
  testWidgets('says when nothing is recorded yet', (tester) async {
    final setup = _Setup();
    await setup.pump(tester);

    expect(find.text('Noch keine Sessions aufgezeichnet.'), findsOneWidget);
    await setup.tearDown(tester);
  });

  testWidgets('lists the newest session first', (tester) async {
    final setup = _Setup();
    await setup.addSession(tester, DateTime(2026, 10, 14, 7));
    await setup.addSession(tester, DateTime(2026, 10, 15, 18, 30), fixture: 'just_row');
    await setup.addSession(tester, DateTime(2026, 10, 12, 19));
    await setup.pump(tester);

    final dates = ['15.10.2026, 18:30', '14.10.2026, 07:00', '12.10.2026, 19:00'];
    final tops = [for (final d in dates) tester.getTopLeft(find.text(d)).dy];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(find.textContaining('/500 m'), findsNWidgets(3));
    await setup.tearDown(tester);
  });

  testWidgets('deletes a session only after confirmation', (tester) async {
    final setup = _Setup();
    final id = await setup.addSession(tester, DateTime(2026, 10, 15, 18, 30), fixture: 'just_row');
    await setup.pump(tester);

    Future<void> chooseDelete() async {
      await tester.tap(find.byTooltip('Aktionen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();
      expect(find.text('Session löschen?'), findsOneWidget);
    }

    await chooseDelete();
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.text('15.10.2026, 18:30'), findsOneWidget);

    await chooseDelete();
    await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
    await tester.pumpAndSettle();
    expect(find.text('Noch keine Sessions aufgezeichnet.'), findsOneWidget);

    final left = await tester.runAsync(() async => (
          await setup.repository.get(id),
          await setup.db.select(setup.db.samples).get(),
          await setup.db.select(setup.db.rawPackets).get(),
        ));
    expect(left!.$1, isNull);
    expect(left.$2, isEmpty);
    expect(left.$3, isEmpty);
    await setup.tearDown(tester);
  });

  testWidgets('plays a session back in the live display', (tester) async {
    final setup = _Setup();
    await setup.addSession(tester, DateTime(2026, 10, 15, 18, 30), fixture: 'just_row');
    await setup.pump(tester);

    await tester.tap(find.byTooltip('Aktionen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abspielen'));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(setup.container.read(activeErgSourceProvider)?.kind, ErgSourceKind.replay);
    expect(find.text('REPLAY'), findsOneWidget);
    final distance = tester.widget<Text>(
      find.descendant(of: find.byKey(const Key('metric-distance')), matching: find.byType(Text)).last,
    );
    expect(int.parse(distance.data!), greaterThan(0));
    await setup.tearDown(tester);
  });
}
