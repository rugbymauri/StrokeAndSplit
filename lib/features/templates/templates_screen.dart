import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../data/courses/course.dart';
import '../../data/courses/course_providers.dart';
import '../../data/templates/session_template.dart';
import '../../data/templates/template_providers.dart';
import '../../l10n/l10n.dart';
import '../courses/course_format.dart';
import '../courses/course_strip.dart';
import '../courses/courses_screen.dart';
import '../zones/zones_screen.dart';
import 'template_editor_screen.dart';
import 'template_format.dart';
import 'template_screen.dart';

/// Templates, courses and zones in three tabs (canvas „Vorlage wählen“).
class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.templatesTitle),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePortrait,
                    0,
                    AppSpacing.pagePortrait,
                    AppSpacing.s,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.small),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: TabBar(
                        tabs: [
                          Tab(height: 40, text: l10n.tabTemplates),
                          Tab(height: 40, text: l10n.tabCourses),
                          Tab(height: 40, text: l10n.tabZones),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            const _TemplatesTab(),
            const CoursesScreen(embedded: true),
            const ZonesScreen(embedded: true),
          ],
        ),
      ),
    );
  }
}

/// All templates, to open one on its own screen and to create one (Change
/// template-screen, Design D2).
class _TemplatesTab extends ConsumerWidget {
  const _TemplatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider);
    final hasCourses = ref.watch(coursesProvider).value?.isNotEmpty ?? true;
    final l10n = context.l10n;
    return SafeArea(
      top: false,
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
                  child: switch (templates) {
                    AsyncData(value: []) when !hasCourses => _NoCourse(
                      onCreate: () => openCourseEditor(context),
                    ),
                    AsyncData(value: []) => Center(
                      child: Text(
                        l10n.templatesEmpty,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.subtitle,
                      ),
                    ),
                    AsyncData(:final value) => ListView.separated(
                      itemCount: value.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          _TemplateCard(template: value[i]),
                    ),
                    AsyncError(:final error) => Center(
                      child: Text(l10n.templatesLoadFailed('$error')),
                    ),
                    _ => const Center(child: CircularProgressIndicator()),
                  },
                ),
                const SizedBox(height: AppSpacing.l),
                OutlinedButton.icon(
                  key: const Key('template-create'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () =>
                      hasCourses ? _openEditor(context) : _offerCourse(context),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.templateCreate),
                ),
              ],
            ),
          ),
        ),
      ),
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.courseCreate),
            ),
          ],
        );
      },
    );
    if (create == true && context.mounted) await openCourseEditor(context);
  }
}

Future<void> _openEditor(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const TemplateEditorScreen()));
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
            Text(
              l10n.templateNeedsCourse,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.route),
              label: Text(l10n.courseCreate),
            ),
          ],
        ),
      ),
    );
  }
}

/// `Seerunde · 1000 m · 3 Runden` below the name of a template.
String templateDetails(AppLocalizations l10n, SessionTemplate template) {
  final course = template.course;
  return '${course.name} · ${formatCourseLength(course.axis, course.definition.length)} · '
      '${formatLaps(l10n, template.laps)}';
}

/// The zones of a course with their bands, each once, e.g.
/// `Tempo 2:05–2:10 · 20–22 spm`; `ohne Zonen` for a free course.
List<String> templateZoneLines(AppLocalizations l10n, Course course) {
  final lines = {
    for (final s in course.definition.segments)
      if (!s.isFree)
        '${s.zoneName ?? l10n.segmentZone} ${formatSegmentBands(l10n, s)}',
  };
  return lines.isEmpty ? [l10n.courseZonesSummary(0, '')] : lines.toList();
}

/// A template as a compact card with its name, details and course; a tap
/// opens its screen (Change template-screen, Design D2).
class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template});

  final SessionTemplate template;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      key: Key('template-${template.id}'),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.cardLarge),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openTemplate(context, template.id),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(template.name, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      templateDetails(l10n, template),
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    CourseStrip(
                      definition: template.course.definition,
                      height: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
