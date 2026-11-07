import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../data/courses/course.dart';
import '../../data/courses/course_providers.dart';
import '../../data/sessions/session_plan.dart';
import '../../data/workouts/workout.dart';
import '../../data/workouts/workout_providers.dart';
import '../../l10n/l10n.dart';
import '../courses/course_strip.dart';
import '../courses/courses_screen.dart';
import '../live/formatters.dart';
import '../sessions/plan_length_choice.dart';

/// Creates a workout, or edits [workout] when given.
class WorkoutEditorScreen extends ConsumerStatefulWidget {
  const WorkoutEditorScreen({super.key, this.workout});

  final Workout? workout;

  @override
  ConsumerState<WorkoutEditorScreen> createState() =>
      _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends ConsumerState<WorkoutEditorScreen> {
  late final _name = TextEditingController(text: widget.workout?.name);
  late final _courses = [...?widget.workout?.courses];
  late PlanLength _length = widget.workout?.length ?? const LapCount(3);
  var _errors = <String>[];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final l10n = context.l10n;
    final errors = [
      if (name.isEmpty) l10n.workoutNameMissing,
      if (_courses.isEmpty) l10n.workoutCourseMissing,
    ];
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    final repository = ref.read(workoutRepositoryProvider);
    final courseIds = [for (final c in _courses) c.id];
    final workout = widget.workout;
    if (workout == null) {
      await repository.create(name, courseIds: courseIds, length: _length);
    } else {
      await repository.update(
        workout.id,
        name: name,
        courseIds: courseIds,
        length: _length,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  /// Lets the rower pick a course: of the axis of the others, or of both
  /// axes when it replaces the only one (workout-course-chain, Design D8).
  Future<Course?> _pick({CourseAxis? axis}) {
    final courses = (ref.read(coursesProvider).value ?? const <Course>[])
        .where((c) => axis == null || c.axis == axis)
        .toList();
    return showModalBottomSheet<Course>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final l10n = context.l10n;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.8,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.workoutCourseChoose,
                    style: AppTextStyles.cardTitle,
                  ),
                ),
                for (final c in courses)
                  ListTile(
                    key: Key('workout-pick-${c.id}'),
                    title: Text(c.name),
                    subtitle: Text(courseSummary(l10n, c)),
                    onTap: () => Navigator.of(context).pop(c),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _append() async {
    final course = await _pick(axis: _courses.firstOrNull?.axis);
    if (course != null) setState(() => _courses.add(course));
  }

  Future<void> _replace(int index) async {
    final course = await _pick(
      axis: _courses.length == 1 ? null : _courses.first.axis,
    );
    if (course != null) setState(() => _courses[index] = course);
  }

  void _move(int index, int by) =>
      setState(() => _courses.insert(index + by, _courses.removeAt(index)));

  Future<void> _delete() async {
    final workout = widget.workout!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.workoutDeleteTitle),
          content: Text(l10n.workoutDeleteBody(workout.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.actionDelete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await ref.read(workoutRepositoryProvider).delete(workout.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the list of courses loaded for the picker.
    ref.watch(coursesProvider);
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.workout == null ? l10n.workoutNew : l10n.workoutEdit,
        ),
        actions: [
          if (widget.workout != null)
            IconButton(
              tooltip: l10n.actionDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          IconButton(
            tooltip: l10n.actionSave,
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
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
                  key: const Key('workout-name'),
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.fieldName),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.workoutCourses.toUpperCase(),
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 10),
                for (final (i, course) in _courses.indexed) ...[
                  _CourseCard(
                    key: Key('workout-course-$i'),
                    course: course,
                    onUp: i == 0 ? null : () => _move(i, -1),
                    onDown: i == _courses.length - 1 ? null : () => _move(i, 1),
                    // The only course can only be replaced (Design D8).
                    onRemove: _courses.length == 1
                        ? null
                        : () => setState(() => _courses.removeAt(i)),
                    onReplace: () => _replace(i),
                  ),
                  const SizedBox(height: 8),
                ],
                OutlinedButton.icon(
                  key: const Key('workout-course-add'),
                  onPressed: _append,
                  icon: const Icon(Icons.add),
                  label: Text(
                    _courses.isEmpty
                        ? l10n.workoutCourseChoose
                        : l10n.workoutCourseAdd,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.workoutLength.toUpperCase(),
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 10),
                PlanLengthChoice(
                  keyPrefix: 'workout',
                  initial: _length,
                  onChanged: (length) => setState(() => _length = length),
                ),
                if (_courses.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _Result(
                    axis: _courses.first.axis,
                    lap: _courses.fold(
                      0,
                      (sum, c) => sum + c.definition.length,
                    ),
                    length: _length,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(onPressed: _save, child: Text(l10n.actionSave)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One course of the workout in its place: name, length and zones, with
/// buttons to move, remove or replace it; a tap on it replaces it too.
class _CourseCard extends StatelessWidget {
  const _CourseCard({
    super.key,
    required this.course,
    required this.onUp,
    required this.onDown,
    required this.onRemove,
    required this.onReplace,
  });

  final Course course;
  final VoidCallback? onUp;
  final VoidCallback? onDown;

  /// Null for the only course, which shows the button to replace it instead.
  final VoidCallback? onRemove;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.small),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onReplace,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          style: AppTextStyles.cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          courseSummary(l10n, course),
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.workoutCourseUp,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: onUp,
                  ),
                  IconButton(
                    tooltip: l10n.workoutCourseDown,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.arrow_downward),
                    onPressed: onDown,
                  ),
                  if (onRemove case final remove?)
                    IconButton(
                      tooltip: l10n.workoutCourseRemove,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close),
                      onPressed: remove,
                    )
                  else
                    IconButton(
                      tooltip: l10n.workoutCourseReplace,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.swap_horiz),
                      onPressed: onReplace,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CourseStrip(definition: course.definition),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the workout adds up to: all laps, the duration with the length of a
/// lap, or one lap when open.
class _Result extends StatelessWidget {
  const _Result({required this.axis, required this.lap, required this.length});

  final CourseAxis axis;

  /// The length of one lap: the sum of all courses.
  final int lap;
  final PlanLength length;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lapText = formatCourseLength(axis, lap);
    final (value, detail) = switch (length) {
      LapCount(:final count) => (
        formatCourseLength(axis, lap * count),
        '$count × $lapText',
      ),
      TimeLimit(:final time) => (
        formatElapsed(time),
        l10n.workoutResultDuration(lapText),
      ),
      OpenLength() => (lapText, l10n.workoutResultOpen),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.workoutResult, style: AppTextStyles.caption),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  key: const Key('workout-result'),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    detail,
                    key: const Key('workout-result-detail'),
                    textAlign: TextAlign.end,
                    style: AppTextStyles.subtitle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
