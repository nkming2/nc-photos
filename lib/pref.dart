import 'dart:convert';

import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/type.dart';
import 'package:nc_photos/use_case/compat/v32.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pref {
  static Future<void> init() async {
    if (await CompatV32.isPrefNeedMigration()) {
      await CompatV32.migratePref();
    }
    return SharedPreferences.getInstance().then((pref) {
      _inst._pref = pref;
    });
  }

  factory Pref.inst() => _inst;

  List<PrefAccount>? getAccounts2() {
    final jsonObjs = _pref.getStringList(_toKey(PrefKey.accounts2));
    return jsonObjs?.map((e) => PrefAccount.fromJson(jsonDecode(e))).toList();
  }

  List<PrefAccount> getAccounts2Or(List<PrefAccount> def) =>
      getAccounts2() ?? def;
  Future<bool> setAccounts2(List<PrefAccount> value) {
    final jsons = value.map((e) => jsonEncode(e.toJson())).toList();
    return _setStringList(PrefKey.accounts2, jsons);
  }

  int? getCurrentAccountIndex() =>
      _pref.getInt(_toKey(PrefKey.currentAccountIndex));
  int getCurrentAccountIndexOr(int def) => getCurrentAccountIndex() ?? def;
  Future<bool> setCurrentAccountIndex(int value) =>
      _setInt(PrefKey.currentAccountIndex, value);

  int? getHomePhotosZoomLevel() =>
      _pref.getInt(_toKey(PrefKey.homePhotosZoomLevel));
  int getHomePhotosZoomLevelOr(int def) => getHomePhotosZoomLevel() ?? def;
  Future<bool> setHomePhotosZoomLevel(int value) =>
      _setInt(PrefKey.homePhotosZoomLevel, value);

  int? getAlbumBrowserZoomLevel() =>
      _pref.getInt(_toKey(PrefKey.albumBrowserZoomLevel));
  int getAlbumBrowserZoomLevelOr(int def) => getAlbumBrowserZoomLevel() ?? def;
  Future<bool> setAlbumBrowserZoomLevel(int value) =>
      _setInt(PrefKey.albumBrowserZoomLevel, value);

  int? getHomeAlbumsSort() => _pref.getInt(_toKey(PrefKey.homeAlbumsSort));
  int getHomeAlbumsSortOr(int def) => getHomeAlbumsSort() ?? def;
  Future<bool> setHomeAlbumsSort(int value) =>
      _setInt(PrefKey.homeAlbumsSort, value);

  bool? isEnableExif() => _pref.getBool(_toKey(PrefKey.enableExif));
  bool isEnableExifOr([bool def = true]) => isEnableExif() ?? def;
  Future<bool> setEnableExif(bool value) => _setBool(PrefKey.enableExif, value);

  int? getViewerScreenBrightness() =>
      _pref.getInt(_toKey(PrefKey.viewerScreenBrightness));
  int getViewerScreenBrightnessOr([int def = -1]) =>
      getViewerScreenBrightness() ?? def;
  Future<bool> setViewerScreenBrightness(int value) =>
      _setInt(PrefKey.viewerScreenBrightness, value);

  bool? isViewerForceRotation() =>
      _pref.getBool(_toKey(PrefKey.viewerForceRotation));
  bool isViewerForceRotationOr([bool def = false]) =>
      isViewerForceRotation() ?? def;
  Future<bool> setViewerForceRotation(bool value) =>
      _setBool(PrefKey.viewerForceRotation, value);

  int? getSetupProgress() => _pref.getInt(_toKey(PrefKey.setupProgress));
  int getSetupProgressOr([int def = 0]) => getSetupProgress() ?? def;
  Future<bool> setSetupProgress(int value) =>
      _setInt(PrefKey.setupProgress, value);

  /// Return the version number when the app last ran
  int? getLastVersion() => _pref.getInt(_toKey(PrefKey.lastVersion));
  int getLastVersionOr(int def) => getLastVersion() ?? def;
  Future<bool> setLastVersion(int value) => _setInt(PrefKey.lastVersion, value);

  bool? isDarkTheme() => _pref.getBool(_toKey(PrefKey.darkTheme));
  bool isDarkThemeOr(bool def) => isDarkTheme() ?? def;
  Future<bool> setDarkTheme(bool value) => _setBool(PrefKey.darkTheme, value);

  bool? isFollowSystemTheme() =>
      _pref.getBool(_toKey(PrefKey.followSystemTheme));
  bool isFollowSystemThemeOr(bool def) => isFollowSystemTheme() ?? def;
  Future<bool> setFollowSystemTheme(bool value) =>
      _setBool(PrefKey.followSystemTheme, value);

  bool? isUseBlackInDarkTheme() =>
      _pref.getBool(_toKey(PrefKey.useBlackInDarkTheme));
  bool isUseBlackInDarkThemeOr(bool def) => isUseBlackInDarkTheme() ?? def;
  Future<bool> setUseBlackInDarkTheme(bool value) =>
      _setBool(PrefKey.useBlackInDarkTheme, value);

  int? getLanguage() => _pref.getInt(_toKey(PrefKey.language));
  int getLanguageOr(int def) => getLanguage() ?? def;
  Future<bool> setLanguage(int value) => _setInt(PrefKey.language, value);

  int? getSlideshowDuration() =>
      _pref.getInt(_toKey(PrefKey.slideshowDuration));
  int getSlideshowDurationOr(int def) => getSlideshowDuration() ?? def;
  Future<bool> setSlideshowDuration(int value) =>
      _setInt(PrefKey.slideshowDuration, value);

  bool? isSlideshowShuffle() =>
      _pref.getBool(_toKey(PrefKey.isSlideshowShuffle));
  bool isSlideshowShuffleOr(bool def) => isSlideshowShuffle() ?? def;
  Future<bool> setSlideshowShuffle(bool value) =>
      _setBool(PrefKey.isSlideshowShuffle, value);

  bool? isSlideshowRepeat() => _pref.getBool(_toKey(PrefKey.isSlideshowRepeat));
  bool isSlideshowRepeatOr(bool def) => isSlideshowRepeat() ?? def;
  Future<bool> setSlideshowRepeat(bool value) =>
      _setBool(PrefKey.isSlideshowRepeat, value);

  bool? isAlbumBrowserShowDate() =>
      _pref.getBool(_toKey(PrefKey.isAlbumBrowserShowDate));
  bool isAlbumBrowserShowDateOr([bool def = false]) =>
      isAlbumBrowserShowDate() ?? def;
  Future<bool> setAlbumBrowserShowDate(bool value) =>
      _setBool(PrefKey.isAlbumBrowserShowDate, value);

  bool? hasNewSharedAlbum() => _pref.getBool(_toKey(PrefKey.newSharedAlbum));
  bool hasNewSharedAlbumOr(bool def) => hasNewSharedAlbum() ?? def;
  Future<bool> setNewSharedAlbum(bool value) =>
      _setBool(PrefKey.newSharedAlbum, value);

  bool? isLabEnableSharedAlbum() =>
      _pref.getBool(_toKey(PrefKey.labEnableSharedAlbum));
  bool isLabEnableSharedAlbumOr(bool def) => isLabEnableSharedAlbum() ?? def;
  Future<bool> setLabEnableSharedAlbum(bool value) =>
      _setBool(PrefKey.labEnableSharedAlbum, value);

  Pref._();

  Future<bool> _setBool(PrefKey key, bool value) async {
    return _onPostSet(await _pref.setBool(_toKey(key), value), key, value);
  }

  Future<bool> _setInt(PrefKey key, int value) async {
    return _onPostSet(await _pref.setInt(_toKey(key), value), key, value);
  }

  Future<bool> _setStringList(PrefKey key, List<String> value) async {
    return _onPostSet(
        await _pref.setStringList(_toKey(key), value), key, value);
  }

  bool _onPostSet(bool result, PrefKey key, dynamic value) {
    if (result) {
      KiwiContainer().resolve<EventBus>().fire(PrefUpdatedEvent(key, value));
      return true;
    } else {
      return false;
    }
  }

  String _toKey(PrefKey key) {
    switch (key) {
      case PrefKey.accounts2:
        return "accounts2";
      case PrefKey.currentAccountIndex:
        return "currentAccountIndex";
      case PrefKey.homePhotosZoomLevel:
        return "homePhotosZoomLevel";
      case PrefKey.albumBrowserZoomLevel:
        return "albumViewerZoomLevel";
      case PrefKey.homeAlbumsSort:
        return "homeAlbumsSort";
      case PrefKey.enableExif:
        return "isEnableExif";
      case PrefKey.viewerScreenBrightness:
        return "viewerScreenBrightness";
      case PrefKey.viewerForceRotation:
        return "viewerForceRotation";
      case PrefKey.setupProgress:
        return "setupProgress";
      case PrefKey.lastVersion:
        return "lastVersion";
      case PrefKey.darkTheme:
        return "isDarkTheme";
      case PrefKey.followSystemTheme:
        return "isFollowSystemTheme";
      case PrefKey.useBlackInDarkTheme:
        return "isUseBlackInDarkTheme";
      case PrefKey.language:
        return "language";
      case PrefKey.newSharedAlbum:
        return "hasNewSharedAlbum";
      case PrefKey.labEnableSharedAlbum:
        return "isLabEnableSharedAlbum";
      case PrefKey.slideshowDuration:
        return "slideshowDuration";
      case PrefKey.isSlideshowShuffle:
        return "isSlideshowShuffle";
      case PrefKey.isSlideshowRepeat:
        return "isSlideshowRepeat";
      case PrefKey.isAlbumBrowserShowDate:
        return "isAlbumBrowserShowDate";
    }
  }

  static final _inst = Pref._();
  late SharedPreferences _pref;
}

