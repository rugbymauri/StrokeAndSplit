import 'package:aergrow/data/sources/erg_source.dart';
import 'package:aergrow/data/sources/erg_source_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erg_protocol/erg_protocol.dart';

import '../../support/fake_erg_source.dart';
import '../../support/fixtures.dart';

class _SourceLabel extends ConsumerWidget {
  const _SourceLabel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(activeErgSourceProvider);
    return Text(source == null ? 'keine Quelle' : '${source.kind.name}: ${source.name}',
        textDirection: TextDirection.ltr);
  }
}

class _FixedSource extends ActiveErgSource {
  _FixedSource(this.source);

  final ErgSource source;

  @override
  ErgSource? build() => source;
}

void main() {
  testWidgets('widgets see the source selected by a provider override', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        activeErgSourceProvider
            .overrideWith(() => _FixedSource(FakeErgSource(kind: ErgSourceKind.simulator, name: 'Sim'))),
      ],
      child: const _SourceLabel(),
    ));

    expect(find.text('simulator: Sim'), findsOneWidget);
  });

  testWidgets('switching the source stops the previous one', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final first = FakeErgSource(name: 'eins');
    final second = FakeErgSource(kind: ErgSourceKind.replay, name: 'zwei');

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const _SourceLabel()));
    expect(find.text('keine Quelle'), findsOneWidget);

    await container.read(activeErgSourceProvider.notifier).use(first);
    await container.read(activeErgSourceProvider.notifier).use(second);
    await tester.pump();

    expect(first.stopped, isTrue);
    expect(second.started, isTrue);
    expect(find.text('replay: zwei'), findsOneWidget);
  });

  test('decodes packets of the active source into rowing events', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final source = FakeErgSource();
    await container.read(activeErgSourceProvider.notifier).use(source);

    final events = <RowingEvent>[];
    container.read(rowingEventsProvider).listen(events.add);
    const tick = StatusTick(
      elapsed: Duration(seconds: 5),
      distanceMeters: 20,
      workoutType: WorkoutType.justRowSplits,
      workoutState: WorkoutState.workoutRow,
      isRowing: true,
      pace: Duration(minutes: 2),
    );
    const Pm5Encoder().encodeStatus(tick, at: Duration.zero).forEach(source.emit);
    await Future<void>.delayed(Duration.zero);

    expect(events.whereType<StatusTick>().single.pace, const Duration(minutes: 2));
  });

  test('decodes the packets of an FTMS source with the FTMS decoder', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final source = FakeErgSource(kind: ErgSourceKind.ftms, name: 'Rower 42', protocol: ErgProtocol.ftms);
    await container.read(activeErgSourceProvider.notifier).use(source);

    final events = <RowingEvent>[];
    container.read(rowingEventsProvider).listen(events.add);
    ftmsRowing(seconds: 10).forEach(source.emit);
    await Future<void>.delayed(Duration.zero);

    final tick = events.whereType<StatusTick>().last;
    expect(tick.distanceMeters, 40);
    expect(tick.pace, const Duration(minutes: 2, seconds: 5));
    expect(tick.workoutState, WorkoutState.unknown);
    expect(events.whereType<Stroke>().map((s) => s.strokeNumber), [1, 2, 3, 4]);
  });
}
