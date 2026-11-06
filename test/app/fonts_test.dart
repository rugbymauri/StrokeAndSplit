import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The fonts of Design D1 ship with the app, so they load without a network.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Map<String, List<(String, int?)>>> manifest() async {
    final json = jsonDecode(
      await rootBundle.loadString('FontManifest.json'),
    ) as List<dynamic>;
    return {
      for (final family in json.cast<Map<String, dynamic>>())
        family['family'] as String: [
          for (final font
              in (family['fonts'] as List<dynamic>)
                  .cast<Map<String, dynamic>>())
            (font['asset'] as String, font['weight'] as int?),
        ],
    };
  }

  test(
    'lists Barlow Condensed 500 and 700 and IBM Plex Sans 400, 500 and 600',
    () async {
      final families = await manifest();

      expect(
        [for (final (_, weight) in families['Barlow Condensed']!) weight],
        [500, 700],
      );
      expect(
        [for (final (_, weight) in families['IBM Plex Sans']!) weight],
        [400, 500, 600],
      );
    },
  );

  test('loads every bundled font file', () async {
    final families = await manifest();
    for (final family in ['Barlow Condensed', 'IBM Plex Sans']) {
      final loader = FontLoader(family);
      for (final (asset, _) in families[family]!) {
        final data = await rootBundle.load(asset);
        // A TrueType file starts with the version 1.0 tag.
        expect(data.getUint32(0), 0x00010000, reason: asset);
        loader.addFont(Future.value(data));
      }
      await loader.load();
    }
  });
}