class PrefAccount {
  const PrefAccount(
    this.account, [
    this.settings = const AccountSettings(),
  ]);

  factory PrefAccount.fromJson(JsonObj json) {
    return PrefAccount(
      Account.fromJson(json["account"].cast<String, dynamic>()),
      AccountSettings.fromJson(json["settings"].cast<String, dynamic>()),
    );
  }

  JsonObj toJson() => {
        "account": account.toJson(),
        "settings": settings.toJson(),
      };

  PrefAccount copyWith({
    Account? account,
    AccountSettings? settings,
  }) {
    return PrefAccount(
      account ?? this.account,
      settings ?? this.settings,
    );
  }

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "settings: $settings, "
        "}";
  }

  final Account account;
  final AccountSettings settings;
}

enum PrefKey {
  accounts2,
  currentAccountIndex,
  homePhotosZoomLevel,
  albumBrowserZoomLevel,
  homeAlbumsSort,
  enableExif,
  viewerScreenBrightness,
  viewerForceRotation,
  setupProgress,
  lastVersion,
  darkTheme,
  followSystemTheme,
  useBlackInDarkTheme,
  language,
  newSharedAlbum,
  labEnableSharedAlbum,
  slideshowDuration,
  isSlideshowShuffle,
  isSlideshowRepeat,
  isAlbumBrowserShowDate,
}

extension PrefExtension on Pref {
  Account? getCurrentAccount() {
    try {
      return Pref.inst()
          .getAccounts2()![Pref.inst().getCurrentAccountIndex()!]
          .account;
    } catch (_) {
      return null;
    }
  }
}
