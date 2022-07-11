import 'dart:async';
import 'dart:convert';

import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/use_case/compat/v34.dart';
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

  List<Account>? getAccounts3() {
    final jsonObjs = provider.getStringList(PrefKey.accounts3);
    return jsonObjs?.map((e) => Account.fromJson(jsonDecode(e))).toList();
  }

  List<Account> getAccounts3Or(List<Account> def) => getAccounts3() ?? def;
  Future<bool> setAccounts3(List<Account> value) {
    final jsons = value.map((e) => jsonEncode(e.toJson())).toList();
    return provider.setStringList(PrefKey.accounts3, jsons);
  }

  int? getCurrentAccountIndex() => provider.getInt(PrefKey.currentAccountIndex);
  int getCurrentAccountIndexOr(int def) => getCurrentAccountIndex() ?? def;
  Future<bool> setCurrentAccountIndex(int value) => _set<int>(
      PrefKey.currentAccountIndex,
      value,
      (key, value) => provider.setInt(key, value));

  int? getHomePhotosZoomLevel() => provider.getInt(PrefKey.homePhotosZoomLevel);
  int getHomePhotosZoomLevelOr(int def) => getHomePhotosZoomLevel() ?? def;
  Future<bool> setHomePhotosZoomLevel(int value) => _set<int>(
      PrefKey.homePhotosZoomLevel,
      value,
      (key, value) => provider.setInt(key, value));

  int? getAlbumBrowserZoomLevel() =>
      provider.getInt(PrefKey.albumBrowserZoomLevel);
  int getAlbumBrowserZoomLevelOr(int def) => getAlbumBrowserZoomLevel() ?? def;
  Future<bool> setAlbumBrowserZoomLevel(int value) => _set<int>(
      PrefKey.albumBrowserZoomLevel,
      value,
      (key, value) => provider.setInt(key, value));

  int? getHomeAlbumsSort() => provider.getInt(PrefKey.homeAlbumsSort);
  int getHomeAlbumsSortOr(int def) => getHomeAlbumsSort() ?? def;
  Future<bool> setHomeAlbumsSort(int value) => _set<int>(PrefKey.homeAlbumsSort,
      value, (key, value) => provider.setInt(key, value));

  bool? isEnableExif() => provider.getBool(PrefKey.enableExif);
  bool isEnableExifOr([bool def = true]) => isEnableExif() ?? def;
  Future<bool> setEnableExif(bool value) => _set<bool>(
      PrefKey.enableExif, value, (key, value) => provider.setBool(key, value));

  int? getViewerScreenBrightness() =>
      provider.getInt(PrefKey.viewerScreenBrightness);
  int getViewerScreenBrightnessOr([int def = -1]) =>
      getViewerScreenBrightness() ?? def;
  Future<bool> setViewerScreenBrightness(int value) => _set<int>(
      PrefKey.viewerScreenBrightness,
      value,
      (key, value) => provider.setInt(key, value));

  bool? isViewerForceRotation() =>
      provider.getBool(PrefKey.viewerForceRotation);
  bool isViewerForceRotationOr([bool def = false]) =>
      isViewerForceRotation() ?? def;
  Future<bool> setViewerForceRotation(bool value) => _set<bool>(
      PrefKey.viewerForceRotation,
      value,
      (key, value) => provider.setBool(key, value));

  int? getSetupProgress() => provider.getInt(PrefKey.setupProgress);
  int getSetupProgressOr([int def = 0]) => getSetupProgress() ?? def;
  Future<bool> setSetupProgress(int value) => _set<int>(PrefKey.setupProgress,
      value, (key, value) => provider.setInt(key, value));

  /// Return the version number when the app last ran
  int? getLastVersion() => provider.getInt(PrefKey.lastVersion);
  int getLastVersionOr(int def) => getLastVersion() ?? def;
  Future<bool> setLastVersion(int value) => _set<int>(
      PrefKey.lastVersion, value, (key, value) => provider.setInt(key, value));

  bool? isDarkTheme() => provider.getBool(PrefKey.darkTheme);
  bool isDarkThemeOr(bool def) => isDarkTheme() ?? def;
  Future<bool> setDarkTheme(bool value) => _set<bool>(
      PrefKey.darkTheme, value, (key, value) => provider.setBool(key, value));

  bool? isFollowSystemTheme() => provider.getBool(PrefKey.followSystemTheme);
  bool isFollowSystemThemeOr(bool def) => isFollowSystemTheme() ?? def;
  Future<bool> setFollowSystemTheme(bool value) => _set<bool>(
      PrefKey.followSystemTheme,
      value,
      (key, value) => provider.setBool(key, value));

  bool? isUseBlackInDarkTheme() =>
      provider.getBool(PrefKey.useBlackInDarkTheme);
  bool isUseBlackInDarkThemeOr(bool def) => isUseBlackInDarkTheme() ?? def;
  Future<bool> setUseBlackInDarkTheme(bool value) => _set<bool>(
      PrefKey.useBlackInDarkTheme,
      value,
      (key, value) => provider.setBool(key, value));

  int? getLanguage() => provider.getInt(PrefKey.language);
  int getLanguageOr(int def) => getLanguage() ?? def;
  Future<bool> setLanguage(int value) => _set<int>(
      PrefKey.language, value, (key, value) => provider.setInt(key, value));

  int? getSlideshowDuration() => provider.getInt(PrefKey.slideshowDuration);
  int getSlideshowDurationOr(int def) => getSlideshowDuration() ?? def;
  Future<bool> setSlideshowDuration(int value) => _set<int>(
      PrefKey.slideshowDuration,
      value,
      (key, value) => provider.setInt(key, value));

  bool? isSlideshowShuffle() => provider.getBool(PrefKey.isSlideshowShuffle);
  bool isSlideshowShuffleOr(bool def) => isSlideshowShuffle() ?? def;
  Future<bool> setSlideshowShuffle(bool value) => _set<bool>(
      PrefKey.isSlideshowShuffle,
      value,
      (key, value) => provider.setBool(key, value));

  bool? isSlideshowRepeat() => provider.getBool(PrefKey.isSlideshowRepeat);
  bool isSlideshowRepeatOr(bool def) => isSlideshowRepeat() ?? def;
  Future<bool> setSlideshowRepeat(bool value) => _set<bool>(
      PrefKey.isSlideshowRepeat,
      value,
      (key, value) => provider.setBool(key, value));

  bool? isAlbumBrowserShowDate() =>
      provider.getBool(PrefKey.isAlbumBrowserShowDate);
  bool isAlbumBrowserShowDateOr([bool def = false]) =>
      isAlbumBrowserShowDate() ?? def;
  Future<bool> setAlbumBrowserShowDate(bool value) => _set<bool>(
      PrefKey.isAlbumBrowserShowDate,
      value,
      (key, value) => provider.setBool(key, value));

  int? getGpsMapProvider() => provider.getInt(PrefKey.gpsMapProvider);
  int getGpsMapProviderOr(int def) => getGpsMapProvider() ?? def;
  Future<bool> setGpsMapProvider(int value) => _set<int>(PrefKey.gpsMapProvider,
      value, (key, value) => provider.setInt(key, value));

  bool? isLabEnableSharedAlbum() =>
      provider.getBool(PrefKey.labEnableSharedAlbum);
  bool isLabEnableSharedAlbumOr(bool def) => isLabEnableSharedAlbum() ?? def;
  Future<bool> setLabEnableSharedAlbum(bool value) => _set<bool>(
      PrefKey.labEnableSharedAlbum,
      value,
      (key, value) => provider.setBool(key, value));

  bool? hasShownSharedAlbumInfo() =>
      provider.getBool(PrefKey.hasShownSharedAlbumInfo);
  bool hasShownSharedAlbumInfoOr(bool def) => hasShownSharedAlbumInfo() ?? def;
  Future<bool> setHasShownSharedAlbumInfo(bool value) => _set<bool>(
      PrefKey.hasShownSharedAlbumInfo,
      value,
      (key, value) => provider.setBool(key, value));

  int? getEnhanceMaxWidth() => provider.getInt(PrefKey.enhanceMaxWidth);
  int getEnhanceMaxWidthOr([int def = 2048]) => getEnhanceMaxWidth() ?? def;
  Future<bool> setEnhanceMaxWidth(int value) => _set<int>(
      PrefKey.enhanceMaxWidth,
      value,
      (key, value) => provider.setInt(key, value));

  int? getEnhanceMaxHeight() => provider.getInt(PrefKey.enhanceMaxHeight);
  int getEnhanceMaxHeightOr([int def = 1536]) => getEnhanceMaxHeight() ?? def;
  Future<bool> setEnhanceMaxHeight(int value) => _set<int>(
      PrefKey.enhanceMaxHeight,
      value,
      (key, value) => provider.setInt(key, value));

  bool? hasShownEnhanceInfo() => provider.getBool(PrefKey.hasShownEnhanceInfo);
  bool hasShownEnhanceInfoOr([bool def = false]) =>
      hasShownEnhanceInfo() ?? def;
  Future<bool> setHasShownEnhanceInfo(bool value) => _set<bool>(
      PrefKey.hasShownEnhanceInfo,
      value,
      (key, value) => provider.setBool(key, value));

  int? getFirstRunTime() => provider.getInt(PrefKey.firstRunTime);
  int getFirstRunTimeOr(int def) => getFirstRunTime() ?? def;
  Future<bool> setFirstRunTime(int value) => _set<int>(
      PrefKey.firstRunTime, value, (key, value) => provider.setInt(key, value));

  bool? isPhotosTabSortByName() =>
      provider.getBool(PrefKey.isPhotosTabSortByName);
  bool isPhotosTabSortByNameOr([bool def = false]) =>
      isPhotosTabSortByName() ?? def;
  Future<bool> setPhotosTabSortByName(bool value) => _set<bool>(
      PrefKey.isPhotosTabSortByName,
      value,
      (key, value) => provider.setBool(key, value));

  bool? shouldProcessExifWifiOnly() =>
      provider.getBool(PrefKey.shouldProcessExifWifiOnly);
  bool shouldProcessExifWifiOnlyOr([bool def = true]) =>
      shouldProcessExifWifiOnly() ?? def;
  Future<bool> setProcessExifWifiOnly(bool value) => _set<bool>(
      PrefKey.shouldProcessExifWifiOnly,
      value,
      (key, value) => provider.setBool(key, value));

  bool? isDoubleTapExit() => provider.getBool(PrefKey.doubleTapExit);
  bool isDoubleTapExitOr([bool def = false]) => isDoubleTapExit() ?? def;
  Future<bool> setDoubleTapExit(bool value) => _set<bool>(PrefKey.doubleTapExit,
      value, (key, value) => provider.setBool(key, value));

  Future<bool> _set<T>(PrefKey key, T value,
      Future<bool> Function(PrefKey key, T value) setFn) async {
    if (await setFn(key, value)) {
      KiwiContainer().resolve<EventBus>().fire(PrefUpdatedEvent(key, value));
      return true;
    } else {
      return false;
    }
  }

  final PrefProvider provider;

  static Pref? _inst;
}

