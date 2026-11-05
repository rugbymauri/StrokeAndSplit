import 'dart:async';

import 'package:strokesplit/data/sources/ble/ble_transport.dart';
import 'package:strokesplit/data/sources/ble/heart_rate_transport.dart';
import 'package:strokesplit/data/sources/ble/rower_connector.dart';
import 'package:strokesplit/data/sources/resistance_control.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

const _pm5 = FoundRower(id: 'C0:00:00:00:00:01', name: 'PM5 430000001 Row');
const _ftms = FoundRower(id: 'AA:BB:CC:DD:EE:FF', name: 'Stroke & Split FTMS', protocol: ErgProtocol.ftms);

class _FakeConnection implements GattConnection {
  _FakeConnection(this.characteristics);

  @override
  final Set<String> characteristics;

  final _notifications = StreamController<(String, List<int>)>.broadcast(sync: true);
  final subscribed = <String>[];
  /// Writes as `id:bytes`, e.g. `2ad9:[0]`.
  final writes = <String>[];
  var disconnected = false;

  /// Called on every write, e.g. to answer on the control point.
  void Function(String id, List<int> bytes)? onWrite;

  /// Called on every subscription, e.g. to send the first status.
  void Function(String id)? onSubscribe;

  void notify(String id, List<int> bytes) => _notifications.add((id, bytes));

  @override
  Stream<(String, List<int>)> get notifications => _notifications.stream;

  @override
  Future<void> subscribe(String id) async {
    subscribed.add(id);
    onSubscribe?.call(id);
  }

  @override
  Future<void> write(String id, List<int> bytes) async {
    if (disconnected) throw StateError('disconnected');
    writes.add('$id:$bytes');
    onWrite?.call(id, bytes);
  }

  /// Values returned by [read].
  final values = <String, List<int>>{};

  @override
  Future<List<int>> read(String id) async => values[id] ?? (throw StateError('no value for $id'));

  @override
  Future<void> get lost => Completer<void>().future;

  @override
  Future<void> disconnect() async => disconnected = true;
}

const _pm5Characteristics = {'0031', '0032', '0033', '0034', '0035', '0036', '003d'};

/// A PM5 that sends its first Additional Status with [ergType], or none.
_FakeConnection _pm5Connection(int? ergType, {Set<String> characteristics = _pm5Characteristics}) {
  final connection = _FakeConnection(characteristics);
  connection.onSubscribe = (id) {
    if (id == Pm5Characteristics.additionalStatus && ergType != null) {
      scheduleMicrotask(() => connection.notify(id, [...List.filled(16, 0), ergType]));
    }
  };
  return connection;
}

/// An FTMS rower; [controlResult] is its answer to Request Control, null for
/// no answer, and without [controlPoint] it has none.
///
/// With [resistance] it reports features and level range like the Domyos
/// Woodrower: level 1 to 15, settable.
_FakeConnection _ftmsConnection({
  bool controlPoint = true,
  int? controlResult = 0x01,
  bool rowerData = true,
  bool resistance = false,
}) {
  final connection = _FakeConnection({
    FtmsIds.feature,
    if (rowerData) FtmsIds.rowerData,
    if (controlPoint) FtmsIds.controlPoint,
    FtmsIds.machineStatus,
    if (resistance) FtmsIds.supportedResistanceLevelRange,
  });
  connection.values[FtmsIds.feature] = [0xa6, 0x56, 0x00, 0x00, if (resistance) 0x04 else 0x00, 0x00, 0x00, 0x00];
  if (resistance) connection.values[FtmsIds.supportedResistanceLevelRange] = [0x0a, 0x00, 0x96, 0x00, 0x0a, 0x00];
  connection.onWrite = (id, bytes) {
    if (id == FtmsIds.controlPoint && controlResult != null) {
      scheduleMicrotask(() => connection.notify(id, [0x80, bytes.first, bytes.first == 0x00 ? controlResult : 0x01]));
    }
  };
  return connection;
}

/// Sets up [connection] and returns the link or the error.
(RowerLink?, Object?, List<String>) _setUp(_FakeConnection connection, FoundRower rower) {
  RowerLink? link;
  Object? error;
  final warnings = <String>[];
  fakeAsync((async) {
    setUpRower(connection, rower, onWarning: warnings.add)
        .then<void>((l) => link = l, onError: (Object e) => error = e);
    async.elapse(const Duration(seconds: 5));
  });
  return (link, error, warnings);
}

