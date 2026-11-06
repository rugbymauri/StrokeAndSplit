import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../app_language.dart';

/// The language choice in the app bar (Design D8): opens a dialog with the
/// languages, and the chosen one applies at once.
class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    icon: const Icon(Icons.language),
    tooltip: context.l10n.languageChoice,
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    onPressed: () => _chooseLanguage(context, ref),
  );
}

Future<void> _chooseLanguage(BuildContext context, WidgetRef ref) async {
  final current = ref.read(appLanguageProvider);
  // Read before the dialog: the button may be rebuilt away while it is open, e.g. when a scan ends.
  final notifier = ref.read(appLanguageProvider.notifier);
  final chosen = await showDialog<AppLanguage>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(context.l10n.languageChoice),
      children: [
        for (final language in AppLanguage.values)
          SimpleDialogOption(
            key: Key('language-${language.name}'),
            onPressed: () => Navigator.of(context).pop(language),
            child: ListTile(
              title: Text(language.nativeName),
              trailing: language == current ? const Icon(Icons.check) : null,
            ),
          ),
      ],
    ),
  );
  if (chosen != null) await notifier.choose(chosen);
}
