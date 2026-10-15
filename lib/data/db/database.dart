import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../sources/erg_source.dart';

part 'database.g.dart';

enum SessionStatus {
  /// Still being recorded, or the app ended before the session was stopped.
  recording,
  complete,

  /// Recovered after the app ended unexpectedly.
  incomplete,
}

@DataClassName('SessionRow')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get status => textEnum<SessionStatus>()();
  TextColumn get source => textEnum<ErgSourceKind>()();
  TextColumn get deviceName => text().nullable()();

  // Summary, derived from samples and strokes when the session ends.
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  IntColumn get distanceDm => integer().withDefault(const Constant(0))();
  IntColumn get averagePaceCs => integer().nullable()();
  IntColumn get averageWatts => integer().nullable()();
  RealColumn get averageStrokeRate => real().nullable()();
  IntColumn get strokeCount => integer().withDefault(const Constant(0))();
}

/// Session-relative values per status tick (Design D6/D7).
@DataClassName('SampleRow')
@TableIndex(name: 'samples_session_time', columns: {#sessionId, #tMs})
class Samples extends Table {
  IntColumn get sessionId => integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get tMs => integer()();
  IntColumn get distanceDm => integer()();
  IntColumn get paceCs => integer().nullable()();
  IntColumn get watts => integer().nullable()();
  IntColumn get strokeRate => integer().nullable()();
  IntColumn get heartRate => integer().nullable()();
  IntColumn get calories => integer().nullable()();
}

@DataClassName('StrokeRow')
@TableIndex(name: 'strokes_session_time', columns: {#sessionId, #tMs})
class Strokes extends Table {
  IntColumn get sessionId => integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get tMs => integer()();
  IntColumn get distanceDm => integer()();
  IntColumn get strokeNumber => integer()();
  RealColumn get driveLengthMeters => real()();
  IntColumn get driveTimeMs => integer()();
  IntColumn get recoveryTimeMs => integer()();
  RealColumn get peakForceNewtons => real()();
  RealColumn get averageForceNewtons => real()();
  IntColumn get watts => integer().nullable()();
}

/// The notifications as received, relative to the first one of the session,
/// so the session can be replayed exactly.
@DataClassName('RawPacketRow')
@TableIndex(name: 'raw_packets_session_time', columns: {#sessionId, #tMs})
class RawPackets extends Table {
  IntColumn get sessionId => integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get tMs => integer()();
  TextColumn get characteristicId => text()();
  BlobColumn get bytes => blob()();
}

@DriftDatabase(tables: [Sessions, Samples, Strokes, RawPackets])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The database file on the device.
  factory AppDatabase.local() => AppDatabase(driftDatabase(name: 'aergrow'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
