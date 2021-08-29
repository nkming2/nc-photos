import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:nc_photos/widget/my_app.dart';

/// Simplify localized string access
class L10n {
  static AppLocalizations global() => AppLocalizations.of(MyApp.globalContext)!;
}
