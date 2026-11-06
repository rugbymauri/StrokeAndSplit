import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/ghost_switch.dart';
import '../../app/widgets/oar_stepper.dart';
import '../../app/widgets/segment_choice.dart';
import '../../data/courses/course.dart';
import '../../data/courses/course_providers.dart';
import '../../data/sessions/session_plan.dart';
import '../../l10n/l10n.dart';
import '../connection/rower_connection.dart';
import '../live/formatters.dart';
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

/// How long the course is rowed.
enum _Length { laps, duration, open }

/// More laps than anyone rows in one session, as in the template editor.
const _maxLaps = 99;

/// The longest total time in minutes.
const _maxMinutes = 180;

/// Rows a course without a template: for a number of laps, a total rowing
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
  var _length = _Length.laps;
  var _laps = 3;
  var _minutes = 30;
  var _ghost = true;

  PlanLength get _planLength => switch (_length) {
    _Length.laps => LapCount(_laps),
    _Length.duration => TimeLimit(Duration(minutes: _minutes)),
    _Length.open => const OpenLength(),
  };

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
                            SegmentChoice(
                              key: const Key('course-start-length'),
                              options: [
                                (_Length.laps, l10n.courseStartLaps),
                                (_Length.duration, l10n.courseStartDuration),
                                (_Length.open, l10n.courseStartOpen),
                              ],
                              value: _length,
                              onChanged: (length) =>
                                  setState(() => _length = length),
                            ),
                            const SizedBox(height: AppSpacing.l),
                            _input(l10n),
                          ],
                        ),
                      ),
                      // Fixed at the bottom like on the template screen.
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

  /// Only the input of the chosen option.
  Widget _input(AppLocalizations l10n) => switch (_length) {
    _Length.laps => OarStepper(
      key: const Key('course-start-laps'),
      value: _laps,
      step: 1,
      min: 1,
      max: _maxLaps,
      stepLabel: l10n.lapsCount(1),
      label: l10n.courseStartLaps,
      unit: l10n.templateLapsUnit(_laps),
      onChanged: (laps) => setState(() => _laps = laps),
    ),
    _Length.duration => OarStepper(
      key: const Key('course-start-duration'),
      value: _minutes,
      step: 1,
      min: 1,
      max: _maxMinutes,
      stepLabel: l10n.stepMinutes(1),
      label: l10n.courseStartDuration,
      format: (minutes) => formatElapsed(Duration(minutes: minutes)),
      onChanged: (minutes) => setState(() => _minutes = minutes),
    ),
    _Length.open => Text(
      l10n.courseStartOpenHint,
      key: const Key('course-start-open-hint'),
      style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
      textAlign: TextAlign.center,
    ),
  };

  void _start(Course course) => startRowing(
    context,
    ref,
    plan: SessionPlan(course: course, length: _planLength),
    ghost: _ghost,
  );
}
