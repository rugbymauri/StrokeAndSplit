import 'dart:io';

/// Name of the database file (`<name>.sqlite`) the app opens.
const databaseName = 'strokesplit';

/// Name of the database file from before the app was renamed from AergRow.
const legacyDatabaseName = 'aergrow';

/// SQLite files that belong to a database next to the main file.
const _companionSuffixes = ['-wal', '-shm', '-journal'];

/// Takes over the database of the app from before the rename (Design D2):
/// renames `aergrow.sqlite` in [directory], together with its `-wal`, `-shm`
/// and `-journal` files, to `strokesplit.sqlite` when there is no
/// `strokesplit.sqlite` yet. Returns whether a database was taken over.
///
/// The main file is renamed last, so an interrupted takeover is completed on
/// the next start.
Future<bool> adoptLegacyDatabase(Directory directory) async {
  File file(String name, [String suffix = '']) => File('${directory.path}${Platform.pathSeparator}$name.sqlite$suffix');

  final legacy = file(legacyDatabaseName);
  if (await file(databaseName).exists() || !await legacy.exists()) return false;
  for (final suffix in _companionSuffixes) {
    final companion = file(legacyDatabaseName, suffix);
    if (await companion.exists()) await companion.rename(file(databaseName, suffix).path);
  }
  await legacy.rename(file(databaseName).path);
  return true;
}
