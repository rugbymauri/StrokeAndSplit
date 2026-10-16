import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/courses/course_providers.dart';
import '../../data/templates/session_template.dart';
import '../../data/templates/template_providers.dart';
import '../../l10n/l10n.dart';
import '../connection/rower_connection.dart';
import '../courses/courses_screen.dart';
import '../zones/zones_screen.dart';
import 'template_editor_screen.dart';
import 'template_format.dart';

/// Templates, courses and zones in three tabs.
class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key, this.selectedTemplateId});

  /// The template shown as chosen, e.g. from "Nochmal" on the start screen.
  final int? selectedTemplateId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.templatesTitle),
          bottom: TabBar(tabs: [Tab(text: l10n.tabTemplates), Tab(text: l10n.tabCourses), Tab(text: l10n.tabZones)]),
        ),
        body: TabBarView(
          children: [
            _TemplatesTab(selectedTemplateId: selectedTemplateId),
            const CoursesScreen(embedded: true),
            const ZonesScreen(embedded: true),
          ],
        ),
      ),
    );
  }
}

/// All templates, to start, create, edit and delete them.
class _TemplatesTab extends ConsumerWidget {
  const _TemplatesTab({this.selectedTemplateId});

  final int? selectedTemplateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider);
    final hasCourses = ref.watch(coursesProvider).value?.isNotEmpty ?? true;
    final l10n = context.l10n;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'templates',
        onPressed: () => hasCourses ? _openEditor(context) : _offerCourse(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.templateCreate),
      ),
      body: switch (templates) {
        AsyncData(value: []) when !hasCourses => _NoCourse(onCreate: () => openCourseEditor(context)),
        AsyncData(value: []) => Center(child: Text(l10n.templatesEmpty)),
        AsyncData(:final value) => ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: value.length,
            itemBuilder: (context, i) => _TemplateTile(
              template: value[i],
              selected: value[i].id == selectedTemplateId,
            ),
          ),
        AsyncError(:final error) => Center(child: Text(l10n.templatesLoadFailed('$error'))),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Future<void> _offerCourse(BuildContext context) async {
    final create = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.templateNeedsCourseTitle),
          content: Text(l10n.templateNeedsCourseBody),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.actionCancel)),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.courseCreate)),
          ],
        );
      },
    );
    if (create == true && context.mounted) await openCourseEditor(context);
  }
}

Future<void> _openEditor(BuildContext context, {SessionTemplate? template}) {
  return Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => TemplateEditorScreen(template: template)));
}

class _NoCourse extends StatelessWidget {
  const _NoCourse({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.templateNeedsCourse, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.route), label: Text(l10n.courseCreate)),
          ],
        ),
      ),
    );
  }
}

enum _Action { edit, delete }

class _TemplateTile extends ConsumerWidget {
  const _TemplateTile({required this.template, this.selected = false});

  final SessionTemplate template;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ListTile(
      key: Key('template-${template.id}'),
      selected: selected,
      leading: const Icon(Icons.flag_outlined),
      title: Text(template.name),
      subtitle: Text('${template.course.name} · ${formatLaps(l10n, template.laps)}'),
      onTap: () => _start(context, ref),
      trailing: PopupMenuButton<_Action>(
        tooltip: l10n.actionMore,
        onSelected: (action) => switch (action) {
          _Action.edit => _openEditor(context, template: template),
          _Action.delete => _delete(context, ref),
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: _Action.edit, child: Text(l10n.actionEdit)),
          PopupMenuItem(value: _Action.delete, child: Text(l10n.actionDelete)),
        ],
      ),
    );
  }

  /// Starts the template with the rower chosen in "Geräte wählen" (Design D6).
  Future<void> _start(BuildContext context, WidgetRef ref) => startRowing(context, ref, template: template);

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.templateDeleteTitle),
          content: Text(l10n.templateDeleteBody(template.name)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.actionCancel)),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.actionDelete)),
          ],
        );
      },
    );
    if (confirmed == true) await ref.read(templateRepositoryProvider).delete(template.id);
  }
}
