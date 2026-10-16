import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10n on BuildContext {
  /// The texts in the language of the app.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension QuotedNames on AppLocalizations {
  /// [names] the user gave, each in quotes, separated by commas.
  String quotedNames(Iterable<String> names) => names.map(quotedName).join(', ');
}
