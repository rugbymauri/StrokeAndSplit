import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/ghost_switch.dart';
import '../../data/courses/course.dart';
import '../../data/courses/course_providers.dart';
import '../../data/sessions/session_plan.dart';
import '../../l10n/l10n.dart';
import '../connection/rower_connection.dart';
import '../sessions/plan_length_choice.dart';
import 'course_strip.dart';
import 'courses_screen.dart';

/// Opens the start screen of the course with [courseId].
Future<void> openCourseStart(BuildContext context, int courseId) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CourseStartScreen(courseId: courseId),
    ),
  );
}

/// Rows a course without a workout: for a number of laps, a total rowing
/// time or until the rower ends the session, with or without the ghost
/// (course-rowing-free, Design D6). Nothing chosen here is stored; deleting
/// the course closes the screen.
class CourseStartScreen extends ConsumerStatefulWidget {
  const CourseStartScreen({super.key, required this.courseId});

  final int courseId;

  @override
  ConsumerState<CourseStartScreen> createState() => _CourseStartScreenState();
}

class _CourseStartScreenState extends ConsumerState<CourseStartScreen> {
  // The values of all options stay while the screen is open.
  PlanLength _length = const LapCount(3);
  var _ghost = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(coursesProvider, (_, next) {
      if (next case AsyncData(:final value)
          when !value.any((c) => c.id == widget.courseId)) {
        final route = ModalRoute.of(context);
        if (route != null && route.isActive) {
          Navigator.of(context).removeRoute(route);
        }
      }
    });
    final course = ref
        .watch(coursesProvider)
        .value
        ?.where((c) => c.id == widget.courseId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(course?.name ?? '')),
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
                            AppSpacing.l,
                          ),
                          children: [
                            CourseStrip(definition: course.definition),
                            const SizedBox(height: 10),
                            Text(
                              courseSummary(l10n, course),
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            PlanLengthChoice(
                              keyPrefix: 'course-start',
                              initial: _length,
                              onChanged: (length) => _length = length,
                            ),
                          ],
                        ),
                      ),
                      // Fixed at the bottom like on the workout screen.
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
                            GhostSwitch(
                              key: const Key('course-start-ghost'),
                              value: _ghost,
                              onChanged: (value) =>
                                  setState(() => _ghost = value),
                            ),
                            const SizedBox(height: AppSpacing.s),
                            SizedBox(
                              height: 56,
                              child: FilledButton(
                                key: const Key('course-start-start'),
                                onPressed: () => _start(course),
                                child: Text(
                                  l10n.courseStartStart,
                                  style: AppTextStyles.cardTitle,
                                ),
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

  void _start(Course course) => startRowing(
    context,
    ref,
    plan: SessionPlan(courses: [course], length: _length),
    ghost: _ghost,
  );
}
