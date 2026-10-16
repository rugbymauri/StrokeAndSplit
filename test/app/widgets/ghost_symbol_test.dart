import 'package:aergrow/app/design_tokens.dart';
import 'package:aergrow/app/widgets/ghost_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/localized_app.dart';

const _symbol = Key('symbol');

Future<void> _pump(WidgetTester tester, {Locale locale = const Locale('de')}) => tester.pumpWidget(LocalizedApp(
      locale: locale,
      home: const Center(
        child: RepaintBoundary(
          key: _symbol,
          child: ColoredBox(
            color: AppColors.surface,
            child: Padding(padding: EdgeInsets.all(3), child: GhostSymbol()),
          ),
        ),
      ),
    ));

void main() {
  testWidgets('is 10 px wide', (tester) async {
    await _pump(tester);

    expect(tester.getSize(find.byType(GhostSymbol)), const Size(10, 4));
  });

  for (final locale in const [Locale('de'), Locale('en')]) {
    testWidgets('tells the screen reader it is the ghost ($locale)', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, locale: locale);

      expect(
        tester.getSemantics(find.byType(GhostSymbol)),
        matchesSemantics(label: 'Ghost', isImage: true),
      );
      semantics.dispose();
    });
  }

  testWidgets('paints a violet rhombus with a rim in the colour of the surface', (tester) async {
    tester.view.devicePixelRatio = 8;
    addTearDown(tester.view.reset);
    await _pump(tester);

    await expectLater(find.byKey(_symbol), matchesGoldenFile('goldens/ghost_symbol.png'));
  });
}
