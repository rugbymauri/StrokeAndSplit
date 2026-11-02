import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// What the app writes to Health Connect and what it does not; Health Connect opens it too (Change
/// health-connect, Spec „Datenschutz-Hinweis“).
class HealthPrivacyScreen extends StatelessWidget {
  const HealthPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final paragraphs = [
      l10n.healthPrivacyWhat,
      l10n.healthPrivacyKept,
      l10n.healthPrivacyNoRead,
      l10n.healthPrivacyDevice,
      l10n.healthPrivacyStop,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.healthPrivacyTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final text in paragraphs)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(text)),
          ],
        ),
      ),
    );
  }
}
