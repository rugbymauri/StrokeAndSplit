import 'package:strokesplit/features/templates/template_format.dart';
import 'package:strokesplit/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats the number of laps in German and English', () {
    final de = lookupAppLocalizations(const Locale('de'));
    final en = lookupAppLocalizations(const Locale('en'));

    expect([formatLaps(de, 1), formatLaps(de, 3), formatLaps(de, null)], ['1 Runde', '3 Runden', 'offen']);
    expect([formatLaps(en, 1), formatLaps(en, 3), formatLaps(en, null)], ['1 lap', '3 laps', 'open']);
  });
}
