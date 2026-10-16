import 'package:flutter/material.dart';

/// What keeps an editor from saving, above its fields.
class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.errors});

  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final e in errors) Text(e, style: TextStyle(color: colors.onErrorContainer))],
        ),
      ),
    );
  }
}
