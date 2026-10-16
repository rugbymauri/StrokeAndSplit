import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/design_tokens.dart';
import '../../data/courses/course.dart';
import '../../data/statistics/ranking.dart';
import '../../data/statistics/ranking_providers.dart';
import '../../data/templates/session_template.dart';
import '../../l10n/l10n.dart';
import '../live/formatters.dart';

/// Room next to the value of place 1 for the ghost symbol of `ghost`.
const templateGhostSlotWidth = 20.0;

/// Places 1–3 of [template] for its current course length and number of
/// laps, with value, pace and date; a hint instead without an entry or with
/// an open number of laps (Change statistics, Design D6).
class TemplatePodium extends ConsumerWidget {
  const TemplatePodium({super.key, required this.template});

  final SessionTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final laps = template.laps;
    if (laps == null) return _Hint(l10n.templatePodiumOpenLaps);
    final rankings = ref.watch(templateRankingsProvider(template.id));
    final course = template.course;
    return switch (rankings) {
      AsyncData(:final value) => switch (_current(value, course, laps)) {
          final Ranking ranking when ranking.entries.isNotEmpty => _Places(ranking: ranking),
          _ => _Hint(l10n.templatePodiumEmpty),
        },
      // Places are an extra; while loading or on an error the card stays as it is.
      _ => const SizedBox.shrink(),
    };
  }

  /// The ranking of the course length and number of laps rowed today.
  static Ranking? _current(List<Ranking> rankings, Course course, int laps) {
    for (final r in rankings) {
      if (r.axis == course.axis && r.length == course.definition.length && r.laps == laps) return r;
    }
    return null;
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, key: const Key('template-podium-hint'), style: AppTextStyles.caption);
}

class _Places extends StatelessWidget {
  const _Places({required this.ranking});

  final Ranking ranking;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      key: const Key('template-podium'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.templatePodiumTitle.toUpperCase(), style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.xs),
        for (final (i, entry) in ranking.entries.indexed) _Place(place: i + 1, axis: ranking.axis, entry: entry),
      ],
    );
  }
}

/// `1  12:34.5  ◆  2:05.7 /500 m       01.10.2026`
class _Place extends StatelessWidget {
  const _Place({required this.place, required this.axis, required this.entry});

  final int place;
  final CourseAxis axis;
  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final paceCs = entry.paceCs;
    final value = switch (axis) {
      CourseAxis.distance => formatLapTime(Duration(milliseconds: entry.durationMs)),
      CourseAxis.time => '${formatGrouped(entry.distanceDm ~/ 10)} m',
    };
    return Padding(
      key: Key('template-place-$place'),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 20,
            child: Text('$place', style: AppTextStyles.cardTitle.copyWith(color: AppColors.textMuted)),
          ),
          Text(value, style: AppTextStyles.cardTitle.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          // Place 1 keeps room for the ghost symbol; the others keep the columns aligned.
          SizedBox(key: place == 1 ? const Key('template-ghost-slot') : null, width: templateGhostSlotWidth),
          Expanded(
            child: Text(
              l10n.templatePodiumPace(formatPace(paceCs == null ? null : Duration(milliseconds: paceCs * 10))),
              style: AppTextStyles.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(DateFormat.yMd(l10n.localeName).format(entry.rowedAt.toLocal()), style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
