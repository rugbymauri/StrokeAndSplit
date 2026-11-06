import 'package:strokesplit/app/platform_providers.dart';
import 'package:strokesplit/data/courses/course.dart';
import 'package:strokesplit/data/courses/course_repository.dart';
import 'package:strokesplit/data/sessions/session_providers.dart';
import 'package:strokesplit/data/sources/rower_choice.dart';
import 'package:strokesplit/data/templates/template_repository.dart';
import 'package:strokesplit/features/templates/templates_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_ble_transport.dart';
import 'localized_app.dart';
import 'test_database.dart';

/// A database with courses and templates, and the app around a screen of the
/// template choice.
class TemplateSetup {
  TemplateSetup({this.rower = const RowerChoice.simulator()});

  final RowerChoice rower;
  final db = openTestDatabase();
  late final courses = CourseRepository(db);
  late final templates = TemplateRepository(db);
  late final container = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db),
    wakelockProvider.overrideWithValue(FakeWakelock()),
    rowerChoiceStoreProvider.overrideWithValue(MemoryRowerChoiceStore(rower)),
  ]);

  Future<int> addCourse(WidgetTester tester, String name, {int length = 1000}) async => (await tester.runAsync(
        () => courses.create(name, CourseDefinition.single(axis: CourseAxis.distance, length: length)),
      ))!;

  /// A course of 1000 m with the zone „Tempo“ from 200 to 800 m.
  Future<int> addCourseWithZone(WidgetTester tester, String name) async => (await tester.runAsync(
        () => courses.create(
          name,
          const CourseDefinition(axis: CourseAxis.distance, length: 1000, segments: [
            CourseSegment(length: 200),
            CourseSegment(length: 600, paceFastCs: 12500, paceSlowCs: 13000, spmMin: 20, spmMax: 22, zoneName: 'Tempo'),
            CourseSegment(length: 200),
          ]),
        ),
      ))!;

  Future<int> addTemplate(WidgetTester tester, String name, {required int courseId, int? laps = 3}) async =>
      (await tester.runAsync(() => templates.create(name, courseId: courseId, laps: laps)))!;

  Future<void> pump(
    WidgetTester tester, {
    Widget home = const TemplatesScreen(),
    Locale locale = const Locale('de'),
  }) async {
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: LocalizedApp(locale: locale, home: home)),
    );
    await settle(tester);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pumpAndSettle();
    }
  }

  /// Opens the screen of the template [name] from the list.
  Future<void> openTemplate(WidgetTester tester, String name) async {
    await tester.tap(find.text(name));
    await settle(tester);
  }
}
