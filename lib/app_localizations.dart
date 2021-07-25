import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Simplify localized string access
class L10n {
  static AppLocalizations of(BuildContext context) =>
      AppLocalizations.of(context)!;
}
