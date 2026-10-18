import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:strokesplit/app/font_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shows the OFL of both bundled fonts on the licence page', () async {
    registerFontLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    for (final family in fontLicenses.keys) {
      final entry = entries.singleWhere((e) => e.packages.contains(family));
      final text = entry.paragraphs.map((p) => p.text).join('\n');
      expect(text, contains('SIL OPEN FONT LICENSE'), reason: family);
    }
  });
}
