import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keys of the translations in an ARB file, without metadata.
Set<String> _keys(Map<String, Object?> arb) => {
  for (final key in arb.keys)
    if (!key.startsWith('@')) key,
};

/// What a translation lacks or has too much compared with the template.
({Set<String> missing, Set<String> extra}) compareArb(
  Map<String, Object?> template,
  Map<String, Object?> other,
) {
  final (expected, actual) = (_keys(template), _keys(other));
  return (
    missing: expected.difference(actual),
    extra: actual.difference(expected),
  );
}

Map<String, Object?> _read(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, Object?>;

void main() {
  final template = _read(File('lib/l10n/app_de.arb'));
  final translations = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb') && !f.path.endsWith('app_de.arb'))
      .toList();

  test('there is at least one translation besides German', () {
    expect(translations, isNotEmpty);
  });

  for (final file in translations) {
    test(
      '${file.uri.pathSegments.last} has exactly the keys of the German template',
      () {
        final result = compareArb(template, _read(file));
        expect(result.missing, isEmpty, reason: 'missing keys');
        expect(result.extra, isEmpty, reason: 'keys not in the template');
      },
    );
  }

  test('every key of the template is described for translators', () {
    expect({
      for (final key in _keys(template))
        if (template['@$key'] == null) key,
    }, isEmpty);
  });

  test('the comparison notices a missing and an extra key', () {
    final result = compareArb(
      {'a': 'A', 'b': 'B', '@a': {}},
      {'a': 'A', 'c': 'C'},
    );
    expect(result.missing, {'b'});
    expect(result.extra, {'c'});
  });
}
