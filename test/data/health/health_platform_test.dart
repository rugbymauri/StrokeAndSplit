import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strokesplit/data/health/health_platform.dart';
import 'package:strokesplit/data/health/health_exercise.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(ChannelHealthPlatform.name);
  final calls = <MethodCall>[];
  Object? Function(MethodCall call) answer = (_) => null;

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return answer(call);
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  final start = DateTime.utc(2026, 11, 2, 18, 30);
  DateTime at(int seconds) => start.add(Duration(seconds: seconds));
  final exercise = HealthExercise(
    id: 'strokesplit-1',
    start: start,
    end: at(600),
    title: 'Seerunde x3',
    meters: 2000.5,
    kilocalories: 120,
    heartRate: [
      HealthSeries(
        id: 'strokesplit-1-heartRate-0',
        samples: [HealthSample(at(1), 140), HealthSample(at(2), 141)],
      ),
    ],
    laps: [HealthLap(start: start, end: at(300), meters: 1000)],
    segments: [
      HealthSegment(start: start, end: at(100), type: HealthSegmentType.rowing),
      HealthSegment(
        start: at(100),
        end: at(130),
        type: HealthSegmentType.pause,
      ),
    ],
  );

  test('sends an exercise with times in milliseconds', () async {
    await ChannelHealthPlatform().write(exercise, version: 7);

    final ms = start.millisecondsSinceEpoch;
    expect(calls.single.method, 'writeSession');
    expect(calls.single.arguments, {
      'id': 'strokesplit-1',
      'version': 7,
      'start': ms,
      'end': ms + 600000,
      'title': 'Seerunde x3',
      'meters': 2000.5,
      'kilocalories': 120.0,
      'heartRate': [
        {
          'id': 'strokesplit-1-heartRate-0',
          'start': ms + 1000,
          'end': ms + 3000,
          'samples': [
            [ms + 1000, 140.0],
            [ms + 2000, 141.0],
          ],
        },
      ],
      'power': <Object?>[],
      'speed': <Object?>[],
      'laps': [
        [ms, ms + 300000, 1000.0],
      ],
      'segments': [
        [ms, ms + 100000, 'rowing'],
        [ms + 100000, ms + 130000, 'pause'],
      ],
    });
  });

  test('turns a refusal of the platform into its reason', () async {
    answer = (_) =>
        throw PlatformException(code: 'permission', message: 'not permitted');
    await expectLater(
      ChannelHealthPlatform().write(exercise, version: 1),
      throwsA(
        isA<HealthException>().having(
          (e) => e.reason,
          'reason',
          HealthFailure.permission,
        ),
      ),
    );
    answer = (_) => throw PlatformException(code: 'odd');
    await expectLater(
      ChannelHealthPlatform().write(exercise, version: 1),
      throwsA(
        isA<HealthException>().having(
          (e) => e.reason,
          'reason',
          HealthFailure.failed,
        ),
      ),
    );
  });

  test('asks for permissions by name and reads the status', () async {
    answer = (call) => switch (call.method) {
      'status' => 'updateRequired',
      'requestPermissions' => ['exercise', 'heartRate', 'unknown'],
      _ => null,
    };
    final platform = ChannelHealthPlatform();
    expect(await platform.status(), HealthStatus.updateRequired);
    expect(
      await platform.requestPermissions({
        HealthKind.exercise,
        HealthKind.heartRate,
      }),
      {HealthKind.exercise, HealthKind.heartRate},
    );
    expect(calls.last.arguments, ['exercise', 'heartRate']);
  });

  test('knows when Health Connect opened it for the privacy notice', () async {
    answer = (call) => call.method == 'launchAction' ? 'privacy' : null;
    final platform = ChannelHealthPlatform();
    expect(await platform.openedForPrivacy(), isTrue);

    final requests = platform.privacyRequests.first;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          ChannelHealthPlatform.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('launchAction', 'privacy'),
          ),
          (_) {},
        );
    await requests;
  });
}
