import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../data/courses/course.dart';
import '../../data/courses/course_providers.dart';
import '../../data/courses/course_repository.dart';
import '../../l10n/l10n.dart';
import 'course_editor_screen.dart';
import 'course_strip.dart';

/// All courses, to create, edit and delete them; [embedded] in a tab it
/// has no app bar of its own.
class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(coursesProvider);
    final rowed = ref.watch(courseRowCountsProvider).value ?? const <int, CourseRowCount>{};
    final l10n = context.l10n;
    return Scaffold(
      appBar: embedded ? null : AppBar(title: Text(l10n.coursesTitle)),
      body: SafeArea(
        top: !embedded,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePortrait,
                AppSpacing.l,
                AppSpacing.pagePortrait,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: switch (courses) {
                      AsyncData(value: []) => Center(
                          child: Text(l10n.coursesEmpty, textAlign: TextAlign.center, style: AppTextStyles.subtitle),
                        ),
                      AsyncData(:final value) => ListView(
                          children: [
                            _CourseList(courses: value, rowed: rowed),
                            const SizedBox(height: AppSpacing.l),
                            const _Legend(),
                          ],
                        ),
                      AsyncError(:final error) => Center(child: Text(l10n.coursesLoadFailed('$error'))),
                      _ => const Center(child: CircularProgressIndicator()),
                    },
                  ),
                  const SizedBox(height: AppSpacing.l),
                  OutlinedButton.icon(
                    key: const Key('course-create'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: () => openCourseEditor(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.courseCreate),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> openCourseEditor(BuildContext context, {Course? course}) {
  return Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CourseEditorScreen(course: course)));
}

/// `2000 m · Sprint, Ausdauer 2:30`, or `1000 m · frei` without zones.
String courseSummary(AppLocalizations l10n, Course course) {
  final zones = {for (final s in course.definition.segments) ?s.zoneName};
  return '${formatCourseLength(course.axis, course.definition.length)} · '
      '${zones.isEmpty ? l10n.segmentFree : zones.join(', ')}';
}

/// `Distanz · Zone Tempo · 12× gerudert` below a course in the list.
String courseDetails(AppLocalizations l10n, Course course, int rowed) {
  final zones = [for (final s in course.definition.segments) if (!s.isFree) s];
  return [
    course.axis == CourseAxis.distance ? l10n.axisDistance : l10n.axisTime,
    l10n.courseZonesSummary(zones.length, zones.firstOrNull?.zoneName ?? l10n.segmentZone),
    l10n.courseRowedCount(rowed),
  ].join(' · ');
}

/// The courses on one card, divided by lines (canvas „Streckenliste“).
class _CourseList extends StatelessWidget {
  const _CourseList({required this.courses, required this.rowed});

  final List<Course> courses;
  final Map<int, CourseRowCount> rowed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.cardLarge),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, course) in courses.indexed) ...[
            if (i > 0) const Divider(height: 1),
            _CourseTile(course: course, rowed: rowed[course.id]?.total ?? 0),
          ],
        ],
      ),
    );
  }
}

class _CourseTile extends ConsumerWidget {
  const _CourseTile({required this.course, required this.rowed});

  final Course course;

  /// How often the course was rowed, in all its versions.
  final int rowed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return InkWell(
      key: Key('course-${course.id}'),
      onTap: () => openCourseEditor(context, course: course),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.xs, AppSpacing.xs, AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(course.name, style: AppTextStyles.cardTitle)),
                Text(
                  formatCourseLength(course.axis, course.definition.length),
                  style: const TextStyle(fontFamily: AppFonts.display, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  tooltip: l10n.actionDelete,
                  color: AppColors.textMuted,
                  iconSize: 20,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, ref),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CourseStrip(definition: course.definition),
                  const SizedBox(height: 10),
                  Text(courseDetails(l10n, course, rowed), style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(courseRepositoryProvider);
    final templates = await repository.templatesUsing(course.id);
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.courseDeleteTitle),
          content: Text([
            l10n.courseDeleteBody(course.name),
            if (templates.isNotEmpty) l10n.courseDeleteTemplates(l10n.quotedNames(templates)),
          ].join('\n\n')),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.actionCancel)),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.actionDelete)),
          ],
        );
      },
    );
    if (confirmed == true) await repository.delete(course.id);
  }
}

/// What the colours of the bars mean.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget swatch(Color color, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 8,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 6),
            Text(text, style: AppTextStyles.caption),
          ],
        );
    return Wrap(
      spacing: AppSpacing.l,
      runSpacing: AppSpacing.xs,
      children: [
        swatch(AppColors.zoneIn, l10n.segmentZone),
        swatch(AppColors.line, l10n.segmentFree),
        Text(l10n.courseLegendShade, style: AppTextStyles.caption),
      ],
    );
  }
}
