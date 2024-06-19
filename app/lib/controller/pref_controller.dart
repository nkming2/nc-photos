// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/collection/util.dart';
import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/language_util.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/protected_page_handler.dart';
import 'package:nc_photos/size.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/object_util.dart';
import 'package:np_gps_map/np_gps_map.dart';
import 'package:np_string/np_string.dart';
import 'package:rxdart/rxdart.dart';

part 'pref_controller.g.dart';
part 'pref_controller/util.dart';

@npSubjectAccessor
class PrefController {
  PrefController(this._c);

  Future<bool> setAccounts(List<Account> value) => _set<List<Account>>(
        controller: _accountsController,
        setter: (pref, value) => pref.setAccounts3(value),
        value: value,
      );

  Future<bool> setAppLanguage(AppLanguage value) => _set<AppLanguage>(
        controller: _languageController,
        setter: (pref, value) => pref.setLanguage(value.langId),
        value: value,
      );

  Future<bool> setHomePhotosZoomLevel(int value) => _set<int>(
        controller: _homePhotosZoomLevelController,
        setter: (pref, value) => pref.setHomePhotosZoomLevel(value),
        value: value,
      );

  Future<bool> setAlbumBrowserZoomLevel(int value) => _set<int>(
        controller: _albumBrowserZoomLevelController,
        setter: (pref, value) => pref.setAlbumBrowserZoomLevel(value),
        value: value,
      );

  Future<bool> setHomeAlbumsSort(CollectionSort value) => _set<CollectionSort>(
        controller: _homeAlbumsSortController,
        setter: (pref, value) => pref.setHomeAlbumsSort(value.index),
        value: value,
      );

  Future<bool> setEnableExif(bool value) => _set<bool>(
        controller: _isEnableExifController,
        setter: (pref, value) => pref.setEnableExif(value),
        value: value,
      );

  Future<bool> setProcessExifWifiOnly(bool value) => _set<bool>(
        controller: _shouldProcessExifWifiOnlyController,
        setter: (pref, value) => pref.setProcessExifWifiOnly(value),
        value: value,
      );

  Future<bool> setMemoriesRange(int value) => _set<int>(
        controller: _memoriesRangeController,
        setter: (pref, value) => pref.setMemoriesRange(value),
        value: value,
      );

  Future<bool> setViewerScreenBrightness(int value) => _set<int>(
        controller: _viewerScreenBrightnessController,
        setter: (pref, value) => pref.setViewerScreenBrightness(value),
        value: value,
      );

  Future<bool> setViewerForceRotation(bool value) => _set<bool>(
        controller: _isViewerForceRotationController,
        setter: (pref, value) => pref.setViewerForceRotation(value),
        value: value,
      );

  Future<bool> setGpsMapProvider(GpsMapProvider value) => _set<GpsMapProvider>(
        controller: _gpsMapProviderController,
        setter: (pref, value) => pref.setGpsMapProvider(value.index),
        value: value,
      );

  Future<bool> setAlbumBrowserShowDate(bool value) => _set<bool>(
        controller: _isAlbumBrowserShowDateController,
        setter: (pref, value) => pref.setAlbumBrowserShowDate(value),
        value: value,
      );

  Future<bool> setDoubleTapExit(bool value) => _set<bool>(
        controller: _isDoubleTapExitController,
        setter: (pref, value) => pref.setDoubleTapExit(value),
        value: value,
      );

  Future<bool> setSaveEditResultToServer(bool value) => _set<bool>(
        controller: _isSaveEditResultToServerController,
        setter: (pref, value) => pref.setSaveEditResultToServer(value),
        value: value,
      );

  Future<bool> setEnhanceMaxSize(SizeInt value) => _set<SizeInt>(
        controller: _enhanceMaxSizeController,
        setter: (pref, value) async {
          return (await Future.wait([
            pref.setEnhanceMaxWidth(value.width),
            pref.setEnhanceMaxHeight(value.height),
          ]))
              .reduce((a, b) => a && b);
        },
        value: value,
      );

  Future<bool> setDarkTheme(bool value) => _set<bool>(
        controller: _isDarkThemeController,
        setter: (pref, value) => pref.setDarkTheme(value),
        value: value,
      );

  Future<bool> setFollowSystemTheme(bool value) => _set<bool>(
        controller: _isFollowSystemThemeController,
        setter: (pref, value) => pref.setFollowSystemTheme(value),
        value: value,
      );

  Future<bool> setUseBlackInDarkTheme(bool value) => _set<bool>(
        controller: _isUseBlackInDarkThemeController,
        setter: (pref, value) => pref.setUseBlackInDarkTheme(value),
        value: value,
      );

