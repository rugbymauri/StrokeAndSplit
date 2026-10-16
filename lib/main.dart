import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/aergrow_app.dart';
import 'app/app_language.dart';
import 'app/font_licenses.dart';
import 'data/db/database.dart';
import 'data/sessions/session_providers.dart';
import 'data/sessions/session_repository.dart';
import 'data/sources/heart_rate_choice.dart';
import 'data/sources/rower_choice.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  final db = AppDatabase.local();
  // Sessions still recording were cut off when the app ended last time.
  await SessionRepository(db).recoverInterrupted();
  // Read before the first frame, so it already shows the chosen language.
  final languages = await PreferencesLanguageStore.open();
  final rower = await PreferencesRowerChoiceStore.open();
  final heartRateMonitor = await PreferencesHeartRateMonitorStore.open();
  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      languageStoreProvider.overrideWithValue(languages),
      rowerChoiceStoreProvider.overrideWithValue(rower),
      heartRateMonitorStoreProvider.overrideWithValue(heartRateMonitor),
    ],
    child: const AergRowApp(),
  ));
}
