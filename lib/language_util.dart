import 'package:flutter/widgets.dart';
import 'package:nc_photos/pref.dart';

class AppLanguage {
  const AppLanguage(this.langId, this.nativeName, this.locale);

  final int langId;
  final String nativeName;
  final Locale? locale;
}

String getSelectedLanguageName(BuildContext context) =>
    _getSelectedLanguage(context).nativeName;
Locale? getSelectedLocale(BuildContext context) =>
    _getSelectedLanguage(context).locale;

final supportedLanguages = {
  _AppLanguageEnum.systemDefault.index:
      AppLanguage(_AppLanguageEnum.systemDefault.index, "System default", null),
  _AppLanguageEnum.english.index: AppLanguage(
      _AppLanguageEnum.english.index, "English", const Locale("en")),
  _AppLanguageEnum.spanish.index: AppLanguage(
      _AppLanguageEnum.spanish.index, "Español", const Locale("es")),
};

enum _AppLanguageEnum {
  // the order must not be changed
  systemDefault,
  english,
  spanish,
}

AppLanguage _getSelectedLanguage(BuildContext context) {
  try {
    final lang = Pref.inst().getLanguageOr(0);
    return supportedLanguages[lang]!;
  } catch (_) {
    return supportedLanguages[_AppLanguageEnum.systemDefault.index]!;
  }
}
