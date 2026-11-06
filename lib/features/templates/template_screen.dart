import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/ghost_symbol.dart';
import '../../data/templates/template_providers.dart';
import '../../l10n/l10n.dart';
import '../connection/rower_connection.dart';
import '../courses/course_strip.dart';
import 'template_editor_screen.dart';
import 'template_podium.dart';
import 'templates_screen.dart';

/// Opens the screen of the template with [templateId].
Future<void> openTemplate(BuildContext context, int templateId) {
  return Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => TemplateScreen(templateId: templateId)));
}

/// A template with its zones and places 1–3, to start it with or without the
/// ghost and to edit it (Change template-screen, Design D1). It follows the
/// stored template, so it shows a change from the editor; deleting the
/// template closes it too.
class TemplateScreen extends ConsumerStatefulWidget {
  const TemplateScreen({super.key, required this.templateId});

  final int templateId;

  @override
  ConsumerState<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends ConsumerState<TemplateScreen> {
  /// Whether the session started from here runs with its ghosts; on each time
  /// the screen opens and never stored (Design D5).
  var _ghost = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(templatesProvider, (_, next) {
      if (next case AsyncData(:final value) when !value.any((t) => t.id == widget.templateId)) {
        final route = ModalRoute.of(context);
        if (route != null && route.isActive) Navigator.of(context).removeRoute(route);
      }
    });
    final template = ref.watch(templatesProvider).value?.where((t) => t.id == widget.templateId).firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(template?.name ?? ''),
        actions: [
          if (template != null)
            IconButton(
              key: const Key('template-edit'),
              tooltip: l10n.templateEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => TemplateEditorScreen(template: template))),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: template == null
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.pagePortrait,
                            AppSpacing.l,
                            AppSpacing.pagePortrait,
                            AppSpacing.l,
                          ),
                          children: [
                            Text(templateDetails(l10n, template), style: AppTextStyles.subtitle),
                            const SizedBox(height: AppSpacing.m),
                            CourseStrip(definition: template.course.definition),
                            const SizedBox(height: AppSpacing.m),
                            for (final line in templateZoneLines(l10n, template.course))
                              Text(line, style: AppTextStyles.caption),
                            const SizedBox(height: AppSpacing.xxl),
                            TemplatePodium(template: template),
                          ],
                        ),
                      ),
                      // Fixed at the bottom, so "Starten" is reachable without scrolling.
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pagePortrait,
                          AppSpacing.s,
                          AppSpacing.pagePortrait,
                          AppSpacing.l,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _GhostSwitch(value: _ghost, onChanged: (value) => setState(() => _ghost = value)),
                            const SizedBox(height: AppSpacing.s),
                            SizedBox(
                              height: 56,
                              child: FilledButton(
                                key: const Key('template-start'),
                                onPressed: () => startRowing(context, ref, template: template, ghost: _ghost),
                                child: Text(l10n.templateStart, style: AppTextStyles.cardTitle),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// The ghost symbol, the text and a switch in one row that reacts to a tap
/// anywhere on it (Design D5).
class _GhostSwitch extends StatelessWidget {
  const _GhostSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        key: const Key('template-ghost'),
        borderRadius: BorderRadius.circular(AppRadii.small),
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              const ExcludeSemantics(child: GhostSymbol(rimColor: AppColors.bg)),
              const SizedBox(width: AppSpacing.m),
              Expanded(child: Text(context.l10n.templateGhost, style: AppTextStyles.body)),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
