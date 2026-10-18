import 'dart:math' as math;

import 'package:strokesplit/app/design_tokens.dart';
import 'package:strokesplit/features/live/force_curve.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fonts.dart';
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

    StrokeForceCurve peaking(int strokeNumber, double peak) =>
        StrokeForceCurve(elapsed: Duration.zero, strokeNumber: strokeNumber, forcesNewtons: [40, peak, 0]);

    test('starts on the fixed scale, whatever the peak of the first curve', () {
      expect(const ForceCurves().add(peaking(2, 300)).scaleNewtons, 1000);
      expect(const ForceCurves().add(peaking(2, 658)).scaleNewtons, 1000);
    });

    test('widens the scale in steps for a stronger curve and never narrows it', () {
      final strong = const ForceCurves().add(peaking(2, 600)).add(peaking(3, 1210));
      final weakAfter = strong.add(peaking(4, 250)).add(peaking(5, 700));

      expect(strong.scaleNewtons, 1500);
      expect(weakAfter.scaleNewtons, 1500);
      expect(weakAfter.add(peaking(6, 1600)).scaleNewtons, 2000);
    });

    test('starts the scale over when the stroke numbers start over', () {
      final curves = const ForceCurves().add(peaking(30, 1210)).add(peaking(2, 500));

      expect(curves.scaleNewtons, 1000);
    });
  });

  group('ForceScale', () {
    test('keeps the scale for a curve that fits on it', () {
      expect(ForceScale.fitting(0), 1000);
      expect(ForceScale.fitting(1000), 1000);
      expect(ForceScale.fitting(700, atLeast: 1500), 1500);
    });

    test('goes to the next step of 500 N above the peak', () {
      expect(ForceScale.fitting(1000.5), 1500);
      expect(ForceScale.fitting(1500), 1500);
      expect(ForceScale.fitting(1750), 2000);
    });
  });

  setUpAll(loadAppFonts);

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

  group('on the absolute scale', () {
    /// A curve that stays close to [peak] over most of the drive.
    List<double> plateau(double peak) => [0, for (var i = 0; i < 20; i++) i.isEven ? peak : peak - 4, 0];

    Future<void> pumpInline(WidgetTester tester, List<double> last, {double scale = 1000}) => _pump(
          tester,
          ForceCurve(last: last, scaleNewtons: scale, variant: ForceCurveVariant.inline),
          _inlineSize,
          background: AppColors.surface,
        );

    /// The point in the middle of the plot at the height of [force] on a scale up to [scale].
    Offset at(double force, {double scale = 1000}) {
      const top = 1.5;
      return Offset(_inlineSize.width / 2, _inlineSize.height - (_inlineSize.height - top) * force / scale);
    }

    final plot = find.byKey(const Key('force-curve-plot'));

    testWidgets('draws a weak stroke lower than a strong one', (tester) async {
      await pumpInline(tester, plateau(900));
      expect(plot, paints..path(includes: [at(200), at(600), at(850)], excludes: [at(950)]));

      await pumpInline(tester, plateau(300));
      expect(plot, paints..path(includes: [at(200)], excludes: [at(600), at(850)]));
    });

    testWidgets('draws a curve above the scale on the next step instead of cutting it off', (tester) async {
      await pumpInline(tester, plateau(1200));

      expect(plot, paints..path(includes: [at(1100, scale: 1500)], excludes: [at(1300, scale: 1500)]));
      expect(find.text('1500 N'), findsOneWidget);
    });

    testWidgets('does not narrow a wider scale for a weak stroke', (tester) async {
      await pumpInline(tester, plateau(300), scale: 1500);

      expect(plot, paints..path(includes: [at(200, scale: 1500)], excludes: [at(400, scale: 1500)]));
      expect(find.text('1500 N'), findsOneWidget);
    });

    testWidgets('draws the previous stroke on the same scale', (tester) async {
      await _pump(
        tester,
        ForceCurve(last: plateau(300), previous: plateau(900), variant: ForceCurveVariant.inline),
        _inlineSize,
        background: AppColors.surface,
      );

      // The previous stroke first, as a line up near 900 N; the last one stays low.
      expect(plot, paints..path(includes: [at(850)])..path(excludes: [at(600)]));
    });

    for (final (name, variant, size) in [
      ('card', ForceCurveVariant.card, _cardSize),
      ('inline', ForceCurveVariant.inline, _inlineSize),
      ('tinted', ForceCurveVariant.tinted, _tintedSize),
    ]) {
      testWidgets('labels the guide lines and shows the peak: $name', (tester) async {
        await _pump(tester, ForceCurve(last: _last, previous: _previous, variant: variant), size);

        expect(find.text('500 N'), findsOneWidget);
        expect(find.text('1000 N'), findsOneWidget);
        expect(find.text('620 N'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('keeps only the lines in the narrow strip', (tester) async {
      await _pump(tester, ForceCurve(last: _last, variant: ForceCurveVariant.strip), _stripSize);

      expect(find.text('500 N'), findsNothing);
      expect(find.text('620 N'), findsOneWidget);
      expect(find.byKey(const Key('force-curve-plot')), paints..line()..line());
    });

    testWidgets('shows no peak while waiting', (tester) async {
      await _pump(tester, const ForceCurve(last: null), _cardSize);

      expect(find.byKey(const Key('force-curve-peak')), findsNothing);
    });
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

        expect(find.text('106 cm'), findsOneWidget);
        await expectLater(find.byKey(_golden), matchesGoldenFile('goldens/force_curve_${name}_length.png'));
      });
    }

    testWidgets('shows it in English with a decimal point', (tester) async {
      await tester.pumpWidget(LocalizedApp(
        locale: const Locale('en'),
        home: Material(child: ForceCurve(last: _last, driveLengthMeters: 1.06)),
      ));

      expect(find.text('106 cm'), findsOneWidget);
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

      expect(find.text('106 cm'), findsNothing);
    });
  });
}
