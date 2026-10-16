import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/courses/course.dart';
import '../../data/courses/course_providers.dart';
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: embedded ? null : AppBar(title: Text(l10n.coursesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'courses',
        onPressed: () => openCourseEditor(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.courseCreate),
      ),
      body: switch (courses) {
        AsyncData(value: []) => Center(child: Text(l10n.coursesEmpty)),
        AsyncData(:final value) => ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: value.length,
            itemBuilder: (context, i) => _CourseTile(course: value[i]),
          ),
        AsyncError(:final error) => Center(child: Text(l10n.coursesLoadFailed('$error'))),
        _ => const Center(child: CircularProgressIndicator()),
      },
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

class _CourseTile extends ConsumerWidget {
  const _CourseTile({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ListTile(
      leading: Icon(course.axis == CourseAxis.distance ? Icons.straighten : Icons.timer_outlined),
      title: Text(course.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(courseSummary(l10n, course)),
          const SizedBox(height: 6),
          CourseStrip(definition: course.definition),
        ],
      ),
      onTap: () => openCourseEditor(context, course: course),
      trailing: IconButton(
        tooltip: l10n.actionDelete,
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _delete(context, ref),
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
