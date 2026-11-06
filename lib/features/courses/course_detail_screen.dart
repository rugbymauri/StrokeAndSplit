import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../data/courses/course.dart';
import '../../data/courses/course_providers.dart';
import '../../data/statistics/ranking_providers.dart';
import '../../l10n/l10n.dart';
import '../statistics/ranking_sections.dart';
import 'course_start_screen.dart';
import 'course_strip.dart';
import 'courses_screen.dart';

Future<void> openCourseDetail(BuildContext context, Course course) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CourseDetailScreen(courseId: course.id),
    ),
  );
}

/// A course with places 1–3 per length, the way to edit it (Change
/// statistics, Design D6) and to row it (course-rowing-free, Design D6).
/// Deleting the course while it is open closes it too.
class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final int courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.listen(coursesProvider, (_, next) {
      if (next case AsyncData(:final value)
          when !value.any((c) => c.id == courseId)) {
        final route = ModalRoute.of(context);
        if (route != null && route.isActive) {
          Navigator.of(context).removeRoute(route);
        }
      }
    });
    final course = ref
        .watch(coursesProvider)
        .value
        ?.where((c) => c.id == courseId)
        .firstOrNull;
    final rankings = ref.watch(courseRankingsProvider(courseId));
    return Scaffold(
      appBar: AppBar(
        title: Text(course?.name ?? ''),
        actions: [
          if (course != null)
            IconButton(
              key: const Key('course-edit'),
              tooltip: l10n.actionEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => openCourseEditor(context, course: course),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: course == null
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
                            AppSpacing.xxl,
                          ),
                          children: [
                            CourseStrip(definition: course.definition),
                            const SizedBox(height: 10),
                            Text(
                              courseSummary(l10n, course),
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            switch (rankings) {
                              AsyncData(:final value) => RankingSections(
                                rankings: value,
                                axis: course.axis,
                                length: course.definition.length,
                              ),
                              AsyncError(:final error) => Text(
                                l10n.rankingLoadFailed('$error'),
                              ),
                              _ => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            },
                          ],
                        ),
                      ),
                      // Fixed below the rankings (course-rowing-free, Design D6).
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pagePortrait,
                          AppSpacing.s,
                          AppSpacing.pagePortrait,
                          AppSpacing.l,
                        ),
                        child: SizedBox(
                          height: 56,
                          child: FilledButton(
                            key: const Key('course-row'),
                            onPressed: () =>
                                openCourseStart(context, course.id),
                            child: Text(
                              l10n.courseRow,
                              style: AppTextStyles.cardTitle,
                            ),
                          ),
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