class AccountPref {
  AccountPref.scoped(this.provider);

  static AccountPref of(Account account) {
    _insts.putIfAbsent(
        account.id, () => AccountPref.scoped(PrefMemoryProvider()));
    return _insts[account.id]!;
  }

  /// Set the global [AccountPref] instance returned by the default constructor
  static void setGlobalInstance(Account account, AccountPref? pref) {
    if (pref != null) {
      assert(!_insts.containsKey(account.id));
      _insts[account.id] = pref;
    } else {
      assert(_insts.containsKey(account.id));
      _insts.remove(account.id);
    }
  }

  bool? isEnableFaceRecognitionApp() =>
      provider.getBool(PrefKey.isEnableFaceRecognitionApp);
  bool isEnableFaceRecognitionAppOr([bool def = true]) =>
      isEnableFaceRecognitionApp() ?? def;
  Future<bool> setEnableFaceRecognitionApp(bool value) => _set<bool>(
      PrefKey.isEnableFaceRecognitionApp,
      value,
      (key, value) => provider.setBool(key, value));

  String? getShareFolder() => provider.getString(PrefKey.shareFolder);
  String getShareFolderOr([String def = ""]) => getShareFolder() ?? def;
  Future<bool> setShareFolder(String value) => _set<String>(PrefKey.shareFolder,
      value, (key, value) => provider.setString(key, value));

