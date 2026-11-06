import 'package:strokesplit/app/platform_providers.dart';
import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/sessions/first_stroke.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/data/sources/erg_source_providers.dart';
import 'package:strokesplit/data/templates/session_template.dart';
import 'package:strokesplit/data/templates/template_repository.dart';
import 'package:strokesplit/features/live/live_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/fake_erg_source.dart';
import '../../support/fixtures.dart';
import '../../support/localized_app.dart';
import '../../support/test_database.dart';

class _Fixed extends ActiveErgSource {
  _Fixed(this.source);

  final ErgSource source;

  @override
  ErgSource? build() => source;
}

/// The live display of a template rowed on a PM5 that plays `just_row`
/// (start-on-first-stroke).
class _Harness {
  final db = openTestDatabase();
  final source = FakeErgSource()
    ..connectionState = ErgConnectionState.connected;
  final packets = loadFixture('just_row').packets;

  /// The packet with the first stroke.
  late final int trigger = () {
    final detector = FirstStrokeDetector(ErgProtocol.pm5);
    return packets.indexWhere((p) => detector.add(p) != null);
  }();

  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('de'),
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final template = (await tester.runAsync(() async {
      final course = await CourseRepository(db).create(
        'Seerunde',
        CourseDefinition.single(axis: CourseAxis.distance, length: 1000),
      );
      final templates = TemplateRepository(db);
      return templates.get(
        await templates.create('Seerunde x3', courseId: course, laps: 3),
      );
    }))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          activeErgSourceProvider.overrideWith(() => _Fixed(source)),
          wakelockProvider.overrideWithValue(FakeWakelock()),
        ],
        child: LocalizedApp(locale: locale, home: _Home(template)),
      ),
    );
    await tester.tap(find.text('Los'));
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(LiveScreen)),
    );
  }

  /// Sends [packets] and lets the recorder store what it needs to.
  Future<void> emit(WidgetTester tester, Iterable<RawPacket> packets) async {
    await tester.runAsync(() async {
      packets.forEach(source.emit);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
  }

  Future<void> end(WidgetTester tester) async {
    await tester.runAsync(
      () => container.read(sessionRecorderProvider.notifier).stop(),
    );
    await disposeWidgetsWithDatabase(tester);
  }
}

class _Home extends StatelessWidget {
  const _Home(this.template);

  final SessionTemplate template;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LiveScreen(plan: template.toPlan()),
        ),
      ),
      child: const Text('Los'),
    ),
  );
}

const _hint = 'Bereit – startet mit dem ersten Schlag';

void main() {
  testWidgets(
    'shows that the template starts with the first stroke, until it does',
    (tester) async {
      final harness = _Harness();
      await harness.pump(tester);
      expect(find.text(_hint), findsOneWidget);

      await harness.emit(tester, harness.packets.take(harness.trigger));
      expect(find.text(_hint), findsOneWidget, reason: 'the rower is idle');
      expect(harness.container.read(sessionRecorderProvider)!.ready, isTrue);

      await harness.emit(
        tester,
        harness.packets.skip(harness.trigger).take(60),
      );
      expect(find.text(_hint), findsNothing);
      expect(harness.container.read(sessionRecorderProvider)!.ready, isFalse);

      await harness.end(tester);
    },
  );

  testWidgets('says it in English', (tester) async {
    final harness = _Harness();
    await harness.pump(tester, locale: const Locale('en'));

    expect(find.text('Ready – starts with your first stroke'), findsOneWidget);
    await harness.end(tester);
  });

  testWidgets('going back before the first stroke stores no session', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.pump(tester);
    await harness.emit(tester, harness.packets.take(harness.trigger));

    // Going back drops the ready session and keeps the rower connected.
    await tester.runAsync(() async {
      await tester.binding.handlePopRoute();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(find.byType(LiveScreen), findsNothing);
    expect(harness.source.stopped, isFalse);
    expect(harness.container.read(sessionRecorderProvider), isNull);
    expect(
      await tester.runAsync(harness.db.select(harness.db.sessions).get),
      isEmpty,
    );
    await disposeWidgetsWithDatabase(tester);
  });
}
