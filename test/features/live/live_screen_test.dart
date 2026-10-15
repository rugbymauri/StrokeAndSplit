import 'dart:async';

import 'package:aergrow/app/platform_providers.dart';
import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:aergrow/features/live/live_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm5_protocol/pm5_protocol.dart';

import '../../support/fake_ble_transport.dart';
import '../../support/fake_erg_source.dart';

class _Fixed extends ActiveErgSource {
  _Fixed(this.source);

  final ErgSource source;

  @override
  ErgSource? build() => source;
}

StatusTick _tick({int? heartRate}) => StatusTick(
      elapsed: const Duration(minutes: 12, seconds: 34),
      distanceMeters: 3021.7,
      workoutType: WorkoutType.justRowSplits,
      workoutState: WorkoutState.workoutRow,
      isRowing: true,
      pace: const Duration(milliseconds: 125300),
      watts: 179,
      strokeRate: 24,
      heartRate: heartRate,
    );

class _Harness {
  // Synchronous, so an emitted event is handled before the next frame.
  final events = StreamController<RowingEvent>.broadcast(sync: true);
  final wakelock = FakeWakelock();

  Future<void> pump(WidgetTester tester, {Size size = const Size(390, 844)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        activeErgSourceProvider.overrideWith(() => _Fixed(FakeErgSource())),
        ergConnectionStateProvider.overrideWithValue(const AsyncData(ErgConnectionState.connected)),
        rowingEventsProvider.overrideWithValue(events.stream),
        wakelockProvider.overrideWithValue(wakelock),
      ],
      child: const MaterialApp(home: LiveScreen()),
    ));
  }

  Future<void> emit(WidgetTester tester, RowingEvent event) async {
    events.add(event);
    await tester.pump();
  }
}

void main() {
  testWidgets('shows the core values in PM5 format', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    await harness.emit(tester, _tick(heartRate: 151));

    expect(find.text('2:05.3'), findsOneWidget);
    expect(find.text('12:34'), findsOneWidget);
    expect(find.text('3021'), findsOneWidget);
    expect(find.text('179'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('151'), findsOneWidget);
  });

  testWidgets('hides the heart rate without a monitor', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    await harness.emit(tester, _tick());

    expect(find.text('Puls'), findsNothing);
  });

  final layouts = {
    'phone portrait': const Size(390, 844),
    'phone landscape': const Size(844, 390),
    'desktop window': const Size(1280, 800),
    'small desktop window': const Size(640, 480),
  };
  for (final MapEntry(key: name, value: size) in layouts.entries) {
    testWidgets('fits all values without overflow on a $name', (tester) async {
      final harness = _Harness();
      await harness.pump(tester, size: size);
      await harness.emit(tester, _tick(heartRate: 151));

      // Overflows would be reported as exceptions and fail the test.
      final pace = tester.getSize(find.byKey(const Key('metric-pace')));
      for (final key in ['metric-elapsed', 'metric-distance', 'metric-watts', 'metric-spm', 'metric-hr']) {
        final other = tester.getSize(find.byKey(Key(key)));
        expect(pace.width * pace.height, greaterThan(other.width * other.height), reason: key);
      }
    });
  }

  testWidgets('marks the values as outdated after 3 seconds without data', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    await harness.emit(tester, _tick());

    await tester.pump(const Duration(milliseconds: 2900));
    expect(find.textContaining('veraltet'), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('veraltet'), findsOneWidget);

    await harness.emit(tester, _tick());
    expect(find.textContaining('veraltet'), findsNothing);
  });

  testWidgets('keeps the screen on while connected and releases it afterwards', (tester) async {
    final harness = _Harness();
    await harness.pump(tester);
    expect(harness.wakelock.enabled, isTrue);

    await tester.pumpWidget(const SizedBox());
    expect(harness.wakelock.enabled, isFalse);
  });
}
