import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/features/live/zone_hint.dart';
import 'package:strokesplit/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final de = lookupAppLocalizations(const Locale('de'));
  final en = lookupAppLocalizations(const Locale('en'));

  const tempo = CourseSegment(
    length: 600,
    paceFastCs: 12500,
    paceSlowCs: 13000,
    spmMin: 20,
    spmMax: 22,
    resistanceLevel: 8,
    zoneName: 'Tempo',
  );
  const kraft = CourseSegment(
    length: 300,
    resistanceLevel: 12,
    zoneName: 'Kraft',
  );
  const unnamed = CourseSegment(
    length: 400,
    paceFastCs: 14000,
    paceSlowCs: 14500,
  );
  const free = CourseSegment(length: 200);

  test('lists all targets of a zone', () {
    expect(zoneTargets(de, tempo), 'Tempo · 2:05–2:10 · 20–22 spm · Stufe 8');
    expect(zoneTargets(en, tempo), 'Tempo · 2:05–2:10 · 20–22 spm · Level 8');
  });

  test('lists only the level of a zone with nothing else', () {
    expect(zoneTargets(de, kraft), 'Kraft · Stufe 12');
    expect(zoneTargets(en, kraft), 'Kraft · Level 12');
  });

  test('names a free part', () {
    expect(zoneTargets(de, free), 'frei');
    expect(zoneTargets(en, free), en.segmentFree);
  });

  test('calls a zone without a name a zone', () {
    expect(zoneTargets(de, unnamed), 'Zone · 2:20–2:25');
    expect(zoneTargets(en, unnamed), '${en.segmentZone} · 2:20–2:25');
  });
}