void main() {
  group('PM5', () {
    test('sets the sample rate and subscribes to the rowing data of a RowErg', () {
      final connection = _pm5Connection(0);
      final (link, error, _) = _setUp(connection, _pm5);

      expect(error, isNull);
      expect(link, isNotNull);
      expect(connection.writes, ['${Pm5Characteristics.sampleRate}:[${Pm5Characteristics.sampleRate250ms}]']);
      expect(connection.subscribed, Pm5Characteristics.subscribed);
      expect(connection.disconnected, isFalse);
    });

    for (final (erg, code, expected) in [
      ('SkiErg', 143, RowerConnectError.skiErg),
      ('BikeErg', 192, RowerConnectError.bikeErg),
    ]) {
      test('disconnects from a PM5 on a $erg', () {
        final connection = _pm5Connection(code);
        final (link, error, _) = _setUp(connection, _pm5);

        expect(link, isNull);
        expect(error, isA<RowerConnectException>().having((e) => e.error, 'error', expected));
        expect((error! as RowerConnectException).notARower, isTrue);
        expect(connection.disconnected, isTrue);
      });
    }

    test('lets a PM5 with an unknown erg type through', () {
      final (link, error, _) = _setUp(_pm5Connection(99), _pm5);

      expect(error, isNull);
      expect(link, isNotNull);
    });

    test('lets a PM5 through that sends no status within 3 seconds', () {
      final connection = _pm5Connection(null);
      RowerLink? link;
      fakeAsync((async) {
        setUpRower(connection, _pm5).then((l) => link = l);
        async.elapse(const Duration(milliseconds: 2900));
        expect(link, isNull);
        async.elapse(const Duration(milliseconds: 200));
        expect(link, isNotNull);
      });
    });

    test('rejects a device without rowing service', () {
      final connection = _FakeConnection({});
      final (_, error, _) = _setUp(connection, _pm5);

      expect(error, isA<RowerConnectException>().having((e) => e.error, 'error', RowerConnectError.noRowingService));
      expect((error! as RowerConnectException).notARower, isFalse);
      expect(connection.disconnected, isTrue);
    });

    test('forwards only the rowing data', () {
      final connection = _pm5Connection(0);
      final (link, _, _) = _setUp(connection, _pm5);
      final received = <String>[];
      link!.notifications.listen((n) => received.add(n.$1));

      connection
        ..notify('0031', [1])
        ..notify('2ad1', [1])
        ..notify('0035', [1])
        ..notify('003d', [1]);

      expect(received, ['0031', '0035', '003d']);
    });

    test('connects to a PM5 without force curve and subscribes to the rest', () {
      final connection = _pm5Connection(0, characteristics: _pm5Characteristics.difference({'003d'}));
      final (link, error, _) = _setUp(connection, _pm5);

      expect(error, isNull);
      expect(link, isNotNull);
      expect(connection.subscribed, Pm5Characteristics.subscribed.where((id) => id != '003d'));
    });
  });

  group('FTMS', () {
    test('requests control and starts the rower', () {
      final connection = _ftmsConnection();
      final (link, error, warnings) = _setUp(connection, _ftms);

      expect(error, isNull);
      expect(link, isNotNull);
      expect(connection.subscribed, [FtmsIds.rowerData, FtmsIds.controlPoint]);
      expect(connection.writes, ['2ad9:[0]', '2ad9:[7]']);
      expect(warnings, isEmpty);
    });

    test('connects to a rower without control point without writing', () {
      final connection = _ftmsConnection(controlPoint: false);
      final (link, _, _) = _setUp(connection, _ftms);

      expect(link, isNotNull);
      expect(connection.subscribed, [FtmsIds.rowerData]);
      expect(connection.writes, isEmpty);
    });

    test('stays connected when the rower refuses control', () {
      final connection = _ftmsConnection(controlResult: 0x05);
      final (link, _, warnings) = _setUp(connection, _ftms);

      expect(link, isNotNull);
      expect(connection.writes, ['2ad9:[0]']);
      expect(connection.disconnected, isFalse);
      expect(warnings.single, contains('refused'));
    });

    test('stays connected when the rower does not answer within 2 seconds', () {
      final connection = _ftmsConnection(controlResult: null);
      RowerLink? link;
      fakeAsync((async) {
        setUpRower(connection, _ftms).then((l) => link = l);
        async.elapse(const Duration(milliseconds: 1900));
        expect(link, isNull);
        async.elapse(const Duration(milliseconds: 200));
        expect(link, isNotNull);
      });
      expect(connection.writes, ['2ad9:[0]']);
    });

    test('stays connected when writing to the control point fails', () {
      final connection = _ftmsConnection()..onWrite = (_, _) => throw StateError('write failed');
      final (link, _, warnings) = _setUp(connection, _ftms);

      expect(link, isNotNull);
      expect(warnings.single, contains('write failed'));
    });

    test('rejects an FTMS machine without rower data', () {
      final connection = _ftmsConnection(rowerData: false);
      final (_, error, _) = _setUp(connection, _ftms);

      expect(error, isA<RowerConnectException>().having((e) => e.error, 'error', RowerConnectError.noRowerData));
      expect((error! as RowerConnectException).notARower, isTrue);
      expect(connection.disconnected, isTrue);
    });

    test('sends neither reset nor stop when disconnecting', () {
      final connection = _ftmsConnection();
      final (link, _, _) = _setUp(connection, _ftms);
      fakeAsync((async) {
        link!.disconnect();
        async.flushMicrotasks();
      });

      expect(connection.disconnected, isTrue);
      expect(connection.writes, isNot(anyOf(contains('2ad9:[1]'), contains('2ad9:[8]'))));
    });

    test('forwards only the rower data', () {
      final connection = _ftmsConnection();
      final (link, _, _) = _setUp(connection, _ftms);
      final received = <String>[];
      link!.notifications.listen((n) => received.add(n.$1));

      connection
        ..notify(FtmsIds.controlPoint, [0x80, 0x07, 0x01])
        ..notify(FtmsIds.rowerData, [1]);

      expect(received, [FtmsIds.rowerData]);
    });
  });

  group('FTMS resistance', () {
    /// Answers Set Target Resistance Level with [results] in turn, everything
    /// else with success; a null result is no answer.
    void answer(_FakeConnection connection, List<int?> results) {
      connection.onWrite = (id, bytes) {
        if (id != FtmsIds.controlPoint) return;
        final result = bytes.first == 0x04 ? results.removeAt(0) : 0x01;
        if (result != null) scheduleMicrotask(() => connection.notify(id, [0x80, bytes.first, result]));
      };
    }

    ResistanceResult? setLevel(RowerLink link, int level) {
      ResistanceResult? result;
      fakeAsync((async) {
        link.resistanceControl!.setLevel(level).then((r) => result = r);
        async.elapse(const Duration(seconds: 10));
      });
      return result;
    }

    test('offers the level range of a Domyos Woodrower', () {
      final connection = _ftmsConnection(resistance: true);
      final (link, _, warnings) = _setUp(connection, _ftms);

      expect(link!.resistanceControl!.range, const ResistanceRange(min: 1, max: 15));
      expect(warnings, isEmpty);
    });

    test('offers nothing without the target setting', () {
      final connection = _ftmsConnection(resistance: true);
      connection.values[FtmsIds.feature] = [0xa6, 0x56, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
      final (link, _, _) = _setUp(connection, _ftms);

      expect(link!.resistanceControl, isNull);
    });

    test('offers nothing without level range or control point', () {
      expect(_setUp(_ftmsConnection(), _ftms).$1!.resistanceControl, isNull);
      expect(_setUp(_ftmsConnection(resistance: true, controlPoint: false), _ftms).$1!.resistanceControl, isNull);
    });

    test('offers nothing for a range that makes no sense', () {
      final connection = _ftmsConnection(resistance: true);
      connection.values[FtmsIds.supportedResistanceLevelRange] = [0x0a, 0x00, 0x96, 0x00, 0x00, 0x00];
      final (link, _, warnings) = _setUp(connection, _ftms);

      expect(link!.resistanceControl, isNull);
      expect(warnings.single, contains('range'));
    });

    test('a PM5 offers nothing', () => expect(_setUp(_pm5Connection(0), _pm5).$1!.resistanceControl, isNull));

    test('sets level 6 as one byte in tenths', () {
      final connection = _ftmsConnection(resistance: true);
      final (link, _, _) = _setUp(connection, _ftms);
      answer(connection, [0x01]);

      expect(setLevel(link!, 6), ResistanceResult.accepted);
      expect(connection.writes.last, '2ad9:[4, 60]');
    });

    test('a refusal is reported', () {
      final connection = _ftmsConnection(resistance: true);
      final (link, _, _) = _setUp(connection, _ftms);
      answer(connection, [0x04]);

      expect(setLevel(link!, 6), ResistanceResult.rejected);
    });

    test('no answer within 2 seconds is reported', () {
      final connection = _ftmsConnection(resistance: true);
      final (link, _, _) = _setUp(connection, _ftms);
      answer(connection, [null]);

      expect(setLevel(link!, 6), ResistanceResult.noAnswer);
    });

    test('a failed write is no answer', () {
      final connection = _ftmsConnection(resistance: true);
      final (link, _, _) = _setUp(connection, _ftms);
      connection.onWrite = (_, _) => throw StateError('write failed');

      expect(setLevel(link!, 6), ResistanceResult.noAnswer);
    });

    test('falls back to 16 bits on an invalid parameter and stays there', () {
      final connection = _ftmsConnection(resistance: true);
      final (link, _, _) = _setUp(connection, _ftms);
      answer(connection, [0x03, 0x01, 0x01]);

      expect(setLevel(link!, 6), ResistanceResult.accepted);
      expect(setLevel(link, 7), ResistanceResult.accepted);
      expect(connection.writes.skip(2), ['2ad9:[4, 60]', '2ad9:[4, 60, 0]', '2ad9:[4, 70, 0]']);
    });

    test('requests control again when it was taken', () {
      final connection = _ftmsConnection(resistance: true);
      final (link, _, _) = _setUp(connection, _ftms);
      answer(connection, [0x05, 0x01]);

      expect(setLevel(link!, 6), ResistanceResult.accepted);
      expect(connection.writes.skip(2), ['2ad9:[4, 60]', '2ad9:[0]', '2ad9:[4, 60]']);
    });

    test('sends one command after the other', () {
      final connection = _ftmsConnection(resistance: true);
      final (link, _, _) = _setUp(connection, _ftms);
      answer(connection, [0x01, 0x01]);
      final results = <ResistanceResult>[];
      fakeAsync((async) {
        link!.resistanceControl!.setLevel(6).then(results.add);
        link.resistanceControl!.setLevel(7).then(results.add);
        async.flushMicrotasks();
        expect(connection.writes.skip(2), ['2ad9:[4, 60]', '2ad9:[4, 70]']);
      });
      expect(results, [ResistanceResult.accepted, ResistanceResult.accepted]);
    });
  });

  group('heart rate strap', () {
    (HeartRateLink?, Object?) setUpStrap(_FakeConnection connection) {
      HeartRateLink? link;
      Object? error;
      fakeAsync((async) {
        setUpHeartRateMonitor(connection).then<void>((l) => link = l, onError: (Object e) => error = e);
        async.flushMicrotasks();
      });
      return (link, error);
    }

    test('subscribes to the heart rate measurement', () {
      final connection = _FakeConnection({HeartRateIds.measurement, '2a38'});
      final (link, error) = setUpStrap(connection);

      expect(error, isNull);
      expect(link, isNotNull);
      expect(connection.subscribed, [HeartRateIds.measurement]);
      expect(connection.writes, isEmpty);
      expect(connection.disconnected, isFalse);
    });

    test('forwards only the heart rate measurement', () {
      final connection = _FakeConnection({HeartRateIds.measurement, '2a38'});
      final (link, _) = setUpStrap(connection);
      final received = <String>[];
      link!.notifications.listen((n) => received.add('${n.$1}:${n.$2}'));

      connection
        ..notify('2a38', [1])
        ..notify(HeartRateIds.measurement, [0x10, 72, 0x00, 0x04]);

      expect(received, ['2a37:[16, 72, 0, 4]']);
    });

    test('rejects a device without heart rate service and disconnects', () {
      final connection = _FakeConnection(_pm5Characteristics);
      final (link, error) = setUpStrap(connection);

      expect(link, isNull);
      expect(
        error,
        isA<HeartRateConnectException>().having((e) => e.error, 'error', HeartRateConnectError.noHeartRateService),
      );
      expect(connection.disconnected, isTrue);
    });

    test('reports a failed subscription as a failed connection', () {
      final connection = _FakeConnection({HeartRateIds.measurement})
        ..onSubscribe = (_) => throw StateError('gatt error');
      final (_, error) = setUpStrap(connection);

      expect(error, isA<HeartRateConnectException>().having((e) => e.error, 'error', HeartRateConnectError.failed));
      expect(connection.disconnected, isTrue);
    });
  });
}
