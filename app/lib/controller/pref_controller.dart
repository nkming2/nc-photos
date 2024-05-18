// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/language_util.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/size.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_gps_map/np_gps_map.dart';
import 'package:rxdart/rxdart.dart';

part 'pref_controller.g.dart';

@npLog
@npSubjectAccessor
class PrefController {
  PrefController(this._c);

  Future<void> setAppLanguage(AppLanguage value) => _set<AppLanguage>(
        controller: _languageController,
        setter: (pref, value) => pref.setLanguage(value.langId),
        value: value,
      );

  Future<void> setHomePhotosZoomLevel(int value) => _set<int>(
        controller: _homePhotosZoomLevelController,
        setter: (pref, value) => pref.setHomePhotosZoomLevel(value),
        value: value,
      );

  Future<void> setAlbumBrowserZoomLevel(int value) => _set<int>(
        controller: _albumBrowserZoomLevelController,
        setter: (pref, value) => pref.setAlbumBrowserZoomLevel(value),
        value: value,
      );

  Future<void> setHomeAlbumsSort(int value) => _set<int>(
        controller: _homeAlbumsSortController,
        setter: (pref, value) => pref.setHomeAlbumsSort(value),
        value: value,
      );

  Future<void> setEnableExif(bool value) => _set<bool>(
        controller: _isEnableExifController,
        setter: (pref, value) => pref.setEnableExif(value),
        value: value,
      );

  Future<void> setProcessExifWifiOnly(bool value) => _set<bool>(
        controller: _shouldProcessExifWifiOnlyController,
        setter: (pref, value) => pref.setProcessExifWifiOnly(value),
        value: value,
      );

  Future<void> setMemoriesRange(int value) => _set<int>(
        controller: _memoriesRangeController,
        setter: (pref, value) => pref.setMemoriesRange(value),
        value: value,
      );

  Future<void> setViewerScreenBrightness(int value) => _set<int>(
        controller: _viewerScreenBrightnessController,
        setter: (pref, value) => pref.setViewerScreenBrightness(value),
        value: value,
      );

  Future<void> setViewerForceRotation(bool value) => _set<bool>(
        controller: _isViewerForceRotationController,
        setter: (pref, value) => pref.setViewerForceRotation(value),
        value: value,
      );

  Future<void> setGpsMapProvider(GpsMapProvider value) => _set<GpsMapProvider>(
        controller: _gpsMapProviderController,
        setter: (pref, value) => pref.setGpsMapProvider(value.index),
        value: value,
      );

  Future<void> setAlbumBrowserShowDate(bool value) => _set<bool>(
        controller: _isAlbumBrowserShowDateController,
        setter: (pref, value) => pref.setAlbumBrowserShowDate(value),
        value: value,
      );

  Future<void> setDoubleTapExit(bool value) => _set<bool>(
        controller: _isDoubleTapExitController,
        setter: (pref, value) => pref.setDoubleTapExit(value),
        value: value,
      );

  Future<void> setSaveEditResultToServer(bool value) => _set<bool>(
        controller: _isSaveEditResultToServerController,
        setter: (pref, value) => pref.setSaveEditResultToServer(value),
        value: value,
      );

  Future<void> setEnhanceMaxSize(SizeInt value) => _set<SizeInt>(
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

  Future<void> setDarkTheme(bool value) => _set<bool>(
        controller: _isDarkThemeController,
        setter: (pref, value) => pref.setDarkTheme(value),
        value: value,
      );

  Future<void> setFollowSystemTheme(bool value) => _set<bool>(
        controller: _isFollowSystemThemeController,
        setter: (pref, value) => pref.setFollowSystemTheme(value),
        value: value,
      );

  Future<void> setUseBlackInDarkTheme(bool value) => _set<bool>(
        controller: _isUseBlackInDarkThemeController,
        setter: (pref, value) => pref.setUseBlackInDarkTheme(value),
        value: value,
      );

  Future<void> setSeedColor(Color? value) => _setOrRemove<Color>(
        controller: _seedColorController,
        setter: (pref, value) => pref.setSeedColor(value.withAlpha(0xFF).value),
        remover: (pref) => pref.setSeedColor(null),
        value: value,
      );

  Future<void> setSecondarySeedColor(Color? value) => _setOrRemove<Color>(
        controller: _secondarySeedColorController,
        setter: (pref, value) =>
            pref.setSecondarySeedColor(value.withAlpha(0xFF).value),
        remover: (pref) => pref.setSecondarySeedColor(null),
        value: value,
      );

  Future<void> _set<T>({
    required BehaviorSubject<T> controller,
    required Future<bool> Function(Pref pref, T value) setter,
    required T value,
  }) async {
    final backup = controller.value;
    controller.add(value);
    try {
      if (!await setter(_c.pref, value)) {
        throw StateError("Unknown error");
      }
    } catch (e, stackTrace) {
      _log.severe("[_set] Failed setting preference", e, stackTrace);
      controller
        ..addError(e, stackTrace)
        ..add(backup);
    }
  }

  Future<void> _setOrRemove<T>({
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
        if (!await remover(_c.pref)) {
          throw StateError("Unknown error");
        }
      } else {
        if (!await setter(_c.pref, value)) {
          throw StateError("Unknown error");
        }
      }
    } catch (e, stackTrace) {
      _log.severe("[_set] Failed setting preference", e, stackTrace);
      controller
        ..addError(e, stackTrace)
        ..add(backup);
    }
  }

  static AppLanguage _langIdToAppLanguage(int langId) {
    try {
      return supportedLanguages[langId]!;
    } catch (_) {
      return supportedLanguages[0]!;
    }
  }

  final DiContainer _c;
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
  late final _homeAlbumsSortController =
      BehaviorSubject.seeded(_c.pref.getHomeAlbumsSortOr(0));
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
