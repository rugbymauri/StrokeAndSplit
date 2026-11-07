import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/widgets/ghost_switch.dart';
import '../../data/workouts/workout_providers.dart';
import '../../l10n/l10n.dart';
import '../connection/rower_connection.dart';
import '../courses/course_strip.dart';
import '../courses/courses_screen.dart';
import 'workout_editor_screen.dart';
import 'workout_podium.dart';
import 'workouts_screen.dart';

/// Opens the screen of the workout with [workoutId].
Future<void> openWorkout(BuildContext context, int workoutId) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => WorkoutScreen(workoutId: workoutId),
    ),
  );
}

/// A workout with its zones and places 1–3, to start it with or without the
/// ghost and to edit it (Change template-screen, Design D1). It follows the
/// stored workout, so it shows a change from the editor; deleting the
/// workout closes it too.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key, required this.workoutId});

  final int workoutId;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  /// Whether the session started from here runs with its ghosts; on each time
  /// the screen opens and never stored (Design D5).
  var _ghost = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(workoutsProvider, (_, next) {
      if (next case AsyncData(:final value)
          when !value.any((t) => t.id == widget.workoutId)) {
        final route = ModalRoute.of(context);
        if (route != null && route.isActive) {
          Navigator.of(context).removeRoute(route);
        }
      }
    });
    final workout = ref
        .watch(workoutsProvider)
        .value
        ?.where((t) => t.id == widget.workoutId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(workout?.name ?? ''),
        actions: [
          if (workout != null)
            IconButton(
              key: const Key('workout-edit'),
              tooltip: l10n.workoutEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WorkoutEditorScreen(workout: workout),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: workout == null
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
                            Text(
                              workoutDetails(l10n, workout),
                              style: AppTextStyles.subtitle,
                            ),
                            const SizedBox(height: AppSpacing.m),
                            CourseStrip(definition: workout.chain.definition),
                            const SizedBox(height: AppSpacing.m),
                            if (workout.courses.length == 1)
                              for (final line in workoutZoneLines(
                                l10n,
                                workout.chain,
                              ))
                                Text(line, style: AppTextStyles.caption)
                            else
                              // Each course in its place with its zones
                              // (Change workout-course-chain).
                              for (final (i, course)
                                  in workout.courses.indexed) ...[
                                if (i > 0) const SizedBox(height: AppSpacing.m),
                                Text(
                                  course.name,
                                  key: Key('workout-course-$i'),
                                  style: AppTextStyles.cardTitle,
                                ),
                                Text(
                                  courseSummary(l10n, course),
                                  style: AppTextStyles.caption,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                CourseStrip(
                                  definition: course.definition,
                                  height: 10,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                for (final line in workoutZoneLines(
                                  l10n,
                                  course,
                                ))
                                  Text(line, style: AppTextStyles.caption),
                              ],
                            const SizedBox(height: AppSpacing.xxl),
                            WorkoutPodium(workout: workout),
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
                            GhostSwitch(
                              key: const Key('workout-ghost'),
                              value: _ghost,
                              onChanged: (value) =>
                                  setState(() => _ghost = value),
                            ),
                            const SizedBox(height: AppSpacing.s),
                            SizedBox(
                              height: 56,
                              child: FilledButton(
                                key: const Key('workout-start'),
                                onPressed: () => startRowing(
                                  context,
                                  ref,
                                  plan: workout.toPlan(),
                                  ghost: _ghost,
                                ),
                                child: Text(
                                  l10n.workoutStart,
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
}
