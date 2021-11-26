import 'dart:convert';

import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/type.dart';
import 'package:nc_photos/use_case/compat/v32.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pref {
  factory Pref() {
    _inst ??= Pref.scoped(PrefMemoryProvider());
    return _inst!;
  }

  Pref.scoped(this.provider);

  /// Set the global [Pref] instance returned by the default constructor
  static void setGlobalInstance(Pref pref) {
    assert(_inst == null);
    _inst = pref;
  }

  List<PrefAccount>? getAccounts2() {
    final jsonObjs = provider.getStringList(PrefKey.accounts2);
    return jsonObjs?.map((e) => PrefAccount.fromJson(jsonDecode(e))).toList();
  }

  List<PrefAccount> getAccounts2Or(List<PrefAccount> def) =>
      getAccounts2() ?? def;
  Future<bool> setAccounts2(List<PrefAccount> value) {
    final jsons = value.map((e) => jsonEncode(e.toJson())).toList();
    return provider.setStringList(PrefKey.accounts2, jsons);
  }

  int? getCurrentAccountIndex() => provider.getInt(PrefKey.currentAccountIndex);
  int getCurrentAccountIndexOr(int def) => getCurrentAccountIndex() ?? def;
  Future<bool> setCurrentAccountIndex(int value) =>
      provider.setInt(PrefKey.currentAccountIndex, value);

  int? getHomePhotosZoomLevel() => provider.getInt(PrefKey.homePhotosZoomLevel);
  int getHomePhotosZoomLevelOr(int def) => getHomePhotosZoomLevel() ?? def;
  Future<bool> setHomePhotosZoomLevel(int value) =>
      provider.setInt(PrefKey.homePhotosZoomLevel, value);

  int? getAlbumBrowserZoomLevel() =>
      provider.getInt(PrefKey.albumBrowserZoomLevel);
  int getAlbumBrowserZoomLevelOr(int def) => getAlbumBrowserZoomLevel() ?? def;
  Future<bool> setAlbumBrowserZoomLevel(int value) =>
      provider.setInt(PrefKey.albumBrowserZoomLevel, value);

  int? getHomeAlbumsSort() => provider.getInt(PrefKey.homeAlbumsSort);
  int getHomeAlbumsSortOr(int def) => getHomeAlbumsSort() ?? def;
  Future<bool> setHomeAlbumsSort(int value) =>
      provider.setInt(PrefKey.homeAlbumsSort, value);

  bool? isEnableExif() => provider.getBool(PrefKey.enableExif);
  bool isEnableExifOr([bool def = true]) => isEnableExif() ?? def;
  Future<bool> setEnableExif(bool value) =>
      provider.setBool(PrefKey.enableExif, value);

  int? getViewerScreenBrightness() =>
      provider.getInt(PrefKey.viewerScreenBrightness);
  int getViewerScreenBrightnessOr([int def = -1]) =>
      getViewerScreenBrightness() ?? def;
  Future<bool> setViewerScreenBrightness(int value) =>
      provider.setInt(PrefKey.viewerScreenBrightness, value);

  bool? isViewerForceRotation() =>
      provider.getBool(PrefKey.viewerForceRotation);
  bool isViewerForceRotationOr([bool def = false]) =>
      isViewerForceRotation() ?? def;
  Future<bool> setViewerForceRotation(bool value) =>
      provider.setBool(PrefKey.viewerForceRotation, value);

  int? getSetupProgress() => provider.getInt(PrefKey.setupProgress);
  int getSetupProgressOr([int def = 0]) => getSetupProgress() ?? def;
  Future<bool> setSetupProgress(int value) =>
      provider.setInt(PrefKey.setupProgress, value);

  /// Return the version number when the app last ran
  int? getLastVersion() => provider.getInt(PrefKey.lastVersion);
  int getLastVersionOr(int def) => getLastVersion() ?? def;
  Future<bool> setLastVersion(int value) =>
      provider.setInt(PrefKey.lastVersion, value);

  bool? isDarkTheme() => provider.getBool(PrefKey.darkTheme);
  bool isDarkThemeOr(bool def) => isDarkTheme() ?? def;
  Future<bool> setDarkTheme(bool value) =>
      provider.setBool(PrefKey.darkTheme, value);

  bool? isFollowSystemTheme() => provider.getBool(PrefKey.followSystemTheme);
  bool isFollowSystemThemeOr(bool def) => isFollowSystemTheme() ?? def;
  Future<bool> setFollowSystemTheme(bool value) =>
      provider.setBool(PrefKey.followSystemTheme, value);

  bool? isUseBlackInDarkTheme() =>
      provider.getBool(PrefKey.useBlackInDarkTheme);
  bool isUseBlackInDarkThemeOr(bool def) => isUseBlackInDarkTheme() ?? def;
  Future<bool> setUseBlackInDarkTheme(bool value) =>
      provider.setBool(PrefKey.useBlackInDarkTheme, value);

  int? getLanguage() => provider.getInt(PrefKey.language);
  int getLanguageOr(int def) => getLanguage() ?? def;
  Future<bool> setLanguage(int value) =>
      provider.setInt(PrefKey.language, value);

  int? getSlideshowDuration() => provider.getInt(PrefKey.slideshowDuration);
  int getSlideshowDurationOr(int def) => getSlideshowDuration() ?? def;
  Future<bool> setSlideshowDuration(int value) =>
      provider.setInt(PrefKey.slideshowDuration, value);

  bool? isSlideshowShuffle() => provider.getBool(PrefKey.isSlideshowShuffle);
  bool isSlideshowShuffleOr(bool def) => isSlideshowShuffle() ?? def;
  Future<bool> setSlideshowShuffle(bool value) =>
      provider.setBool(PrefKey.isSlideshowShuffle, value);

  bool? isSlideshowRepeat() => provider.getBool(PrefKey.isSlideshowRepeat);
  bool isSlideshowRepeatOr(bool def) => isSlideshowRepeat() ?? def;
  Future<bool> setSlideshowRepeat(bool value) =>
      provider.setBool(PrefKey.isSlideshowRepeat, value);

  bool? isAlbumBrowserShowDate() =>
      provider.getBool(PrefKey.isAlbumBrowserShowDate);
  bool isAlbumBrowserShowDateOr([bool def = false]) =>
      isAlbumBrowserShowDate() ?? def;
  Future<bool> setAlbumBrowserShowDate(bool value) =>
      provider.setBool(PrefKey.isAlbumBrowserShowDate, value);

  bool? hasNewSharedAlbum() => provider.getBool(PrefKey.newSharedAlbum);
  bool hasNewSharedAlbumOr(bool def) => hasNewSharedAlbum() ?? def;
  Future<bool> setNewSharedAlbum(bool value) =>
      provider.setBool(PrefKey.newSharedAlbum, value);

  int? getGpsMapProvider() => provider.getInt(PrefKey.gpsMapProvider);
  int getGpsMapProviderOr(int def) => getGpsMapProvider() ?? def;
  Future<bool> setGpsMapProvider(int value) =>
      provider.setInt(PrefKey.gpsMapProvider, value);

  bool? isLabEnableSharedAlbum() =>
      provider.getBool(PrefKey.labEnableSharedAlbum);
  bool isLabEnableSharedAlbumOr(bool def) => isLabEnableSharedAlbum() ?? def;
  Future<bool> setLabEnableSharedAlbum(bool value) =>
      provider.setBool(PrefKey.labEnableSharedAlbum, value);

  bool? hasShownSharedAlbumInfo() =>
      provider.getBool(PrefKey.hasShownSharedAlbumInfo);
  bool hasShownSharedAlbumInfoOr(bool def) => hasShownSharedAlbumInfo() ?? def;
  Future<bool> setHasShownSharedAlbumInfo(bool value) =>
      provider.setBool(PrefKey.hasShownSharedAlbumInfo, value);

  final PrefProvider provider;

  static Pref? _inst;
}

