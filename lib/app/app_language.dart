import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Languages of the user interface, in the order of the language choice.
///
/// A new language needs its ARB file and a value here (Design D2).
enum AppLanguage {
  de('Deutsch'),
  en('English');

  const AppLanguage(this.nativeName);

  /// Name of the language in the language itself.
  final String nativeName;

  Locale get locale => Locale(name);

  /// The language stored as [code]; German when there is none or it is no
  /// longer offered.
  static AppLanguage parse(String? code) => values.asNameMap()[code] ?? de;
}

/// Where the chosen language is kept.
abstract interface class LanguageStore {
  String? read();

  Future<void> write(String code);
}

/// Keeps the language in the shared preferences of the platform.
class PreferencesLanguageStore implements LanguageStore {
  PreferencesLanguageStore._(this._preferences);

  static const _key = 'language';

  final SharedPreferencesWithCache _preferences;

  static Future<PreferencesLanguageStore> open() async {
    const options = SharedPreferencesWithCacheOptions(allowList: {_key});
    return PreferencesLanguageStore._(await SharedPreferencesWithCache.create(cacheOptions: options));
  }

  @override
  String? read() => _preferences.getString(_key);

  @override
  Future<void> write(String code) => _preferences.setString(_key, code);
}

/// Keeps the language in memory only; used in tests and until `main` has
/// opened the preferences.
class MemoryLanguageStore implements LanguageStore {
  MemoryLanguageStore([this._code]);

  String? _code;

  @override
  String? read() => _code;

  @override
  Future<void> write(String code) async => _code = code;
}

/// Where the language is kept; `main` sets the preferences.
final languageStoreProvider = Provider<LanguageStore>((ref) => MemoryLanguageStore());

/// The language of the user interface.
final appLanguageProvider = NotifierProvider<AppLanguageNotifier, AppLanguage>(AppLanguageNotifier.new);

class AppLanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.parse(ref.watch(languageStoreProvider).read());

  /// Switches the user interface to [language] and remembers it.
  Future<void> choose(AppLanguage language) async {
    state = language;
    await ref.read(languageStoreProvider).write(language.name);
  }
}