  bool? hasNewSharedAlbum() => provider.getBool(PrefKey.hasNewSharedAlbum);
  bool hasNewSharedAlbumOr([bool def = false]) => hasNewSharedAlbum() ?? def;
  Future<bool> setNewSharedAlbum(bool value) => _set<bool>(
      PrefKey.hasNewSharedAlbum,
      value,
      (key, value) => provider.setBool(key, value));

  bool? isEnableMemoryAlbum() => provider.getBool(PrefKey.isEnableMemoryAlbum);
  bool isEnableMemoryAlbumOr([bool def = false]) =>
      isEnableMemoryAlbum() ?? def;
  Future<bool> setEnableMemoryAlbum(bool value) => _set<bool>(
      PrefKey.isEnableMemoryAlbum,
      value,
      (key, value) => provider.setBool(key, value));

  String? getTouchRootEtag() => provider.getString(PrefKey.touchRootEtag);
  String getTouchRootEtagOr([String def = ""]) => getTouchRootEtag() ?? def;
  Future<bool> setTouchRootEtag(String value) => _set<String>(
      PrefKey.touchRootEtag,
      value,
      (key, value) => provider.setString(key, value));
  Future<bool> removeTouchRootEtag() => _remove(PrefKey.touchRootEtag);

  String? getAccountLabel() => provider.getString(PrefKey.accountLabel);
  String getAccountLabelOr([String def = ""]) => getAccountLabel() ?? def;
  Future<bool> setAccountLabel(String? value) {
    if (value == null) {
      return _remove(PrefKey.accountLabel);
    } else {
      return _set<String>(PrefKey.accountLabel, value,
          (key, value) => provider.setString(key, value));
    }
  }

