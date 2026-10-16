import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/courses/course.dart';
import '../../data/courses/course_providers.dart';
import '../../data/templates/session_template.dart';
import '../../data/templates/template_providers.dart';
import '../../l10n/l10n.dart';
import '../courses/courses_screen.dart';

/// Creates a template, or edits [template] when given.
class TemplateEditorScreen extends ConsumerStatefulWidget {
  const TemplateEditorScreen({super.key, this.template});

  final SessionTemplate? template;

  @override
  ConsumerState<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  late final _name = TextEditingController(text: widget.template?.name);
  late final _laps = TextEditingController(text: '${widget.template?.laps ?? 3}');
  late int? _courseId = widget.template?.course.id;
  late var _open = widget.template != null && widget.template!.laps == null;
  var _errors = <String>[];

  @override
  void dispose() {
    _name.dispose();
    _laps.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final laps = _open ? null : int.tryParse(_laps.text.trim());
    final l10n = context.l10n;
    final errors = [
      if (name.isEmpty) l10n.templateNameMissing,
      if (_courseId == null) l10n.templateCourseMissing,
      if (!_open && (laps == null || laps < 1)) l10n.templateLapsInvalid,
    ];
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    final repository = ref.read(templateRepositoryProvider);
    final template = widget.template;
    if (template == null) {
      await repository.create(name, courseId: _courseId!, laps: laps);
    } else {
      await repository.update(template.id, name: name, courseId: _courseId!, laps: laps);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesProvider).value ?? const <Course>[];
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null ? l10n.templateNew : l10n.templateEdit),
        actions: [IconButton(tooltip: l10n.actionSave, icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final e in _errors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(e, style: TextStyle(color: colors.error)),
                ),
              TextField(
                key: const Key('template-name'),
                controller: _name,
                decoration: InputDecoration(labelText: l10n.fieldName),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                key: const Key('template-course'),
                initialValue: courses.any((c) => c.id == _courseId) ? _courseId : null,
                decoration: InputDecoration(labelText: l10n.templateCourse),
                items: [
                  for (final c in courses)
                    DropdownMenuItem(value: c.id, child: Text('${c.name} · ${courseSummary(l10n, c)}')),
                ],
                onChanged: (id) => setState(() => _courseId = id),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.templateOpenLaps),
                subtitle: Text(l10n.templateOpenLapsHint),
                value: _open,
                onChanged: (open) => setState(() => _open = open),
              ),
              if (!_open)
                TextField(
                  key: const Key('template-laps'),
                  controller: _laps,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.templateLaps),
                ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _save, child: Text(l10n.actionSave)),
            ],
          ),
        ),
      ),
    );
  }
}
