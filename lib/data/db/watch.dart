import 'package:drift/drift.dart';

extension WatchTables on GeneratedDatabase {
  /// [load] now and again after every change to [tables].
  ///
  /// Changes made while the listener is paused, e.g. because Riverpod
  /// pauses providers of covered screens, are delivered once it resumes; a
  /// watched `SELECT 1` lost them and the list stayed stale.
  Stream<T> watchTables<T>(
    Iterable<TableInfo> tables,
    Future<T> Function() load,
  ) async* {
    yield await load();
    await for (final _ in tableUpdates(TableUpdateQuery.onAllTables(tables))) {
      yield await load();
    }
  }
}
