import 'package:strokesplit/app/design_tokens.dart';
import 'package:strokesplit/app/widgets/oar_stepper.dart';
import 'package:strokesplit/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/localized_app.dart';

String _pace(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// An [OarStepper] that keeps the value it reports; [stepLabel] gets the texts of the app.
Future<void> _pump(
  WidgetTester tester, {
  required int value,
  required int step,
  required String Function(AppLocalizations l10n) stepLabel,
  int? min,
  int? max,
  String Function(int)? format,
  String? unit,
  String? label,
  OarStepperSize size = OarStepperSize.large,
  Locale locale = const Locale('de'),
}) {
  var current = value;
  return tester.pumpWidget(LocalizedApp(
    locale: locale,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          child: StatefulBuilder(
            builder: (context, setState) => OarStepper(
              value: current,
              step: step,
              stepLabel: stepLabel(context.l10n),
              min: min,
              max: max,
              format: format,
              unit: unit,
              label: label,
              size: size,
              onChanged: (v) => setState(() => current = v),
            ),
          ),
        ),
      ),
    ),
  ));
}

/// Holds the pointer down for [duration], with frames in between as on a device.
Future<void> _holdFor(WidgetTester tester, Duration duration) async {
  const frame = Duration(milliseconds: 10);
  for (var held = Duration.zero; held < duration; held += frame) {
    await tester.pump(frame);
  }
}

double _opacityOf(WidgetTester tester, String label) =>
    tester.widget<Opacity>(find.descendant(of: find.bySemanticsLabel(label), matching: find.byType(Opacity))).opacity;

void main() {
  testWidgets('adds one step to the pace band', (tester) async {
    await _pump(tester, value: 105, step: 5, stepLabel: (l) => l.stepSeconds(5), format: _pace, unit: '/500 m');

    await tester.tap(find.bySemanticsLabel('5 Sekunden mehr'));
    await tester.pump();

    expect(find.text('1:50'), findsOneWidget);
    expect(find.text('/500 m'), findsOneWidget);
  });

  testWidgets('moves a zone back by one step', (tester) async {
    await _pump(tester, value: 1600, step: 50, stepLabel: (_) => '50 m', unit: 'm');

    await tester.tap(find.bySemanticsLabel('50 m weniger'));
    await tester.pump();

    expect(find.text('1550'), findsOneWidget);
  });

  testWidgets('disables less at the minimum and keeps the value', (tester) async {
    await _pump(tester, value: 1, step: 1, min: 1, stepLabel: (l) => l.lapsCount(1));

    await tester.tap(find.bySemanticsLabel('1 Runde weniger'));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(_opacityOf(tester, '1 Runde weniger'), 0.35);
    expect(_opacityOf(tester, '1 Runde mehr'), 1);
  });

  testWidgets('disables more when the step would pass the maximum', (tester) async {
    await _pump(tester, value: 95, step: 10, max: 100, stepLabel: (_) => '10 m', size: OarStepperSize.compact);

    await tester.tap(find.bySemanticsLabel('10 m mehr'));
    await tester.pump();

    expect(find.text('95'), findsOneWidget);
    expect(_opacityOf(tester, '10 m mehr'), 0.35);
  });

  testWidgets('repeats the step while held, faster after a second', (tester) async {
    await _pump(tester, value: 2000, step: 100, stepLabel: (_) => '100 m', unit: 'm');

    final gesture = await tester.startGesture(tester.getCenter(find.bySemanticsLabel('100 m mehr')));
    await _holdFor(tester, const Duration(milliseconds: 1000));
    expect(find.text('2500'), findsOneWidget);

    await _holdFor(tester, const Duration(milliseconds: 500));
    expect(find.text('3500'), findsOneWidget);

    await gesture.up();
    await _holdFor(tester, const Duration(milliseconds: 500));
    expect(find.text('3500'), findsOneWidget, reason: 'no step on release and none after');
  });

  testWidgets('stops repeating at the maximum', (tester) async {
    await _pump(tester, value: 2000, step: 100, max: 2300, stepLabel: (_) => '100 m');

    final gesture = await tester.startGesture(tester.getCenter(find.bySemanticsLabel('100 m mehr')));
    await _holdFor(tester, const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();

    expect(find.text('2300'), findsOneWidget);
    expect(_opacityOf(tester, '100 m mehr'), 0.35);
  });

  testWidgets('tells screen readers the value and the direction of each button', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      value: 30,
      step: 1,
      min: 30,
      stepLabel: (l) => l.stepStrokes(1),
      unit: 'spm',
      label: 'Mindestens',
      size: OarStepperSize.compact,
    );

    expect(
      tester.getSemantics(find.byType(OarStepper)),
      isSemantics(
        label: 'Mindestens',
        value: '30 spm',
        increasedValue: '31 spm',
        hasIncreaseAction: true,
        hasDecreaseAction: false,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('1 Schlag weniger')),
      isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('1 Schlag mehr')),
      isSemantics(isButton: true, isEnabled: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  testWidgets('changes the value through the screen reader actions', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, value: 105, step: 5, stepLabel: (l) => l.stepSeconds(5), format: _pace);

    final node = tester.getSemantics(find.byType(OarStepper));
    node.owner!.performAction(node.id, SemanticsAction.increase);
    await tester.pump();
    expect(find.text('1:50'), findsOneWidget);

    node.owner!.performAction(node.id, SemanticsAction.decrease);
    await tester.pump();
    expect(find.text('1:45'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('labels the buttons in English', (tester) async {
    await _pump(
      tester,
      value: 105,
      step: 5,
      stepLabel: (l) => l.stepSeconds(5),
      format: _pace,
      locale: const Locale('en'),
    );

    await tester.tap(find.bySemanticsLabel('5 seconds less'));
    await tester.pump();

    expect(find.text('1:40'), findsOneWidget);
    expect(find.bySemanticsLabel('5 seconds more'), findsOneWidget);
  });

  testWidgets('takes the background of a card', (tester) async {
    Color fill() {
      final box = find.descendant(of: find.byType(OarStepper), matching: find.byType(DecoratedBox)).first;
      return (tester.widget<DecoratedBox>(box).decoration as BoxDecoration).color!;
    }
    Widget stepper({Color? background}) => LocalizedApp(
          locale: const Locale('de'),
          home: Scaffold(
            body: background == null
                ? OarStepper(value: 30, step: 1, stepLabel: '1 Schlag', onChanged: (_) {})
                : OarStepper(value: 30, step: 1, stepLabel: '1 Schlag', onChanged: (_) {}, background: background),
          ),
        );

    await tester.pumpWidget(stepper());
    expect(fill(), AppColors.surface);
    await tester.pumpWidget(stepper(background: AppColors.bg));
    expect(fill(), AppColors.bg);
  });
}
