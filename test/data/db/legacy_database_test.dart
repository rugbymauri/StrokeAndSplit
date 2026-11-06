import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strokesplit/data/db/database.dart';
import 'package:strokesplit/data/db/legacy_database.dart';
import 'package:strokesplit/data/sources/erg_source.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('strokesplit-db');
    addTearDown(() => directory.delete(recursive: true));
  });

  File file(String name) => File('${directory.path}/$name');

  test(
    'takes over the database from before the rename with its sessions',
    () async {
      final old = AppDatabase(NativeDatabase(file('aergrow.sqlite')));
      await old
          .into(old.sessions)
          .insert(
            SessionsCompanion.insert(
              startedAt: DateTime(2026, 10, 15, 18, 30),
              status: SessionStatus.complete,
              source: ErgSourceKind.pm5,
            ),
          );
      await old.close();

      expect(await adoptLegacyDatabase(directory), isTrue);

      expect(file('aergrow.sqlite').existsSync(), isFalse);
      final db = AppDatabase(NativeDatabase(file('strokesplit.sqlite')));
      addTearDown(db.close);
      expect(await db.select(db.sessions).get(), hasLength(1));
    },
  );

  test('moves the -wal and -shm files along', () async {
    for (final name in [
      'aergrow.sqlite',
      'aergrow.sqlite-wal',
      'aergrow.sqlite-shm',
    ]) {
      file(name).writeAsStringSync(name);
    }

    expect(await adoptLegacyDatabase(directory), isTrue);

    expect(file('strokesplit.sqlite').readAsStringSync(), 'aergrow.sqlite');
    expect(
      file('strokesplit.sqlite-wal').readAsStringSync(),
      'aergrow.sqlite-wal',
    );
    expect(
      file('strokesplit.sqlite-shm').readAsStringSync(),
      'aergrow.sqlite-shm',
    );
    expect(
      directory.listSync().map((e) => e.uri.pathSegments.last),
      isNot(contains(startsWith('aergrow'))),
    );
  });

  test(
    'keeps an existing strokesplit database and leaves the old one alone',
    () async {
      file('aergrow.sqlite').writeAsStringSync('old');
      file('strokesplit.sqlite').writeAsStringSync('new');

      expect(await adoptLegacyDatabase(directory), isFalse);

      expect(file('strokesplit.sqlite').readAsStringSync(), 'new');
      expect(file('aergrow.sqlite').readAsStringSync(), 'old');
    },
  );

  test('does nothing without an old database', () async {
    expect(await adoptLegacyDatabase(directory), isFalse);
    expect(directory.listSync(), isEmpty);
  });
}