  Future<bool> _set<T>(PrefKey key, T value,
      Future<bool> Function(PrefKey key, T value) setFn) async {
    if (await setFn(key, value)) {
      KiwiContainer()
          .resolve<EventBus>()
          .fire(AccountPrefUpdatedEvent(this, key, value));
      return true;
    } else {
      return false;
    }
  }

  Future<bool> _remove(PrefKey key) => provider.remove(key);

  final PrefProvider provider;

  static final _insts = <String, AccountPref>{};
}

/// Provide the data for [Pref]
abstract class PrefProvider {
  bool? getBool(PrefKey key);
  Future<bool> setBool(PrefKey key, bool value);

  int? getInt(PrefKey key);
  Future<bool> setInt(PrefKey key, int value);

  String? getString(PrefKey key);
  Future<bool> setString(PrefKey key, String value);

  List<String>? getStringList(PrefKey key);
  Future<bool> setStringList(PrefKey key, List<String> value);

  Future<bool> remove(PrefKey key);
  Future<bool> clear();
}

/// [Pref] stored with [SharedPreferences] lib
class PrefSharedPreferencesProvider extends PrefProvider {
  Future<void> init() async {
    // Obsolete, CompatV34 is compatible with pre v32 versions
    // if (await CompatV32.isPrefNeedMigration()) {
    //   await CompatV32.migratePref();
    // }
    if (await CompatV34.isPrefNeedMigration()) {
      await CompatV34.migratePref(platform.UniversalStorage());
    }
    return SharedPreferences.getInstance().then((pref) {
      _pref = pref;
    });
  }

  @override
  getBool(PrefKey key) => _pref.getBool(key.toStringKey());

  @override
  setBool(PrefKey key, bool value) => _pref.setBool(key.toStringKey(), value);

  @override
  getInt(PrefKey key) => _pref.getInt(key.toStringKey());

  @override
  setInt(PrefKey key, int value) => _pref.setInt(key.toStringKey(), value);

  @override
  getString(PrefKey key) => _pref.getString(key.toStringKey());

  @override
  setString(PrefKey key, String value) =>
      _pref.setString(key.toStringKey(), value);

  @override
  getStringList(PrefKey key) => _pref.getStringList(key.toStringKey());

  @override
  setStringList(PrefKey key, List<String> value) =>
      _pref.setStringList(key.toStringKey(), value);

  @override
  remove(PrefKey key) => _pref.remove(key.toStringKey());

  @override
  clear() => _pref.clear();

  late SharedPreferences _pref;
}

/// [Pref] backed by [UniversalStorage]
class PrefUniversalStorageProvider extends PrefProvider {
  PrefUniversalStorageProvider(this.name);

  Future<void> init() async {
    final prefStr = await platform.UniversalStorage().getString(name) ?? "{}";
    _data
      ..clear()
      ..addAll(jsonDecode(prefStr));
  }

  @override
  getBool(PrefKey key) => _get<bool>(key);
  @override
  setBool(PrefKey key, bool value) => _set(key, value);

  @override
  getInt(PrefKey key) => _get<int>(key);
  @override
  setInt(PrefKey key, int value) => _set(key, value);

  @override
  getString(PrefKey key) => _get<String>(key);
  @override
  setString(PrefKey key, String value) => _set(key, value);

