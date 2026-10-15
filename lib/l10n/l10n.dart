import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Convenience extension so widgets can write `context.l10n.someKey`
/// instead of the verbose `AppLocalizations.of(context)`.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
