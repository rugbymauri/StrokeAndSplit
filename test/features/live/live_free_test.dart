import 'package:aergrow/features/live/live_free.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/localized_app.dart';

const _tick = StatusTick(
  elapsed: Duration(minutes: 8, seconds: 32),
  distanceMeters: 2014,
  workoutType: WorkoutType.justRowSplits,
  workoutState: WorkoutState.workoutRow,
  isRowing: true,
  pace: Duration(milliseconds: 127400),
  watts: 172,
  strokeRate: 21,
  heartRate: 142,
  calories: 118,
);

const _forces = <double>[0, 20, 60, 110, 140, 150, 130, 90, 40, 0];

Future<void> _pump(WidgetTester tester, Size size, {List<double>? forces = _forces}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(LocalizedApp(
    home: Scaffold(
      body: FreeLiveView(
        tick: _tick,
        session: null,
        forces: forces,
        action: FilledButton(onPressed: () {}, child: const Text('Session beenden')),
      ),
    ),
  ));
}

void main() {
  testWidgets('shows the values of the canvas screen', (tester) async {
    await _pump(tester, const Size(390, 844));

    expect(find.text('2:07.4'), findsOneWidget);
    expect(find.text('21 spm'), findsOneWidget);
    expect(find.text('172'), findsOneWidget);
    expect(find.text('8:32'), findsOneWidget);
    expect(find.text('2 014 m'), findsOneWidget);
    expect(find.text('Puls 142'), findsOneWidget);
    expect(find.text('Kalorien 118'), findsOneWidget);
    expect(find.text('Kraftkurve'), findsOneWidget);
  });

  testWidgets('leaves out the force curve without data', (tester) async {
    await _pump(tester, const Size(390, 844), forces: null);

    expect(find.byKey(const Key('force-curve')), findsNothing);
  });

  testWidgets('leaves out the force curve first when space is short', (tester) async {
    await _pump(tester, const Size(360, 600));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('force-curve')), findsNothing);
  });

  final sizes = {
    'phone portrait': const Size(390, 844),
    'phone landscape': const Size(844, 390),
    'desktop window': const Size(1280, 800),
    'small desktop window': const Size(640, 480),
  };
  for (final MapEntry(key: name, value: size) in sizes.entries) {
    testWidgets('fits a $name with the force curve and the pace as the largest text', (tester) async {
      await _pump(tester, size);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('force-curve')), findsOneWidget);
      final pace = tester.getRect(find.byKey(const Key('metric-pace'))).height;
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        if (text.key == const Key('metric-pace')) continue;
        final reason = text.data ?? text.textSpan?.toPlainText();
        expect(tester.getRect(find.byWidget(text)).height, lessThan(pace), reason: reason);
      }
    });
  }
}