  @override
  getStringList(PrefKey key) => _get<List<String>>(key);
  @override
  setStringList(PrefKey key, List<String> value) => _set(key, value);

  @override
  remove(PrefKey key) async {
    final newData = Map.of(_data)..remove(key.toStringKey());
    await platform.UniversalStorage().putString(name, jsonEncode(newData));
    _data.remove(key.toStringKey());
    return true;
  }

  @override
  clear() async {
    await platform.UniversalStorage().remove(name);
    _data.clear();
    return true;
  }

  T? _get<T>(PrefKey key) => _data[key.toStringKey()];

  Future<bool> _set<T>(PrefKey key, T value) async {
    final newData = Map.of(_data)
      ..addEntries([MapEntry(key.toStringKey(), value)]);
    await platform.UniversalStorage().putString(name, jsonEncode(newData));
    _data[key.toStringKey()] = value;
    return true;
  }

  final String name;
  final _data = <String, dynamic>{};
}

/// [Pref] stored in memory, useful in unit tests
class PrefMemoryProvider extends PrefProvider {
  PrefMemoryProvider([
    Map<String, dynamic> initialData = const <String, dynamic>{},
  ]) : _data = Map.of(initialData);

  @override
  getBool(PrefKey key) => _get<bool>(key);
  @override
  setBool(PrefKey key, bool value) => _set(key, value);

  @override
  getInt(PrefKey key) => _get<int>(key);
  @override
  setInt(PrefKey key, int value) => _set(key, value);

  @override
  getString(PrefKey key) => _get<String>(key);
  @override
  setString(PrefKey key, String value) => _set(key, value);

  @override
  getStringList(PrefKey key) => _get<List<String>>(key);
  @override
  setStringList(PrefKey key, List<String> value) => _set(key, value);

  @override
  remove(PrefKey key) async {
    _data.remove(key);
    return true;
  }

  @override
  clear() async {
    _data.clear();
    return true;
  }

  T? _get<T>(PrefKey key) => _data[key.toStringKey()];

  Future<bool> _set<T>(PrefKey key, T value) async {
    _data[key.toStringKey()] = value;
    return true;
  }

  final Map<String, dynamic> _data;
}

enum PrefKey {
  accounts3,
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
  labEnableSharedAlbum,
  slideshowDuration,
  isSlideshowShuffle,
  isSlideshowRepeat,
  isAlbumBrowserShowDate,
  gpsMapProvider,
  hasShownSharedAlbumInfo,
  enhanceMaxWidth,
  enhanceMaxHeight,
  hasShownEnhanceInfo,
  firstRunTime,
  isPhotosTabSortByName,
  shouldProcessExifWifiOnly,
  doubleTapExit,

  // account pref
  isEnableFaceRecognitionApp,
  shareFolder,
  hasNewSharedAlbum,
  isEnableMemoryAlbum,
  touchRootEtag,
  accountLabel,
}

extension on PrefKey {
  String toStringKey() {
    switch (this) {
      case PrefKey.accounts3:
        return "accounts3";
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
      case PrefKey.enhanceMaxWidth:
        return "enhanceMaxWidth";
      case PrefKey.enhanceMaxHeight:
        return "enhanceMaxHeight";
      case PrefKey.hasShownEnhanceInfo:
        return "hasShownEnhanceInfo";
      case PrefKey.firstRunTime:
        return "firstRunTime";
      case PrefKey.isPhotosTabSortByName:
        return "isPhotosTabSortByName";
      case PrefKey.shouldProcessExifWifiOnly:
        return "shouldProcessExifWifiOnly";
      case PrefKey.doubleTapExit:
        return "doubleTapExit";

      // account pref
      case PrefKey.isEnableFaceRecognitionApp:
        return "isEnableFaceRecognitionApp";
      case PrefKey.shareFolder:
        return "shareFolder";
      case PrefKey.hasNewSharedAlbum:
        return "hasNewSharedAlbum";
      case PrefKey.isEnableMemoryAlbum:
        return "isEnableMemoryAlbum";
      case PrefKey.touchRootEtag:
        return "touchRootEtag";
      case PrefKey.accountLabel:
        return "accountLabel";
    }
  }
}

extension PrefExtension on Pref {
  Account? getCurrentAccount() {
    try {
      return Pref().getAccounts3()![Pref().getCurrentAccountIndex()!];
    } catch (_) {
      return null;
    }
  }
}