  Future<bool> setSeedColor(Color? value) => _setOrRemove<Color>(
        controller: _seedColorController,
        setter: (pref, value) => pref.setSeedColor(value.withAlpha(0xFF).value),
        remover: (pref) => pref.setSeedColor(null),
        value: value,
      );

  Future<bool> setSecondarySeedColor(Color? value) => _setOrRemove<Color>(
        controller: _secondarySeedColorController,
        setter: (pref, value) =>
            pref.setSecondarySeedColor(value.withAlpha(0xFF).value),
        remover: (pref) => pref.setSecondarySeedColor(null),
        value: value,
      );

  Future<bool> _set<T>({
    required BehaviorSubject<T> controller,
    required Future<bool> Function(Pref pref, T value) setter,
    required T value,
  }) =>
      _doSet(
        pref: _c.pref,
        controller: controller,
        setter: setter,
        value: value,
      );

  Future<bool> _setOrRemove<T>({
    required BehaviorSubject<T?> controller,
    required Future<bool> Function(Pref pref, T value) setter,
    required Future<bool> Function(Pref pref) remover,
    required T? value,
    T? defaultValue,
  }) =>
      _doSetOrRemove(
        pref: _c.pref,
        controller: controller,
        setter: setter,
        remover: remover,
        value: value,
        defaultValue: defaultValue,
      );

  static AppLanguage _langIdToAppLanguage(int langId) {
    try {
      return supportedLanguages[langId]!;
    } catch (_) {
      return supportedLanguages[0]!;
    }
  }

  final DiContainer _c;
  @npSubjectAccessor
  late final _accountsController =
      BehaviorSubject.seeded(_c.pref.getAccounts3() ?? []);
  @npSubjectAccessor
  late final _languageController =
      BehaviorSubject.seeded(_langIdToAppLanguage(_c.pref.getLanguageOr(0)));
  @npSubjectAccessor
  late final _homePhotosZoomLevelController =
      BehaviorSubject.seeded(_c.pref.getHomePhotosZoomLevelOr(0));
  @npSubjectAccessor
  late final _albumBrowserZoomLevelController =
      BehaviorSubject.seeded(_c.pref.getAlbumBrowserZoomLevelOr(0));
  @npSubjectAccessor
  late final _homeAlbumsSortController = BehaviorSubject.seeded(
      CollectionSort.values[_c.pref.getHomeAlbumsSortOr(0)]);
  @npSubjectAccessor
  late final _isEnableExifController =
      BehaviorSubject.seeded(_c.pref.isEnableExifOr(true));
  @npSubjectAccessor
  late final _shouldProcessExifWifiOnlyController =
      BehaviorSubject.seeded(_c.pref.shouldProcessExifWifiOnlyOr(true));
  @npSubjectAccessor
  late final _memoriesRangeController =
      BehaviorSubject.seeded(_c.pref.getMemoriesRangeOr(2));
  @npSubjectAccessor
  late final _viewerScreenBrightnessController =
      BehaviorSubject.seeded(_c.pref.getViewerScreenBrightnessOr(-1));
  @npSubjectAccessor
  late final _isViewerForceRotationController =
      BehaviorSubject.seeded(_c.pref.isViewerForceRotationOr(false));
  @npSubjectAccessor
  late final _gpsMapProviderController = BehaviorSubject.seeded(
      GpsMapProvider.values[_c.pref.getGpsMapProviderOr(0)]);
  @npSubjectAccessor
  late final _isAlbumBrowserShowDateController =
      BehaviorSubject.seeded(_c.pref.isAlbumBrowserShowDateOr(false));
  @npSubjectAccessor
  late final _isDoubleTapExitController =
      BehaviorSubject.seeded(_c.pref.isDoubleTapExitOr(false));
  @npSubjectAccessor
  late final _isSaveEditResultToServerController =
      BehaviorSubject.seeded(_c.pref.isSaveEditResultToServerOr(true));
  @npSubjectAccessor
  late final _enhanceMaxSizeController = BehaviorSubject.seeded(
      SizeInt(_c.pref.getEnhanceMaxWidthOr(), _c.pref.getEnhanceMaxHeightOr()));
  @npSubjectAccessor
  late final _isDarkThemeController =
      BehaviorSubject.seeded(_c.pref.isDarkThemeOr(false));
  @npSubjectAccessor
  late final _isFollowSystemThemeController =
      BehaviorSubject.seeded(_c.pref.isFollowSystemThemeOr(false));
  @npSubjectAccessor
  late final _isUseBlackInDarkThemeController =
      BehaviorSubject.seeded(_c.pref.isUseBlackInDarkThemeOr(false));
  @NpSubjectAccessor(type: "Color?")
  late final _seedColorController =
      BehaviorSubject<Color?>.seeded(_c.pref.getSeedColor()?.run(Color.new));
  @NpSubjectAccessor(type: "Color?")
  late final _secondarySeedColorController = BehaviorSubject<Color?>.seeded(
      _c.pref.getSecondarySeedColor()?.run(Color.new));
}

