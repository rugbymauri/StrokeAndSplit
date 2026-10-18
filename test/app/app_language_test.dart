import 'package:strokesplit/app/app_language.dart';
import 'package:strokesplit/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container(LanguageStore store) {
  final container = ProviderContainer(overrides: [languageStoreProvider.overrideWithValue(store)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('is German without a stored language', () {
    expect(_container(MemoryLanguageStore()).read(appLanguageProvider), AppLanguage.de);
  });

  test('starts with the stored language', () {
    expect(_container(MemoryLanguageStore('en')).read(appLanguageProvider), AppLanguage.en);
  });

  test('falls back to German for a language no longer offered', () {
    expect(_container(MemoryLanguageStore('fr')).read(appLanguageProvider), AppLanguage.de);
  });

  test('remembers the chosen language', () async {
    final store = MemoryLanguageStore();
    final container = _container(store);

    await container.read(appLanguageProvider.notifier).choose(AppLanguage.en);

    expect(container.read(appLanguageProvider), AppLanguage.en);
    expect(store.read(), 'en');
    expect(_container(store).read(appLanguageProvider), AppLanguage.en);
  });

  test('names each language in the language itself', () {
    expect([for (final l in AppLanguage.values) (l.nativeName, l.locale)], [
      ('Deutsch', const Locale('de')),
      ('English', const Locale('en')),
    ]);
  });

  test('offers exactly the languages that have translations', () {
    expect({for (final l in AppLanguage.values) l.locale}, AppLocalizations.supportedLocales.toSet());
  });
}
