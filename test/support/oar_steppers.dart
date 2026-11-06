import 'package:strokesplit/app/widgets/oar_stepper.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The value of the [OarStepper] with [key].
int stepperValue(WidgetTester tester, Key key) =>
    tester.widget<OarStepper>(find.byKey(key)).value;

/// Taps the button "more" or "less" of the [OarStepper] with [key] once.
Future<void> tapStep(WidgetTester tester, Key key, {required bool more}) async {
  final button = find.descendant(
    of: find.byKey(key),
    matching: find.bySemanticsLabel(
      RegExp(more ? r' (mehr|more)$' : r' (weniger|less)$'),
    ),
  );
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

/// Taps the [OarStepper] with [key] up or down until it shows [target].
Future<void> stepTo(WidgetTester tester, Key key, int target) async {
  for (var taps = 0; taps < 200; taps++) {
    final value = stepperValue(tester, key);
    if (value == target) return;
    await tapStep(tester, key, more: value < target);
  }
  fail('$key does not reach $target, it stays at ${stepperValue(tester, key)}');
}
