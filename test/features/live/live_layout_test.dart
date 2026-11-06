import 'package:strokesplit/features/live/live_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<LiveLayout> _layoutAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late LiveLayout chosen;
  await tester.pumpWidget(
    LiveLayoutBuilder(
      builder: (context, layout) {
        chosen = layout;
        return const SizedBox.expand();
      },
    ),
  );
  return chosen;
}

void main() {
  testWidgets('uses the landscape layout in a laptop window of 1200 × 700', (
    tester,
  ) async {
    expect(
      await _layoutAt(tester, const Size(1200, 700)),
      LiveLayout.landscape,
    );
  });

  testWidgets('uses the portrait layout on a phone of 390 × 844', (
    tester,
  ) async {
    expect(await _layoutAt(tester, const Size(390, 844)), LiveLayout.portrait);
  });

  test('takes a square space as portrait', () {
    expect(LiveLayout.of(const Size(500, 500)), LiveLayout.portrait);
  });
}
