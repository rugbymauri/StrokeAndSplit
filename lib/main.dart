import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/aergrow_app.dart';
import 'app/app_language.dart';
import 'app/font_licenses.dart';
import 'data/db/database.dart';
import 'data/sessions/session_providers.dart';
import 'data/sessions/session_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  final db = AppDatabase.local();
  // Sessions still recording were cut off when the app ended last time.
  await SessionRepository(db).recoverInterrupted();
  // Read before the first frame, so it already shows the chosen language.
  final languages = await PreferencesLanguageStore.open();
  runApp(ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db), languageStoreProvider.overrideWithValue(languages)],
    child: const AergRowApp(),
  ));
}
