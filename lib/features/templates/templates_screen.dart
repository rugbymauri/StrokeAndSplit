import 'package:erg_protocol/erg_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/courses/course_providers.dart';
import '../../data/sources/erg_source_providers.dart';
import '../../data/sources/simulated_source.dart';
import '../../data/templates/session_template.dart';
import '../../data/templates/template_providers.dart';
import '../connection/device_list_screen.dart';
import '../courses/courses_screen.dart';
import '../live/live_screen.dart';
import '../zones/zones_screen.dart';
import 'template_editor_screen.dart';

/// Templates, courses and zones in three tabs.
class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vorlage rudern'),
          bottom: const TabBar(tabs: [Tab(text: 'Vorlagen'), Tab(text: 'Strecken'), Tab(text: 'Zonen')]),
        ),
        body: const TabBarView(
          children: [_TemplatesTab(), CoursesScreen(embedded: true), ZonesScreen(embedded: true)],
        ),
      ),
    );
  }
}

/// All templates, to start, create, edit and delete them.
class _TemplatesTab extends ConsumerWidget {
  const _TemplatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider);
    final hasCourses = ref.watch(coursesProvider).value?.isNotEmpty ?? true;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'templates',
        onPressed: () => hasCourses ? _openEditor(context) : _offerCourse(context),
        icon: const Icon(Icons.add),
        label: const Text('Vorlage anlegen'),
      ),
      body: switch (templates) {
        AsyncData(value: []) when !hasCourses => _NoCourse(onCreate: () => openCourseEditor(context)),
        AsyncData(value: []) => const Center(child: Text('Noch keine Vorlagen angelegt.')),
        AsyncData(:final value) => ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: value.length,
            itemBuilder: (context, i) => _TemplateTile(template: value[i]),
          ),
        AsyncError(:final error) => Center(child: Text('Vorlagen konnten nicht geladen werden: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Future<void> _offerCourse(BuildContext context) async {
    final create = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zuerst eine Strecke anlegen'),
        content: const Text('Eine Vorlage rudert eine Strecke. Lege dafür zuerst eine Strecke an.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Strecke anlegen')),
        ],
      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Für eine Vorlage brauchst du zuerst eine Strecke.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.route), label: const Text('Strecke anlegen')),
          ],
        ),
      ),
    );
  }
}

enum _Action { edit, delete }

enum _Source { pm5, simulator, simulatorFtms }

class _TemplateTile extends ConsumerWidget {
  const _TemplateTile({required this.template});

  final SessionTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.flag_outlined),
      title: Text(template.name),
      subtitle: Text('${template.course.name} · ${formatLaps(template.laps)}'),
      onTap: () => _start(context, ref),
      trailing: PopupMenuButton<_Action>(
        tooltip: 'Aktionen',
        onSelected: (action) => switch (action) {
          _Action.edit => _openEditor(context, template: template),
          _Action.delete => _delete(context, ref),
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: _Action.edit, child: Text('Bearbeiten')),
          PopupMenuItem(value: _Action.delete, child: Text('Löschen')),
        ],
      ),
    );
  }

  /// Lets the user pick the source; the session starts once it is connected.
  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final source = await showDialog<_Source>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('„${template.name}“ rudern'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(_Source.pm5),
            child: const ListTile(leading: Icon(Icons.bluetooth_searching), title: Text('Rudergerät suchen')),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(_Source.simulator),
            child: const ListTile(leading: Icon(Icons.smart_toy_outlined), title: Text('Simulator')),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(_Source.simulatorFtms),
            child: const ListTile(
              leading: Icon(Icons.smart_toy_outlined),
              title: Text('Simulator (FTMS)'),
              subtitle: Text('Wie ein FTMS-Rudergerät, ohne Schlagdetails'),
            ),
          ),
        ],
      ),
    );
    if (source == null || !context.mounted) return;
    final navigator = Navigator.of(context);
    switch (source) {
      case _Source.pm5:
        await navigator.push(MaterialPageRoute<void>(builder: (_) => DeviceListScreen(template: template)));
      case _Source.simulator || _Source.simulatorFtms:
        final protocol = source == _Source.simulatorFtms ? ErgProtocol.ftms : ErgProtocol.pm5;
        await ref.read(activeErgSourceProvider.notifier).use(SimulatedSource(protocol: protocol));
        await navigator.push(MaterialPageRoute<void>(builder: (_) => LiveScreen(template: template)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vorlage löschen?'),
        content: Text('„${template.name}“ wird gelöscht. Damit geruderte Sessions bleiben erhalten.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Löschen')),
        ],
      ),
    );
    if (confirmed == true) await ref.read(templateRepositoryProvider).delete(template.id);
  }
}
