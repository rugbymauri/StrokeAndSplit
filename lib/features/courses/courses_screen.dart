import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/courses/course.dart';
import '../../data/courses/course_providers.dart';
import 'course_editor_screen.dart';

/// All courses, to create, edit and delete them; [embedded] in a tab it
/// has no app bar of its own.
class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(coursesProvider);
    return Scaffold(
      appBar: embedded ? null : AppBar(title: const Text('Strecken')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'courses',
        onPressed: () => openCourseEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Strecke anlegen'),
      ),
      body: switch (courses) {
        AsyncData(value: []) => const Center(child: Text('Noch keine Strecken angelegt.')),
        AsyncData(:final value) => ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: value.length,
            itemBuilder: (context, i) => _CourseTile(course: value[i]),
          ),
        AsyncError(:final error) => Center(child: Text('Strecken konnten nicht geladen werden: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

Future<void> openCourseEditor(BuildContext context, {Course? course}) {
  return Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CourseEditorScreen(course: course)));
}

/// `1000 m · 3 Segmente`
String courseSummary(Course course) {
  final segments = course.definition.segments.length;
  return '${formatCourseLength(course.axis, course.definition.length)} · '
      '${segments == 1 ? '1 Segment' : '$segments Segmente'}';
}

class _CourseTile extends ConsumerWidget {
  const _CourseTile({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(course.axis == CourseAxis.distance ? Icons.straighten : Icons.timer_outlined),
      title: Text(course.name),
      subtitle: Text(courseSummary(course)),
      onTap: () => openCourseEditor(context, course: course),
      trailing: IconButton(
        tooltip: 'Löschen',
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
      builder: (context) => AlertDialog(
        title: const Text('Strecke löschen?'),
        content: Text([
          '„${course.name}“ verschwindet aus der Liste. Bereits geruderte Sessions behalten ihre Runden.',
          if (templates.isNotEmpty)
            'Diese Vorlagen verwenden die Strecke und werden mitgelöscht: ${templates.map((t) => '„$t“').join(', ')}.',
        ].join('\n\n')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Löschen')),
        ],
      ),
    );
    if (confirmed == true) await repository.delete(course.id);
  }
}
