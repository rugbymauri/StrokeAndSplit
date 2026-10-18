import 'package:strokesplit/data/sources/simulated_source.dart';
import 'package:strokesplit/features/simulator/simulator_controls.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/localized_app.dart';

void main() {
  late SimulatedSource source;

  setUp(() => source = SimulatedSource(targetPace: const Duration(minutes: 2, seconds: 10), targetStrokeRate: 22));

  Future<void> pump(WidgetTester tester, {ValueChanged<ErgProtocol>? onProtocolChanged}) => tester.pumpWidget(
      LocalizedApp(home: Scaffold(body: SimulatorControls(source: source, onProtocolChanged: onProtocolChanged))));

  testWidgets('makes the simulator faster and slower', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip('Schneller'));
    await tester.pump();
    expect(source.targetPace, const Duration(minutes: 2, seconds: 5));
    expect(find.text('2:05'), findsOneWidget);

    await tester.tap(find.byTooltip('Langsamer'));
    await tester.tap(find.byTooltip('Langsamer'));
    await tester.pump();
    expect(source.targetPace, const Duration(minutes: 2, seconds: 15));
  });

  testWidgets('changes the stroke rate', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip('Mehr Schläge'));
    await tester.pump();

    expect(source.targetStrokeRate, 23);
    expect(find.text('23'), findsOneWidget);
  });

  testWidgets('pauses and resumes the simulator', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(source.isPaused, isTrue);

    await tester.tap(find.text('Weiterrudern'));
    await tester.pump();
    expect(source.isPaused, isFalse);
  });

  testWidgets('switches between PM5 and FTMS', (tester) async {
    final chosen = <ErgProtocol>[];
    await pump(tester, onProtocolChanged: chosen.add);

    await tester.tap(find.text('FTMS'));
    await tester.pump();

    expect(chosen, [ErgProtocol.ftms]);
  });

  testWidgets('keeps the protocol while switching is not possible', (tester) async {
    await pump(tester);

    final button = tester.widget<SegmentedButton<ErgProtocol>>(find.byKey(const Key('sim-protocol')));
    expect(button.onSelectionChanged, isNull);
    expect(button.selected, {ErgProtocol.pm5});
  });
}
