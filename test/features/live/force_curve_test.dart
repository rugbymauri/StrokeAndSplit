import 'dart:convert';
import 'dart:math' as math;

import 'package:aergrow/app/design_tokens.dart';
import 'package:aergrow/features/live/force_curve.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/localized_app.dart';

/// A force curve in Newton shaped like one from the PM5: [count] values, starting above 0,
/// rising quickly to [peak], falling off slowly and ending on 0, with values repeated in pairs.
List<double> _curve(int count, double peak) => [
      for (var i = 0; i < count; i++)
        i == count - 1 ? 0 : (peak * (0.04 + 0.96 * _rise((i ~/ 2 * 2) / (count - 1)))).roundToDouble(),
    ];

/// From 0 at the catch over 1 before the middle of the drive back to 0 at the finish.
double _rise(double share) => math.sin(math.pi * math.pow(share, 0.8));

final _last = _curve(60, 620);
final _previous = _curve(52, 540);

/// The bundled fonts, so texts in the goldens look as in the app.
Future<void> _loadFonts() async {
  final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final family in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(family['family'] as String);
    for (final font in (family['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

const _golden = Key('golden');

/// [curve] at [size] on [background], as placed in the canvas screen.
Future<void> _pump(WidgetTester tester, Widget curve, Size size, {Color background = AppColors.bg}) async {
  tester.view.physicalSize = Size(size.width + 24, size.height + 24);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(LocalizedApp(
    home: Material(
      color: AppColors.bg,
      child: Center(
        child: RepaintBoundary(
        key: _golden,
        child: ColoredBox(
          color: background,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox.fromSize(size: size, child: curve),
          ),
        ),
      ),
      ),
    ),
  ));
}

/// The sizes of the curve in the canvas screens: a card of 350 px with a curve of about 96 px,
/// the strip "Kraft" of about 60 px and the curve below the pace and in the stroke rate card.
const _cardSize = Size(350, 132);
const _stripSize = Size(350, 60);
const _inlineSize = Size(380, 88);
const _tintedSize = Size(220, 120);

void main() {
  group('ForceCurves', () {
    StrokeForceCurve curve(int strokeNumber) =>
        StrokeForceCurve(elapsed: Duration.zero, strokeNumber: strokeNumber, forcesNewtons: const [0, 100, 0]);

    test('keeps the latest curve and the one before', () {
      final curves = const ForceCurves().add(curve(2)).add(curve(3)).add(curve(4));

      expect(curves.last?.strokeNumber, 4);
      expect(curves.previous?.strokeNumber, 3);
    });

    test('has no previous curve after the first one', () {
      expect(const ForceCurves().add(curve(2)).previous, isNull);
    });

    test('drops the previous curve when the stroke numbers start over', () {
      final curves = const ForceCurves().add(curve(17)).add(curve(2));

      expect(curves.last?.strokeNumber, 2);
      expect(curves.previous, isNull);
    });
  });

  setUpAll(_loadFonts);

  group('in the card', () {
    testWidgets('shows the last stroke over the previous one with a legend', (tester) async {
      await _pump(tester, ForceCurve(last: _last, previous: _previous), _cardSize);

      expect(find.text('Letzter'), findsOneWidget);
      expect(find.text('Vorheriger'), findsOneWidget);
      await expectLater(find.byKey(_golden), matchesGoldenFile('goldens/force_curve_card.png'));
    });

    testWidgets('shows only the last stroke after the first curve', (tester) async {
      await _pump(tester, ForceCurve(last: _last), _cardSize);

      expect(find.text('Letzter'), findsOneWidget);
      expect(find.text('Vorheriger'), findsNothing);
      await expectLater(find.byKey(_golden), matchesGoldenFile('goldens/force_curve_card_first.png'));
    });

    testWidgets('waits for the first stroke with a dashed baseline', (tester) async {
      await _pump(tester, const ForceCurve(last: null), _cardSize);

      expect(find.text('Warte auf ersten Schlag'), findsOneWidget);
      expect(find.text('Letzter'), findsNothing);
      await expectLater(find.byKey(_golden), matchesGoldenFile('goldens/force_curve_card_waiting.png'));
    });

    testWidgets('waits as well for a curve without force', (tester) async {
      await _pump(tester, const ForceCurve(last: [0, 0, 0]), _cardSize);

      expect(find.byKey(const Key('force-curve-waiting')), findsOneWidget);
    });

    testWidgets('fits a narrow card in English', (tester) async {
      tester.view.physicalSize = const Size(280, 132);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(LocalizedApp(
        locale: const Locale('en'),
        home: Material(child: ForceCurve(last: _last, previous: _previous)),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Previous'), findsOneWidget);
    });
  });

  group('in the strip', () {
    testWidgets('shows both strokes beside the label', (tester) async {
      await _pump(tester, ForceCurve(last: _last, previous: _previous, variant: ForceCurveVariant.strip), _stripSize);

      expect(find.text('Kraft'), findsOneWidget);
      await expectLater(find.byKey(_golden), matchesGoldenFile('goldens/force_curve_strip.png'));
    });

    testWidgets('waits for the first stroke', (tester) async {
      await _pump(tester, const ForceCurve(last: null, variant: ForceCurveVariant.strip), _stripSize);

      await expectLater(find.byKey(_golden), matchesGoldenFile('goldens/force_curve_strip_waiting.png'));
    });
  });

  testWidgets('shows both strokes below the pace in landscape', (tester) async {
    await _pump(
      tester,
      ForceCurve(last: _last, previous: _previous, variant: ForceCurveVariant.inline),
      _inlineSize,
      background: AppColors.surface,
    );

    await expectLater(find.byKey(_golden), matchesGoldenFile('goldens/force_curve_inline.png'));
  });

  testWidgets('draws both strokes in text on the coloured stroke rate card', (tester) async {
    await _pump(
      tester,
      ForceCurve(
        last: _last,
        previous: _previous,
        variant: ForceCurveVariant.tinted,
        foreground: AppColors.zoneOutText,
      ),
      _tintedSize,
      background: AppColors.zoneOutSurface,
    );

    expect(find.text('Kraftkurve'), findsOneWidget);
    await expectLater(find.byKey(_golden), matchesGoldenFile('goldens/force_curve_tinted.png'));
  });

  group('with the drive length', () {
    for (final (name, variant, size, background) in [
      ('card', ForceCurveVariant.card, _cardSize, AppColors.bg),
      ('strip', ForceCurveVariant.strip, _stripSize, AppColors.bg),
      ('inline', ForceCurveVariant.inline, _inlineSize, AppColors.surface),
      ('tinted', ForceCurveVariant.tinted, _tintedSize, AppColors.zoneOutSurface),
    ]) {
      testWidgets('shows it beside the last stroke: $name', (tester) async {
        await _pump(
          tester,
          ForceCurve(
            last: _last,
            previous: _previous,
            driveLengthMeters: 1.06,
            variant: variant,
            foreground: variant == ForceCurveVariant.tinted ? AppColors.zoneOutText : AppColors.textMuted,
          ),
          size,
          background: background,
        );

        expect(find.text('1,06 m'), findsOneWidget);
        await expectLater(find.byKey(_golden), matchesGoldenFile('goldens/force_curve_${name}_length.png'));
      });
    }

    testWidgets('shows it in English with a decimal point', (tester) async {
      await tester.pumpWidget(LocalizedApp(
        locale: const Locale('en'),
        home: Material(child: ForceCurve(last: _last, driveLengthMeters: 1.06)),
      ));

      expect(find.text('1.06 m'), findsOneWidget);
    });

    for (final length in [null, 0.0]) {
      testWidgets('leaves it out without a length: $length', (tester) async {
        await _pump(tester, ForceCurve(last: _last, previous: _previous, driveLengthMeters: length), _cardSize);

        expect(find.byKey(const Key('force-curve-length')), findsNothing);
        expect(find.textContaining(' m'), findsNothing);
        // Exactly as without the length at all.
        await expectLater(find.byKey(_golden), matchesGoldenFile('goldens/force_curve_card.png'));
      });
    }

    testWidgets('leaves it out without a length in the strip', (tester) async {
      await _pump(tester, ForceCurve(last: _last, previous: _previous, variant: ForceCurveVariant.strip), _stripSize);

      expect(find.byKey(const Key('force-curve-length')), findsNothing);
    });

    testWidgets('leaves it out while waiting for the first stroke', (tester) async {
      await _pump(tester, const ForceCurve(last: null, driveLengthMeters: 1.06), _cardSize);

      expect(find.text('1,06 m'), findsNothing);
    });
  });
}
