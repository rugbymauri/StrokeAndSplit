import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/oar_stepper.dart';
import '../../app/widgets/segment_choice.dart';
import '../../data/courses/course.dart';
import '../../data/courses/course_providers.dart';
import '../../data/sessions/session_plan.dart';
import '../../data/workouts/workout.dart';
import '../../data/workouts/workout_providers.dart';
import '../../l10n/l10n.dart';
import '../courses/course_strip.dart';
import '../courses/courses_screen.dart';

/// Creates a workout, or edits [workout] when given.
class WorkoutEditorScreen extends ConsumerStatefulWidget {
  const WorkoutEditorScreen({super.key, this.workout});

  final Workout? workout;

  @override
  ConsumerState<WorkoutEditorScreen> createState() =>
      _WorkoutEditorScreenState();
}

/// More laps than anyone rows in one session.
const _maxLaps = 99;

class _WorkoutEditorScreenState extends ConsumerState<WorkoutEditorScreen> {
  late final _name = TextEditingController(text: widget.workout?.name);
  late var _laps = widget.workout?.laps ?? 3;
  late int? _courseId = widget.workout?.courses.first.id;
  late var _open = widget.workout?.length is OpenLength;
  var _errors = <String>[];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final laps = _open ? null : _laps;
    final l10n = context.l10n;
    final errors = [
      if (name.isEmpty) l10n.workoutNameMissing,
      if (_courseId == null) l10n.workoutCourseMissing,
    ];
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    final repository = ref.read(workoutRepositoryProvider);
    final workout = widget.workout;
    if (workout == null) {
      await repository.create(
        name,
        courseIds: [_courseId!],
        length: laps == null ? const OpenLength() : LapCount(laps),
      );
    } else {
      await repository.update(
        workout.id,
        name: name,
        courseIds: [_courseId!],
        length: laps == null ? const OpenLength() : LapCount(laps),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

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
    final courses = ref.watch(coursesProvider).value ?? const <Course>[];
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final course = courses.where((c) => c.id == _courseId).firstOrNull;
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
                DropdownButtonFormField<int>(
                  key: const Key('workout-course'),
                  initialValue: courses.any((c) => c.id == _courseId)
                      ? _courseId
                      : null,
                  decoration: InputDecoration(labelText: l10n.workoutCourse),
                  items: [
                    for (final c in courses)
                      DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.name} · ${courseSummary(l10n, c)}'),
                      ),
                  ],
                  onChanged: (id) => setState(() => _courseId = id),
                ),
                if (course != null) ...[
                  const SizedBox(height: 8),
                  CourseStrip(definition: course.definition),
                ],
                const SizedBox(height: 24),
                Text(
                  l10n.workoutLaps.toUpperCase(),
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 10),
                SegmentChoice(
                  options: [
                    (false, l10n.workoutFixedLaps),
                    (true, l10n.workoutOpenLaps),
                  ],
                  value: _open,
                  onChanged: (open) => setState(() => _open = open),
                ),
                if (!_open) ...[
                  const SizedBox(height: 10),
                  OarStepper(
                    key: const Key('workout-laps'),
                    value: _laps,
                    step: 1,
                    min: 1,
                    max: _maxLaps,
                    stepLabel: l10n.lapsCount(1),
                    label: l10n.workoutLaps,
                    unit: l10n.workoutLapsUnit(_laps),
                    onChanged: (laps) => setState(() => _laps = laps),
                  ),
                ],
                if (course != null) ...[
                  const SizedBox(height: 22),
                  _Result(course: course, laps: _open ? null : _laps),
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

/// What the laps add up to: the whole length, or one lap when [laps] is open.
class _Result extends StatelessWidget {
  const _Result({required this.course, required this.laps});

  final Course course;
  final int? laps;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lap = course.definition.length;
    final laps = this.laps;
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
                  formatCourseLength(
                    course.axis,
                    laps == null ? lap : lap * laps,
                  ),
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
                    laps == null
                        ? l10n.workoutResultOpen
                        : '$laps × ${formatCourseLength(course.axis, lap)}',
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
