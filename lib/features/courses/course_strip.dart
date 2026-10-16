import 'package:flutter/material.dart';

import '../../data/courses/course.dart';

/// A course as a bar: its zones in the primary colour, free gaps muted.
class CourseStrip extends StatelessWidget {
  const CourseStrip({super.key, required this.definition, this.height = 8});

  final CourseDefinition definition;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (final s in definition.segments)
              if (s.length > 0)
                Expanded(
                  flex: s.length,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    color: s.isFree ? colors.surfaceContainerHighest : colors.primary,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
