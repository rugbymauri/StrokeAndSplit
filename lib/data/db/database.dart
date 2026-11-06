import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:erg_protocol/erg_protocol.dart';
import 'package:path_provider/path_provider.dart';

import '../sources/erg_source.dart';
import 'database.steps.dart';
import 'legacy_database.dart';

part 'database.g.dart';

enum SessionStatus {
  /// Still being recorded, or the app ended before the session was stopped.
  recording,
  complete,

  /// Recovered after the app ended unexpectedly.
  incomplete,
}

/// What a course measures its length in.
enum CourseAxis {
  /// Length in metres.
  distance,

  /// Length in seconds of wall-clock time.
  time,
}

/// A course; its definition lives in [CourseVersions] (Design D4).
@DataClassName('CourseRow')
class Courses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get axis => textEnum<CourseAxis>()();

  /// Courses are only marked as deleted, as sessions keep pointing to them.
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

@DataClassName('CourseVersionRow')
@TableIndex(name: 'course_versions_course', columns: {#courseId, #version})
class CourseVersions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get courseId => integer().references(Courses, #id)();
  IntColumn get version => integer()();

  /// In metres or seconds, depending on the axis of the course.
  IntColumn get length => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

/// A reusable band over a fixed length, placed in courses of the same axis
/// (Change zones, Design D1).
@DataClassName('ZoneRow')
class Zones extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get axis => textEnum<CourseAxis>()();

  /// In metres or seconds, depending on [axis].
  IntColumn get length => integer()();

  // Pace per 500 m in centiseconds; at least one band is set.
  IntColumn get paceFastCs => integer().nullable()();
  IntColumn get paceSlowCs => integer().nullable()();
  IntColumn get spmMin => integer().nullable()();
  IntColumn get spmMax => integer().nullable()();

  /// Resistance level set while rowing the zone; null leaves the base level
  /// (Change resistance-control, Design D7).
  IntColumn get resistanceLevel => integer().nullable()();

  /// Zones are only marked as deleted, as course versions keep their name.
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// The resolved parts of a course version: placed zones with a copy of their
/// bands, and the free gaps between them.
@DataClassName('CourseSegmentRow')
class CourseSegments extends Table {
  IntColumn get versionId =>
      integer().references(CourseVersions, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();

  /// In the unit of the course length.
  IntColumn get length => integer()();

  // Optional bands; pace per 500 m in centiseconds.
  IntColumn get paceFastCs => integer().nullable()();
  IntColumn get paceSlowCs => integer().nullable()();
  IntColumn get spmMin => integer().nullable()();
  IntColumn get spmMax => integer().nullable()();

  /// Copy of the resistance level of the zone.
  IntColumn get resistanceLevel => integer().nullable()();

  /// The placed zone; null for a free gap and in versions from before zones
  /// that were already rowed.
  IntColumn get zoneId => integer().nullable().references(Zones, #id)();

  /// The name of the zone when the version was stored.
  TextColumn get zoneName => text().nullable()();

  @override
  Set<Column> get primaryKey => {versionId, position};
}

@DataClassName('TemplateRow')
class Templates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
}

/// The parts of a template; the app uses exactly one for now.
@DataClassName('TemplateBlockRow')
class TemplateBlocks extends Table {
  IntColumn get templateId =>
      integer().references(Templates, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  IntColumn get courseId => integer().references(Courses, #id)();

  /// Null means open: laps follow until the session is stopped.
  IntColumn get laps => integer().nullable()();

  @override
  Set<Column> get primaryKey => {templateId, position};
}

@DataClassName('SessionRow')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get status => textEnum<SessionStatus>()();
  TextColumn get source => textEnum<ErgSourceKind>()();
  TextColumn get deviceName => text().nullable()();

  /// Protocol of the raw packets; sessions before schema 4 are PM5 sessions.
  TextColumn get protocol =>
      textEnum<ErgProtocol>().withDefault(const Constant('pm5'))();

  // Summary, derived from samples and strokes when the session ends.
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  IntColumn get distanceDm => integer().withDefault(const Constant(0))();
  IntColumn get averagePaceCs => integer().nullable()();
  IntColumn get averageWatts => integer().nullable()();
  RealColumn get averageStrokeRate => real().nullable()();
  IntColumn get strokeCount => integer().withDefault(const Constant(0))();

  // Set when the session was started from a template (Design D4).
  IntColumn get templateId => integer().nullable().references(
    Templates,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The template name at the time, kept when the template is deleted.
  TextColumn get templateName => text().nullable()();
  IntColumn get courseVersionId =>
      integer().nullable().references(CourseVersions, #id)();

  /// Null for an open number of laps.
  IntColumn get plannedLaps => integer().nullable()();

  /// Set by the import; imported sessions count in no ranking (Change
  /// statistics, Design D3). Sessions before schema 5 count as recorded here.
  BoolColumn get imported => boolean().withDefault(const Constant(false))();

  // Pulse summary (Change heart-rate, Design D5); null without heart rate or,
  // for RMSSD, with fewer than two RR intervals.
  IntColumn get averageHeartRate => integer().nullable()();
  IntColumn get maxHeartRate => integer().nullable()();
  IntColumn get rmssdMs => integer().nullable()();

  // Pause summary (Change auto-pause, Design D3); sessions before schema 7 have none.
  IntColumn get pauseCount => integer().withDefault(const Constant(0))();
  IntColumn get pausedMs => integer().withDefault(const Constant(0))();

  /// When the session was last written to Health Connect (Change health-connect, Design D6); null when it
  /// was not, and for sessions before schema 8 and imported ones.
  DateTimeColumn get healthExportedAt => dateTime().nullable()();
}

/// Session-relative values per status tick (Design D6/D7).
@DataClassName('SampleRow')
@TableIndex(name: 'samples_session_time', columns: {#sessionId, #tMs})
class Samples extends Table {
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get tMs => integer()();
  IntColumn get distanceDm => integer()();
  IntColumn get paceCs => integer().nullable()();
  IntColumn get watts => integer().nullable()();
  IntColumn get strokeRate => integer().nullable()();
  IntColumn get heartRate => integer().nullable()();
  IntColumn get calories => integer().nullable()();

  /// Wall-clock time since the first notification; keeps running while the
  /// PM5 pauses its clock. Null for sessions recorded before schema 2.
  IntColumn get wallMs => integer().nullable()();

  /// Session time: the wall-clock time without the pauses of the session
  /// (Change auto-pause, Design D2). Null for sessions recorded before
  /// schema 7, which had no pauses; their session time is [wallMs].
  IntColumn get activeMs => integer().nullable()();
}

@DataClassName('StrokeRow')
@TableIndex(name: 'strokes_session_time', columns: {#sessionId, #tMs})
class Strokes extends Table {
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get tMs => integer()();
  IntColumn get distanceDm => integer()();
  IntColumn get strokeNumber => integer()();

  // Stroke details; null when the device does not report them (FTMS).
  RealColumn get driveLengthMeters => real().nullable()();
  IntColumn get driveTimeMs => integer().nullable()();
  IntColumn get recoveryTimeMs => integer().nullable()();
  RealColumn get peakForceNewtons => real().nullable()();
  RealColumn get averageForceNewtons => real().nullable()();
  IntColumn get watts => integer().nullable()();
}

/// The notifications as received, relative to the first one of the session,
/// so the session can be replayed exactly.
@DataClassName('RawPacketRow')
@TableIndex(name: 'raw_packets_session_time', columns: {#sessionId, #tMs})
class RawPackets extends Table {
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get tMs => integer()();
  TextColumn get characteristicId => text()();
  BlobColumn get bytes => blob()();
}

/// The beat-to-beat intervals of a strap (Change heart-rate, Design D4/D5),
/// each at the session time it ended.
@DataClassName('RrIntervalRow')
@TableIndex(name: 'rr_intervals_session_time', columns: {#sessionId, #tMs})
class RrIntervals extends Table {
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get tMs => integer()();
  IntColumn get rrMs => integer()();
}

/// The laps of a session on a course. The `*WallMs` times are session times
/// (Change auto-pause, Design D2): the wall clock without the pauses, which
/// sessions before schema 7 did not know, so for them it is the wall clock.
@DataClassName('LapRow')
class Laps extends Table {
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();

  /// Starting at 1.
  IntColumn get lapNo => integer()();
  IntColumn get startWallMs => integer()();
  IntColumn get endWallMs => integer()();
  IntColumn get startDistanceDm => integer()();
  IntColumn get endDistanceDm => integer()();

  /// False for a lap that was started but not finished.
  BoolColumn get complete => boolean()();

  /// Share of time within the bands, 0 to 1; null without bands.
  RealColumn get inZoneShare => real().nullable()();

  @override
  Set<Column> get primaryKey => {sessionId, lapNo};
}

/// The pauses of a session (Change auto-pause, Design D3), on the
/// wall-clock axis of its samples and raw notifications.
@DataClassName('PauseRow')
class Pauses extends Table {
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get startWallMs => integer()();
  IntColumn get endWallMs => integer()();

  @override
  Set<Column> get primaryKey => {sessionId, startWallMs};
}

@DataClassName('LapSegmentRow')
class LapSegments extends Table {
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get lapNo => integer()();
  IntColumn get position => integer()();
  IntColumn get durationMs => integer()();
  IntColumn get distanceDm => integer()();
  RealColumn get inZoneShare => real().nullable()();

  @override
  Set<Column> get primaryKey => {sessionId, lapNo, position};
}

@DriftDatabase(
  tables: [
    Sessions,
    Samples,
    Strokes,
    RawPackets,
    Courses,
    CourseVersions,
    CourseSegments,
    Zones,
    Templates,
    TemplateBlocks,
    Laps,
    LapSegments,
    RrIntervals,
    Pauses,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The database file on the device, taking over the one from before the
  /// rename (Design D2).
  factory AppDatabase.local() => AppDatabase(
    driftDatabase(
      name: databaseName,
      native: DriftNativeOptions(
        databaseDirectory: () async {
          final directory = await getApplicationDocumentsDirectory();
          await adoptLegacyDatabase(directory);
          return directory;
        },
      ),
    ),
  );

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      // Courses and templates; only additions, old sessions stay as they are.
      from1To2: (m, schema) async {
        for (final table in [
          schema.courses,
          schema.courseVersions,
          schema.courseSegments,
          schema.templates,
          schema.templateBlocks,
          schema.laps,
          schema.lapSegments,
        ]) {
          await m.createTable(table);
        }
        await m.createIndex(schema.courseVersionsCourse);
        await m.addColumn(schema.sessions, schema.sessions.templateId);
        await m.addColumn(schema.sessions, schema.sessions.templateName);
        await m.addColumn(schema.sessions, schema.sessions.courseVersionId);
        await m.addColumn(schema.sessions, schema.sessions.plannedLaps);
        await m.addColumn(schema.samples, schema.samples.wallMs);
      },
      // Reusable zones; segments with bands become zones (Change zones, Design D5).
      from2To3: (m, schema) async {
        await m.createTable(schema.zones);
        await m.addColumn(schema.courseSegments, schema.courseSegments.zoneId);
        await m.addColumn(
          schema.courseSegments,
          schema.courseSegments.zoneName,
        );
        await migrateSegmentsToZones(m.database);
      },
      // FTMS rowers (Change device-types, Design D9): SQLite cannot drop NOT NULL in place,
      // so the strokes table is rebuilt with its rows; old sessions are PM5 sessions.
      from3To4: (m, schema) async {
        await m.alterTable(TableMigration(schema.strokes));
        await m.addColumn(schema.sessions, schema.sessions.protocol);
      },
      // Imported sessions leave the rankings (Change statistics, Design D3);
      // existing sessions count as recorded on this device.
      from4To5: (m, schema) async {
        await m.addColumn(schema.sessions, schema.sessions.imported);
      },
      // Heart rate straps (Change heart-rate, Design D5); existing sessions
      // keep no pulse summary.
      from5To6: (m, schema) async {
        await m.addColumn(schema.sessions, schema.sessions.averageHeartRate);
        await m.addColumn(schema.sessions, schema.sessions.maxHeartRate);
        await m.addColumn(schema.sessions, schema.sessions.rmssdMs);
        await m.createTable(schema.rrIntervals);
        await m.createIndex(schema.rrIntervalsSessionTime);
      },
      // Auto-pause (Change auto-pause, Design D3); existing sessions keep
      // their times and have no pauses.
      from6To7: (m, schema) async {
        await m.addColumn(schema.sessions, schema.sessions.pauseCount);
        await m.addColumn(schema.sessions, schema.sessions.pausedMs);
        await m.addColumn(schema.samples, schema.samples.activeMs);
        await m.createTable(schema.pauses);
      },
      // Health Connect (Change health-connect, Design D6); existing sessions count as not written.
      from7To8: (m, schema) async {
        await m.addColumn(schema.sessions, schema.sessions.healthExportedAt);
      },
      // Resistance level per zone and its copy in course segments (Change resistance-control, D7).
      from8To9: (m, schema) async {
        await m.addColumn(schema.zones, schema.zones.resistanceLevel);
        await m.addColumn(
          schema.courseSegments,
          schema.courseSegments.resistanceLevel,
        );
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// Turns every segment with a band into a zone named after its course and
/// position. Segments of the newest version of a course are placed zones;
/// older versions only keep the name, as they no longer change.
Future<void> migrateSegmentsToZones(GeneratedDatabase db) async {
  final courses = await db
      .customSelect('SELECT id, name, axis FROM courses')
      .get();
  for (final course in courses) {
    final courseId = course.read<int>('id');
    final versions = await db
        .customSelect(
          'SELECT id FROM course_versions WHERE course_id = ? ORDER BY version DESC',
          variables: [Variable.withInt(courseId)],
        )
        .get();
    for (final (i, version) in versions.indexed) {
      final versionId = version.read<int>('id');
      final segments = await db
          .customSelect(
            'SELECT position, length, pace_fast_cs, pace_slow_cs, spm_min, spm_max FROM course_segments '
            'WHERE version_id = ? AND (pace_fast_cs IS NOT NULL OR spm_min IS NOT NULL) ORDER BY position',
            variables: [Variable.withInt(versionId)],
          )
          .get();
      for (final segment in segments) {
        final position = segment.read<int>('position');
        final name = '${course.read<String>('name')} ${position + 1}';
        int? zoneId;
        if (i == 0) {
          zoneId = await db.customInsert(
            'INSERT INTO zones (name, axis, length, pace_fast_cs, pace_slow_cs, spm_min, spm_max) '
            'VALUES (?, ?, ?, ?, ?, ?, ?)',
            variables: [
              Variable.withString(name),
              Variable.withString(course.read<String>('axis')),
              Variable.withInt(segment.read<int>('length')),
              Variable(segment.read<int?>('pace_fast_cs')),
              Variable(segment.read<int?>('pace_slow_cs')),
              Variable(segment.read<int?>('spm_min')),
              Variable(segment.read<int?>('spm_max')),
            ],
          );
        }
        await db.customUpdate(
          'UPDATE course_segments SET zone_id = ?, zone_name = ? WHERE version_id = ? AND position = ?',
          variables: [
            Variable(zoneId),
            Variable.withString(name),
            Variable.withInt(versionId),
            Variable.withInt(position),
          ],
        );
      }
    }
  }
}
