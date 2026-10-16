import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../data/courses/course.dart';
import '../../data/statistics/ranking.dart';
import '../../l10n/l10n.dart';
import '../connection/option_card.dart';
import 'ranking_format.dart';

/// Places 1–3 of each length of a course or zone, as the providers give
/// them with the current length first (Change statistics, Design D6); a
/// hint instead when nothing was rowed yet.
class RankingSections extends StatelessWidget {
  const RankingSections({super.key, required this.rankings, required this.axis, required this.length});

  final List<Ranking> rankings;

  /// The current axis and length of the course or zone, to mark its ranking.
  final CourseAxis axis;
  final int length;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (rankings.isEmpty) {
      return _Card(
        key: const Key('ranking-empty'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Text(l10n.rankingEmpty, style: AppTextStyles.subtitle),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final ranking in rankings) ...[
          SectionLabel(
            ranking.axis == axis && ranking.length == length
                ? l10n.rankingLengthCurrent(formatCourseLength(ranking.axis, ranking.length))
                : l10n.rankingLength(formatCourseLength(ranking.axis, ranking.length)),
          ),
          _Card(
            key: Key('ranking-${ranking.axis.name}-${ranking.length}'),
            child: Column(
              children: [
                for (final (i, entry) in ranking.entries.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  _PlaceRow(place: i + 1, axis: ranking.axis, entry: entry),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
        ],
        Text(l10n.rankingPausesHint, style: AppTextStyles.caption),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}

/// A place with its value, the date and the pace per 500 m.
class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.place, required this.axis, required this.entry});

  final int place;
  final CourseAxis axis;
  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final first = place == 1;
    return Padding(
      key: Key('place-$place'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: first ? AppColors.text : null,
              shape: BoxShape.circle,
              border: first ? null : Border.all(color: AppColors.line, width: 1.5),
            ),
            child: Text(
              '$place',
              semanticsLabel: l10n.rankingPlace(place),
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: first ? AppColors.bg : AppColors.text,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatRankingValue(axis, entry),
                  style: const TextStyle(fontFamily: AppFonts.display, fontSize: 24, fontWeight: FontWeight.w700),
                ),
                Text(formatRankingDate(l10n, entry), style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(l10n.rankingPace(formatRankingPace(entry)), style: AppTextStyles.subtitle),
        ],
      ),
    );
  }
}
