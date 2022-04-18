import 'package:flutter/widgets.dart';
import 'package:nc_photos/pref.dart';

class AppLanguage {
  const AppLanguage(this.langId, this.nativeName, this.isoName, this.locale);

  final int langId;
  final String nativeName;
  final String? isoName;
  final Locale? locale;
}

String getSelectedLanguageName() => _getSelectedLanguage().nativeName;
Locale? getSelectedLocale() => _getSelectedLanguage().locale;

final supportedLanguages = {
  _AppLanguageEnum.systemDefault.index: AppLanguage(
      _AppLanguageEnum.systemDefault.index, "System default", null, null),
  // sorted by alphabetic order of their ISO language names
  _AppLanguageEnum.czech.index: AppLanguage(
      _AppLanguageEnum.czech.index, "čeština", "Czech", const Locale("cs")),
  _AppLanguageEnum.english.index: AppLanguage(
      _AppLanguageEnum.english.index, "English", "English", const Locale("en")),
  _AppLanguageEnum.finnish.index: AppLanguage(
      _AppLanguageEnum.finnish.index, "suomi", "Finnish", const Locale("fi")),
  _AppLanguageEnum.french.index: AppLanguage(
      _AppLanguageEnum.french.index, "français", "French", const Locale("fr")),
  _AppLanguageEnum.german.index: AppLanguage(
      _AppLanguageEnum.german.index, "Deutsch", "German", const Locale("de")),
  _AppLanguageEnum.greek.index: AppLanguage(
      _AppLanguageEnum.greek.index, "ελληνικά", "Greek", const Locale("el")),
  _AppLanguageEnum.polish.index: AppLanguage(
      _AppLanguageEnum.polish.index, "język polski", "Polish", const Locale("pl")),
  _AppLanguageEnum.portuguese.index: AppLanguage(
      _AppLanguageEnum.portuguese.index, "Português", "Portuguese", const Locale("pt")),
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
  german,
  czech,
  finnish,
  polish,
  portuguese,
}

AppLanguage _getSelectedLanguage() {
  try {
    final lang = Pref().getLanguageOr(0);
    return supportedLanguages[lang]!;
  } catch (_) {
    return supportedLanguages[_AppLanguageEnum.systemDefault.index]!;
  }
}
