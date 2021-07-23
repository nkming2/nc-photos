import 'dart:convert';

import 'package:nc_photos/account.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pref {
  static Future<void> init() async {
    return SharedPreferences.getInstance().then((pref) {
      _inst._pref = pref;
    });
  }

  factory Pref.inst() => _inst;

  List<Account>? getAccounts() {
    final jsonObjs = _pref.getStringList("accounts");
    return jsonObjs?.map((e) => Account.fromJson(jsonDecode(e))).toList();
  }

  List<Account> getAccountsOr(List<Account> def) => getAccounts() ?? def;
  Future<bool> setAccounts(List<Account> value) {
    final jsons = value.map((e) => jsonEncode(e.toJson())).toList();
    return _pref.setStringList("accounts", jsons);
  }

  int? getCurrentAccountIndex() => _pref.getInt("currentAccountIndex");
  int getCurrentAccountIndexOr(int def) => getCurrentAccountIndex() ?? def;
  Future<bool> setCurrentAccountIndex(int value) =>
      _pref.setInt("currentAccountIndex", value);

  int? getHomePhotosZoomLevel() => _pref.getInt("homePhotosZoomLevel");
  int getHomePhotosZoomLevelOr(int def) => getHomePhotosZoomLevel() ?? def;
  Future<bool> setHomePhotosZoomLevel(int value) =>
      _pref.setInt("homePhotosZoomLevel", value);

  int? getAlbumViewerZoomLevel() => _pref.getInt("albumViewerZoomLevel");
  int getAlbumViewerZoomLevelOr(int def) => getAlbumViewerZoomLevel() ?? def;
  Future<bool> setAlbumViewerZoomLevel(int value) =>
      _pref.setInt("albumViewerZoomLevel", value);

  bool? isEnableExif() => _pref.getBool("isEnableExif");
  bool isEnableExifOr([bool def = true]) => isEnableExif() ?? def;
  Future<bool> setEnableExif(bool value) =>
      _pref.setBool("isEnableExif", value);

  int? getSetupProgress() => _pref.getInt("setupProgress");
  int getSetupProgressOr([int def = 0]) => getSetupProgress() ?? def;
  Future<bool> setSetupProgress(int value) =>
      _pref.setInt("setupProgress", value);

  /// Return the version number when the app last ran
  int? getLastVersion() => _pref.getInt("lastVersion");
  int getLastVersionOr(int def) => getLastVersion() ?? def;
  Future<bool> setLastVersion(int value) => _pref.setInt("lastVersion", value);

  bool? isDarkTheme() => _pref.getBool("isDarkTheme");
  bool isDarkThemeOr(bool def) => isDarkTheme() ?? def;
  Future<bool> setDarkTheme(bool value) => _pref.setBool("isDarkTheme", value);

  int? getLanguage() => _pref.getInt("language");
  int getLanguageOr(int def) => getLanguage() ?? def;
  Future<bool> setLanguage(int value) => _pref.setInt("language", value);

  Pref._();

  static final _inst = Pref._();
  late SharedPreferences _pref;
}

extension PrefExtension on Pref {
  Account? getCurrentAccount() {
    try {
      return Pref.inst().getAccounts()![Pref.inst().getCurrentAccountIndex()!];
    } catch (_) {
      return null;
    }
  }
}
