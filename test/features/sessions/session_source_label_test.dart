import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/sources/erg_source.dart';
import 'package:strokesplit/features/sessions/session_summary_screen.dart';
import 'package:strokesplit/l10n/l10n.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  Future<String> label(
    ErgSourceKind source, {
    String? deviceName,
    ErgProtocol protocol = ErgProtocol.pm5,
    String language = 'de',
  }) async {
    final id = await db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            startedAt: DateTime(2026, 10, 16),
            status: SessionStatus.complete,
            source: source,
            deviceName: Value(deviceName),
            protocol: Value(protocol),
          ),
        );
    final session = await (db.select(
      db.sessions,
    )..where((s) => s.id.equals(id))).getSingle();
    return sessionSourceLabel(
      lookupAppLocalizations(Locale(language)),
      session,
    );
  }

  test('names the device of a PM5 and an FTMS session', () async {
    expect(
      await label(ErgSourceKind.pm5, deviceName: 'PM5 430000001 Row'),
      'PM5 430000001 Row',
    );
    expect(
      await label(
        ErgSourceKind.ftms,
        deviceName: 'Rower 42',
        protocol: ErgProtocol.ftms,
      ),
      'Rower 42 · FTMS',
    );
    expect(
      await label(ErgSourceKind.ftms, protocol: ErgProtocol.ftms),
      'Rudergerät · FTMS',
    );
    expect(
      await label(
        ErgSourceKind.ftms,
        protocol: ErgProtocol.ftms,
        language: 'en',
      ),
      'Rower · FTMS',
    );
  });

  test('marks simulated sessions with their protocol', () async {
    expect(await label(ErgSourceKind.simulator), 'Simulator');
    expect(
      await label(ErgSourceKind.simulator, protocol: ErgProtocol.ftms),
      'Simulator (FTMS)',
    );
    expect(await label(ErgSourceKind.replay), 'Replay');
  });
}