@npSubjectAccessor
class SecurePrefController {
  SecurePrefController(this._c);

  Future<bool> setProtectedPageAuthType(ProtectedPageAuthType? value) =>
      _setOrRemove<ProtectedPageAuthType>(
        controller: _protectedPageAuthTypeController,
        setter: (pref, value) => pref.setProtectedPageAuthType(value.index),
        remover: (pref) => pref.setProtectedPageAuthType(null),
        value: value,
      );

  Future<bool> setProtectedPageAuthPin(CiString? value) =>
      _setOrRemove<CiString>(
        controller: _protectedPageAuthPinController,
        setter: (pref, value) =>
            pref.setProtectedPageAuthPin(value.toCaseInsensitiveString()),
        remover: (pref) => pref.setProtectedPageAuthPin(null),
        value: value,
      );

  Future<bool> setProtectedPageAuthPassword(CiString? value) =>
      _setOrRemove<CiString>(
        controller: _protectedPageAuthPasswordController,
        setter: (pref, value) =>
            pref.setProtectedPageAuthPassword(value.toCaseInsensitiveString()),
        remover: (pref) => pref.setProtectedPageAuthPassword(null),
        value: value,
      );

  // ignore: unused_element
  Future<bool> _set<T>({
    required BehaviorSubject<T> controller,
    required Future<bool> Function(Pref pref, T value) setter,
    required T value,
  }) =>
      _doSet(
        pref: _c.securePref,
        controller: controller,
        setter: setter,
        value: value,
      );

  // ignore: unused_element
  Future<bool> _setOrRemove<T>({
    required BehaviorSubject<T?> controller,
    required Future<bool> Function(Pref pref, T value) setter,
    required Future<bool> Function(Pref pref) remover,
    required T? value,
    T? defaultValue,
  }) =>
      _doSetOrRemove(
        pref: _c.securePref,
        controller: controller,
        setter: setter,
        remover: remover,
        value: value,
        defaultValue: defaultValue,
      );

  final DiContainer _c;
  @npSubjectAccessor
  late final _protectedPageAuthTypeController = BehaviorSubject.seeded(_c
      .securePref
      .getProtectedPageAuthType()
      ?.let((e) => ProtectedPageAuthType.values[e]));
  @npSubjectAccessor
  late final _protectedPageAuthPinController =
      BehaviorSubject.seeded(_c.securePref.getProtectedPageAuthPin()?.toCi());
  @npSubjectAccessor
  late final _protectedPageAuthPasswordController = BehaviorSubject.seeded(
      _c.securePref.getProtectedPageAuthPassword()?.toCi());
}

Future<bool> _doSet<T>({
  required Pref pref,
  required BehaviorSubject<T> controller,
  required Future<bool> Function(Pref pref, T value) setter,
  required T value,
}) async {
  final backup = controller.value;
  controller.add(value);
  try {
    if (!await setter(pref, value)) {
      throw StateError("Unknown error");
    }
    return true;
  } catch (e, stackTrace) {
    _$__NpLog.log.severe("[_doSet] Failed setting preference", e, stackTrace);
    controller
      ..addError(e, stackTrace)
      ..add(backup);
    return false;
  }
}

Future<bool> _doSetOrRemove<T>({
  required Pref pref,
  required BehaviorSubject<T?> controller,
  required Future<bool> Function(Pref pref, T value) setter,
  required Future<bool> Function(Pref pref) remover,
  required T? value,
  T? defaultValue,
}) async {
  final backup = controller.value;
  controller.add(value ?? defaultValue);
  try {
    if (value == null) {
      if (!await remover(pref)) {
        throw StateError("Unknown error");
      }
    } else {
      if (!await setter(pref, value)) {
        throw StateError("Unknown error");
      }
    }
    return true;
  } catch (e, stackTrace) {
    _$__NpLog.log
        .severe("[_doSetOrRemove] Failed setting preference", e, stackTrace);
    controller
      ..addError(e, stackTrace)
      ..add(backup);
    return false;
  }
}

@npLog
// ignore: camel_case_types
class __ {}
