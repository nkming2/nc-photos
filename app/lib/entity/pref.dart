import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/pref/provider/memory.dart';
import 'package:nc_photos/event/event.dart';
import 'package:np_codegen/np_codegen.dart';

part 'pref.g.dart';
part 'pref/extension.dart';

@npLog
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

  Future<bool> _set<T>(PrefKey key, T value,
      Future<bool> Function(PrefKey key, T value) setFn) async {
    if (await setFn(key, value)) {
      KiwiContainer().resolve<EventBus>().fire(PrefUpdatedEvent(key, value));
      return true;
    } else {
      return false;
    }
  }

  Future<bool> _remove(PrefKey key) => provider.remove(key);

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

  int? getLastNewCollectionType() =>
      provider.getInt(PrefKey.lastNewCollectionType);
  int getLastNewCollectionTypeOr(int def) => getLastNewCollectionType() ?? def;
  Future<bool> setLastNewCollectionType(int? value) {
    if (value == null) {
      return _remove(PrefKey.lastNewCollectionType);
    } else {
      return _set<int>(PrefKey.lastNewCollectionType, value,
          (key, value) => provider.setInt(key, value));
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
  memoriesRange,
  saveEditResultToServer,
  hasShownSaveEditResultDialog,
  isSlideshowReverse,
  seedColor,
  isVideoPlayerMute,
  isVideoPlayerLoop,

  // account pref
  isEnableFaceRecognitionApp,
  shareFolder,
  hasNewSharedAlbum,
  isEnableMemoryAlbum,
  touchRootEtag,
  accountLabel,
  lastNewCollectionType;

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
      case PrefKey.memoriesRange:
        return "memoriesRange";
      case PrefKey.saveEditResultToServer:
        return "saveEditResultToServer";
      case PrefKey.hasShownSaveEditResultDialog:
        return "hasShownSaveEditResultDialog";
      case PrefKey.isSlideshowReverse:
        return "isSlideshowReverse";
      case PrefKey.seedColor:
        return "seedColor";
      case PrefKey.isVideoPlayerMute:
        return "isVideoPlayerMute";
      case PrefKey.isVideoPlayerLoop:
        return "isVideoPlayerLoop";

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
      case PrefKey.lastNewCollectionType:
        return "lastNewCollectionType";
    }
  }
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
