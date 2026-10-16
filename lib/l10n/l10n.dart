import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10n on BuildContext {
  /// The texts in the language of the app.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
