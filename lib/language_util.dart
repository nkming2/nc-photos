import 'package:flutter/widgets.dart';
import 'package:nc_photos/pref.dart';

class AppLanguage {
  const AppLanguage(this.langId, this.nativeName, this.isoName, this.locale);

  final int langId;
  final String nativeName;
  final String? isoName;
  final Locale? locale;
}

String getSelectedLanguageName(BuildContext context) =>
    _getSelectedLanguage(context).nativeName;
Locale? getSelectedLocale(BuildContext context) =>
    _getSelectedLanguage(context).locale;

final supportedLanguages = {
  _AppLanguageEnum.systemDefault.index: AppLanguage(
      _AppLanguageEnum.systemDefault.index, "System default", null, null),
  // sorted by alphabetic order of their ISO language names
  _AppLanguageEnum.english.index: AppLanguage(
      _AppLanguageEnum.english.index, "English", "English", const Locale("en")),
  _AppLanguageEnum.french.index: AppLanguage(
      _AppLanguageEnum.french.index, "français", "French", const Locale("fr")),
  _AppLanguageEnum.greek.index: AppLanguage(
      _AppLanguageEnum.greek.index, "ελληνικά", "Greek", const Locale("el")),
  _AppLanguageEnum.russian.index: AppLanguage(
      _AppLanguageEnum.russian.index, "русский", "Russian", const Locale("ru")),
  _AppLanguageEnum.spanish.index: AppLanguage(
      _AppLanguageEnum.spanish.index, "Español", "Spanish", const Locale("es")),
};

enum _AppLanguageEnum {
  // the order must not be changed
  systemDefault,
  english,
  spanish,
  greek,
  french,
  russian,
}

AppLanguage _getSelectedLanguage(BuildContext context) {
  try {
    final lang = Pref.inst().getLanguageOr(0);
    return supportedLanguages[lang]!;
  } catch (_) {
    return supportedLanguages[_AppLanguageEnum.systemDefault.index]!;
  }
}