/// Provide the data for [Pref]
abstract class PrefProvider {
  bool? getBool(PrefKey key);
  Future<bool> setBool(PrefKey key, bool value);

  int? getInt(PrefKey key);
  Future<bool> setInt(PrefKey key, int value);

  List<String>? getStringList(PrefKey key);
  Future<bool> setStringList(PrefKey key, List<String> value);

  bool _onPostSet(bool result, PrefKey key, dynamic value) {
    if (result) {
      KiwiContainer().resolve<EventBus>().fire(PrefUpdatedEvent(key, value));
      return true;
    } else {
      return false;
    }
  }
}

/// [Pref] stored with [SharedPreferences] lib
class PrefSharedPreferencesProvider extends PrefProvider {
  Future<void> init() async {
    if (await CompatV32.isPrefNeedMigration()) {
      await CompatV32.migratePref();
    }
    return SharedPreferences.getInstance().then((pref) {
      _pref = pref;
    });
  }

  @override
  getBool(PrefKey key) => _pref.getBool(key.toStringKey());

  @override
  setBool(PrefKey key, bool value) async {
    return _onPostSet(
        await _pref.setBool(key.toStringKey(), value), key, value);
  }

  @override
  getInt(PrefKey key) => _pref.getInt(key.toStringKey());

  @override
  setInt(PrefKey key, int value) async {
    return _onPostSet(await _pref.setInt(key.toStringKey(), value), key, value);
  }

  @override
  getStringList(PrefKey key) => _pref.getStringList(key.toStringKey());

  @override
  setStringList(PrefKey key, List<String> value) async {
    return _onPostSet(
        await _pref.setStringList(key.toStringKey(), value), key, value);
  }

  late SharedPreferences _pref;
}

/// [Pref] stored in memory
class PrefMemoryProvider extends PrefProvider {
  PrefMemoryProvider([
    Map<String, dynamic> initialData = const <String, dynamic>{},
  ]) : _data = Map.of(initialData);

  @override
  getBool(PrefKey key) => _data[key.toStringKey()];

  @override
  setBool(PrefKey key, bool value) async {
    return _onPostSet(() {
      _data[key.toStringKey()] = value;
      return true;
    }(), key, value);
  }

  @override
  getInt(PrefKey key) => _data[key.toStringKey()];

  @override
  setInt(PrefKey key, int value) async {
    return _onPostSet(() {
      _data[key.toStringKey()] = value;
      return true;
    }(), key, value);
  }

  @override
  getStringList(PrefKey key) => _data[key.toStringKey()];

  @override
  setStringList(PrefKey key, List<String> value) async {
    return _onPostSet(() {
      _data[key.toStringKey()] = value;
      return true;
    }(), key, value);
  }

  final Map<String, dynamic> _data;
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
  gpsMapProvider,
  hasShownSharedAlbumInfo,
}

extension on PrefKey {
  String toStringKey() {
    switch (this) {
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
      case PrefKey.gpsMapProvider:
        return "gpsMapProvider";
      case PrefKey.hasShownSharedAlbumInfo:
        return "hasShownSharedAlbumInfo";
    }
  }
}

extension PrefExtension on Pref {
  Account? getCurrentAccount() {
    try {
      return Pref().getAccounts2()![Pref().getCurrentAccountIndex()!].account;
    } catch (_) {
      return null;
    }
  }

  AccountSettings getAccountSettings(Account account) {
    return Pref()
        .getAccounts2()!
        .firstWhere((element) => element.account == account)
        .settings;
  }
}
