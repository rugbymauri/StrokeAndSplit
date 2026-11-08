import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strokesplit/data/sessions/resistance_providers.dart';
import 'package:strokesplit/features/live/resistance_card.dart';

import '../../support/localized_app.dart';

/// A level as the controller would hold it, with the steps asked for.
class _Fixed extends ResistanceController {
  _Fixed(this.fixed);

  final ResistanceState fixed;
  final steps = <int>[];

  @override
  ResistanceState build() => fixed;

  @override
  void step(int delta) => steps.add(delta);
}

const _range = ResistanceRange(min: 1, max: 15);

Future<_Fixed> _pump(WidgetTester tester, ResistanceState state) async {
  final controller = _Fixed(state);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [resistanceProvider.overrideWith(() => controller)],
      child: const LocalizedApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 320, child: ResistanceCard(tick: null)),
          ),
        ),
      ),
    ),
  );
  return controller;
}

void main() {
  testWidgets('shows the level below its name', (tester) async {
    await _pump(
      tester,
      const ResistanceState(range: _range, level: 6, target: 6),
    );

    expect(find.text('STUFE'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(
      tester.getRect(find.text('6')).top,
      greaterThan(tester.getRect(find.text('STUFE')).top),
    );
  });

  testWidgets('raises with the right blade and lowers with the left', (
    tester,
  ) async {
    final controller = await _pump(
      tester,
      const ResistanceState(range: _range, level: 6, target: 6),
    );

    final lower = find.byKey(const Key('resistance-card-lower'));
    final raise = find.byKey(const Key('resistance-card-raise'));
    expect(tester.getCenter(lower).dx, lessThan(tester.getCenter(raise).dx));
    await tester.tap(raise);
    await tester.pump();
    await tester.tap(lower);
    await tester.pump();
    expect(controller.steps, [1, -1]);
    for (final button in [lower, raise]) {
      final size = tester.getSize(button);
      expect(size.width, greaterThanOrEqualTo(56));
      expect(size.height, greaterThanOrEqualTo(60));
    }
  });

  testWidgets('cannot raise beyond the highest level', (tester) async {
    final controller = await _pump(
      tester,
      const ResistanceState(range: _range, level: 15, target: 15),
    );

    await tester.tap(find.byKey(const Key('resistance-card-raise')));
    await tester.pump();
    expect(controller.steps, isEmpty);
    await tester.tap(find.byKey(const Key('resistance-card-lower')));
    await tester.pump();
    expect(controller.steps, [-1]);
  });

  testWidgets('shows only the level when it cannot be set', (tester) async {
    await _pump(tester, const ResistanceState(level: 6));

    expect(find.text('6'), findsOneWidget);
    expect(find.byKey(const Key('resistance-card-lower')), findsNothing);
    expect(find.byKey(const Key('resistance-card-raise')), findsNothing);
  });

  testWidgets('says when the rower refused a level', (tester) async {
    await _pump(
      tester,
      const ResistanceState(range: _range, level: 6, target: 7, refused: true),
    );

    expect(find.text('Stufe nicht gesetzt'), findsOneWidget);
  });

  testWidgets('is not there without a level', (tester) async {
    await _pump(tester, const ResistanceState());

    expect(find.byKey(const Key('resistance-card')), findsNothing);
  });
}
