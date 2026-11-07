import 'package:drift/drift.dart';
import 'package:strokesplit/data/db/database.dart';

/// Stores [session] rowing the course versions [courseVersionIds] in their
/// order, as the recorder does (Change workout-course-chain, Design D3).
Future<int> insertSession(
  AppDatabase db,
  SessionsCompanion session, {
  List<int> courseVersionIds = const [],
}) {
  return db.transaction(() async {
    final id = await db.into(db.sessions).insert(session);
    var firstSegment = 0;
    for (final (position, versionId) in courseVersionIds.indexed) {
      await db
          .into(db.sessionCourses)
          .insert(
            SessionCoursesCompanion.insert(
              sessionId: id,
              position: position,
              courseVersionId: versionId,
              firstSegment: firstSegment,
            ),
          );
      final segments = await (db.select(
        db.courseSegments,
      )..where((s) => s.versionId.equals(versionId))).get();
      firstSegment += segments.length;
    }
    return id;
  });
}

/// The course versions session [id] rows, in their order.
Future<List<int>> sessionVersionIds(AppDatabase db, int id) async => [
  for (final c
      in await (db.select(db.sessionCourses)
            ..where((c) => c.sessionId.equals(id))
            ..orderBy([(c) => OrderingTerm.asc(c.position)]))
          .get())
    c.courseVersionId,
];
