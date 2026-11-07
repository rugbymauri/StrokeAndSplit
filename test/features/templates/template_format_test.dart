import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/features/templates/template_format.dart';
import 'package:strokesplit/features/templates/templates_screen.dart';
import 'package:strokesplit/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats the number of laps in German and English', () {
    final de = lookupAppLocalizations(const Locale('de'));
    final en = lookupAppLocalizations(const Locale('en'));

    expect(
      [formatLaps(de, 1), formatLaps(de, 3), formatLaps(de, null)],
      ['1 Runde', '3 Runden', 'offen'],
    );
    expect(
      [formatLaps(en, 1), formatLaps(en, 3), formatLaps(en, null)],
      ['1 lap', '3 laps', 'open'],
    );
  });

  test('lists a zone with only a level with its level', () {
    final de = lookupAppLocalizations(const Locale('de'));
    const course = Course(
      id: 1,
      name: 'Seerunde',
      versionId: 1,
      version: 1,
      definition: CourseDefinition(
        axis: CourseAxis.distance,
        length: 1000,
        segments: [
          CourseSegment(length: 500),
          CourseSegment(
            length: 500,
            resistanceLevel: 12,
            zoneId: 4,
            zoneName: 'Kraft',
          ),
        ],
      ),
    );

    expect(templateZoneLines(de, course), ['Kraft Stufe 12']);
  });
}
