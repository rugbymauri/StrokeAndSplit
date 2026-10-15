import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/aergrow_app.dart';
import 'data/db/database.dart';
import 'data/sessions/session_providers.dart';
import 'data/sessions/session_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase.local();
  // Sessions still recording were cut off when the app ended last time.
  await SessionRepository(db).recoverInterrupted();
  runApp(ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: const AergRowApp(),
  ));
}
