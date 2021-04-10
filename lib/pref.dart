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

  List<Account> getAccounts([List<Account> def]) {
    final jsonObjs = _pref.getStringList("accounts");
    return jsonObjs?.map((e) => Account.fromJson(jsonDecode(e)))?.toList() ??
        def;
  }

  Future<bool> setAccounts(List<Account> value) {
    final jsons = value.map((e) => jsonEncode(e.toJson())).toList();
    return _pref.setStringList("accounts", jsons);
  }

  int getCurrentAccountIndex([int def]) =>
      _pref.getInt("currentAccountIndex") ?? def;

  Future<bool> setCurrentAccountIndex(int value) =>
      _pref.setInt("currentAccountIndex", value);

  int getHomePhotosZoomLevel([int def]) =>
      _pref.getInt("homePhotosZoomLevel") ?? def;

  Future<bool> setHomePhotosZoomLevel(int value) =>
      _pref.setInt("homePhotosZoomLevel", value);

  int getAlbumViewerZoomLevel([int def]) =>
      _pref.getInt("albumViewerZoomLevel") ?? def;

  Future<bool> setAlbumViewerZoomLevel(int value) =>
      _pref.setInt("albumViewerZoomLevel", value);

  bool isEnableExif([bool def = true]) => _pref.getBool("isEnableExif") ?? def;

  Future<bool> setEnableExif(bool value) =>
      _pref.setBool("isEnableExif", value);

  int getSetupProgress([int def = 0]) => _pref.getInt("setupProgress") ?? def;

  Future<bool> setSetupProgress(int value) =>
      _pref.setInt("setupProgress", value);

  Pref._();

  static final _inst = Pref._();
  SharedPreferences _pref;
}

extension PrefExtension on Pref {
  Account getCurrentAccount() {
    try {
      return Pref.inst().getAccounts()[Pref.inst().getCurrentAccountIndex()];
    } catch (_) {
      return null;
    }
  }
}
