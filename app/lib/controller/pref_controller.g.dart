// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pref_controller.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$__NpLog on __ {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("controller.pref_controller.__");
}

// **************************************************************************
// NpSubjectAccessorGenerator
// **************************************************************************

extension $PrefControllerNpSubjectAccessor on PrefController {
  // _accountsController
  ValueStream<List<Account>> get accounts => _accountsController.stream;
  Stream<List<Account>> get accountsNew => accounts.skip(1);
  Stream<List<Account>> get accountsChange => accounts.distinct().skip(1);
  List<Account> get accountsValue => _accountsController.value;
// _languageController
  ValueStream<AppLanguage> get language => _languageController.stream;
  Stream<AppLanguage> get languageNew => language.skip(1);
  Stream<AppLanguage> get languageChange => language.distinct().skip(1);
  AppLanguage get languageValue => _languageController.value;
// _homePhotosZoomLevelController
  ValueStream<int> get homePhotosZoomLevel =>
      _homePhotosZoomLevelController.stream;
  Stream<int> get homePhotosZoomLevelNew => homePhotosZoomLevel.skip(1);
  Stream<int> get homePhotosZoomLevelChange =>
      homePhotosZoomLevel.distinct().skip(1);
  int get homePhotosZoomLevelValue => _homePhotosZoomLevelController.value;
// _albumBrowserZoomLevelController
  ValueStream<int> get albumBrowserZoomLevel =>
      _albumBrowserZoomLevelController.stream;
  Stream<int> get albumBrowserZoomLevelNew => albumBrowserZoomLevel.skip(1);
  Stream<int> get albumBrowserZoomLevelChange =>
      albumBrowserZoomLevel.distinct().skip(1);
  int get albumBrowserZoomLevelValue => _albumBrowserZoomLevelController.value;
// _homeAlbumsSortController
  ValueStream<CollectionSort> get homeAlbumsSort =>
      _homeAlbumsSortController.stream;
  Stream<CollectionSort> get homeAlbumsSortNew => homeAlbumsSort.skip(1);
  Stream<CollectionSort> get homeAlbumsSortChange =>
      homeAlbumsSort.distinct().skip(1);
  CollectionSort get homeAlbumsSortValue => _homeAlbumsSortController.value;
// _isEnableExifController
  ValueStream<bool> get isEnableExif => _isEnableExifController.stream;
  Stream<bool> get isEnableExifNew => isEnableExif.skip(1);
  Stream<bool> get isEnableExifChange => isEnableExif.distinct().skip(1);
  bool get isEnableExifValue => _isEnableExifController.value;
// _shouldProcessExifWifiOnlyController
  ValueStream<bool> get shouldProcessExifWifiOnly =>
      _shouldProcessExifWifiOnlyController.stream;
  Stream<bool> get shouldProcessExifWifiOnlyNew =>
      shouldProcessExifWifiOnly.skip(1);
  Stream<bool> get shouldProcessExifWifiOnlyChange =>
      shouldProcessExifWifiOnly.distinct().skip(1);
  bool get shouldProcessExifWifiOnlyValue =>
      _shouldProcessExifWifiOnlyController.value;
// _memoriesRangeController
  ValueStream<int> get memoriesRange => _memoriesRangeController.stream;
  Stream<int> get memoriesRangeNew => memoriesRange.skip(1);
  Stream<int> get memoriesRangeChange => memoriesRange.distinct().skip(1);
  int get memoriesRangeValue => _memoriesRangeController.value;
// _viewerScreenBrightnessController
  ValueStream<int> get viewerScreenBrightness =>
      _viewerScreenBrightnessController.stream;
  Stream<int> get viewerScreenBrightnessNew => viewerScreenBrightness.skip(1);
  Stream<int> get viewerScreenBrightnessChange =>
      viewerScreenBrightness.distinct().skip(1);
  int get viewerScreenBrightnessValue =>
      _viewerScreenBrightnessController.value;
// _isViewerForceRotationController
  ValueStream<bool> get isViewerForceRotation =>
      _isViewerForceRotationController.stream;
  Stream<bool> get isViewerForceRotationNew => isViewerForceRotation.skip(1);
  Stream<bool> get isViewerForceRotationChange =>
      isViewerForceRotation.distinct().skip(1);
  bool get isViewerForceRotationValue => _isViewerForceRotationController.value;
// _gpsMapProviderController
  ValueStream<GpsMapProvider> get gpsMapProvider =>
      _gpsMapProviderController.stream;
  Stream<GpsMapProvider> get gpsMapProviderNew => gpsMapProvider.skip(1);
  Stream<GpsMapProvider> get gpsMapProviderChange =>
      gpsMapProvider.distinct().skip(1);
  GpsMapProvider get gpsMapProviderValue => _gpsMapProviderController.value;
// _isAlbumBrowserShowDateController
  ValueStream<bool> get isAlbumBrowserShowDate =>
      _isAlbumBrowserShowDateController.stream;
  Stream<bool> get isAlbumBrowserShowDateNew => isAlbumBrowserShowDate.skip(1);
  Stream<bool> get isAlbumBrowserShowDateChange =>
      isAlbumBrowserShowDate.distinct().skip(1);
  bool get isAlbumBrowserShowDateValue =>
      _isAlbumBrowserShowDateController.value;
// _isDoubleTapExitController
  ValueStream<bool> get isDoubleTapExit => _isDoubleTapExitController.stream;
  Stream<bool> get isDoubleTapExitNew => isDoubleTapExit.skip(1);
  Stream<bool> get isDoubleTapExitChange => isDoubleTapExit.distinct().skip(1);
  bool get isDoubleTapExitValue => _isDoubleTapExitController.value;
// _isSaveEditResultToServerController
  ValueStream<bool> get isSaveEditResultToServer =>
      _isSaveEditResultToServerController.stream;
  Stream<bool> get isSaveEditResultToServerNew =>
      isSaveEditResultToServer.skip(1);
  Stream<bool> get isSaveEditResultToServerChange =>
      isSaveEditResultToServer.distinct().skip(1);
  bool get isSaveEditResultToServerValue =>
      _isSaveEditResultToServerController.value;
// _enhanceMaxSizeController
  ValueStream<SizeInt> get enhanceMaxSize => _enhanceMaxSizeController.stream;
  Stream<SizeInt> get enhanceMaxSizeNew => enhanceMaxSize.skip(1);
  Stream<SizeInt> get enhanceMaxSizeChange => enhanceMaxSize.distinct().skip(1);
  SizeInt get enhanceMaxSizeValue => _enhanceMaxSizeController.value;
// _isDarkThemeController
  ValueStream<bool> get isDarkTheme => _isDarkThemeController.stream;
  Stream<bool> get isDarkThemeNew => isDarkTheme.skip(1);
  Stream<bool> get isDarkThemeChange => isDarkTheme.distinct().skip(1);
  bool get isDarkThemeValue => _isDarkThemeController.value;
// _isFollowSystemThemeController
  ValueStream<bool> get isFollowSystemTheme =>
      _isFollowSystemThemeController.stream;
  Stream<bool> get isFollowSystemThemeNew => isFollowSystemTheme.skip(1);
  Stream<bool> get isFollowSystemThemeChange =>
      isFollowSystemTheme.distinct().skip(1);
  bool get isFollowSystemThemeValue => _isFollowSystemThemeController.value;
// _isUseBlackInDarkThemeController
  ValueStream<bool> get isUseBlackInDarkTheme =>
      _isUseBlackInDarkThemeController.stream;
  Stream<bool> get isUseBlackInDarkThemeNew => isUseBlackInDarkTheme.skip(1);
  Stream<bool> get isUseBlackInDarkThemeChange =>
      isUseBlackInDarkTheme.distinct().skip(1);
  bool get isUseBlackInDarkThemeValue => _isUseBlackInDarkThemeController.value;
// _seedColorController
  ValueStream<Color?> get seedColor => _seedColorController.stream;
  Stream<Color?> get seedColorNew => seedColor.skip(1);
  Stream<Color?> get seedColorChange => seedColor.distinct().skip(1);
  Color? get seedColorValue => _seedColorController.value;
// _secondarySeedColorController
  ValueStream<Color?> get secondarySeedColor =>
      _secondarySeedColorController.stream;
  Stream<Color?> get secondarySeedColorNew => secondarySeedColor.skip(1);
  Stream<Color?> get secondarySeedColorChange =>
      secondarySeedColor.distinct().skip(1);
  Color? get secondarySeedColorValue => _secondarySeedColorController.value;
// _isDontShowVideoPreviewHintController
  ValueStream<bool> get isDontShowVideoPreviewHint =>
      _isDontShowVideoPreviewHintController.stream;
  Stream<bool> get isDontShowVideoPreviewHintNew =>
      isDontShowVideoPreviewHint.skip(1);
  Stream<bool> get isDontShowVideoPreviewHintChange =>
      isDontShowVideoPreviewHint.distinct().skip(1);
  bool get isDontShowVideoPreviewHintValue =>
      _isDontShowVideoPreviewHintController.value;
// _mapBrowserPrevPositionController
  ValueStream<MapCoord?> get mapBrowserPrevPosition =>
      _mapBrowserPrevPositionController.stream;
  Stream<MapCoord?> get mapBrowserPrevPositionNew =>
      mapBrowserPrevPosition.skip(1);
  Stream<MapCoord?> get mapBrowserPrevPositionChange =>
      mapBrowserPrevPosition.distinct().skip(1);
  MapCoord? get mapBrowserPrevPositionValue =>
      _mapBrowserPrevPositionController.value;
// _isNewHttpEngineController
  ValueStream<bool> get isNewHttpEngine => _isNewHttpEngineController.stream;
  Stream<bool> get isNewHttpEngineNew => isNewHttpEngine.skip(1);
  Stream<bool> get isNewHttpEngineChange => isNewHttpEngine.distinct().skip(1);
  bool get isNewHttpEngineValue => _isNewHttpEngineController.value;
}

extension $SecurePrefControllerNpSubjectAccessor on SecurePrefController {
  // _protectedPageAuthTypeController
  ValueStream<ProtectedPageAuthType?> get protectedPageAuthType =>
      _protectedPageAuthTypeController.stream;
  Stream<ProtectedPageAuthType?> get protectedPageAuthTypeNew =>
      protectedPageAuthType.skip(1);
  Stream<ProtectedPageAuthType?> get protectedPageAuthTypeChange =>
      protectedPageAuthType.distinct().skip(1);
  ProtectedPageAuthType? get protectedPageAuthTypeValue =>
      _protectedPageAuthTypeController.value;
// _protectedPageAuthPinController
  ValueStream<CiString?> get protectedPageAuthPin =>
      _protectedPageAuthPinController.stream;
  Stream<CiString?> get protectedPageAuthPinNew => protectedPageAuthPin.skip(1);
  Stream<CiString?> get protectedPageAuthPinChange =>
      protectedPageAuthPin.distinct().skip(1);
  CiString? get protectedPageAuthPinValue =>
      _protectedPageAuthPinController.value;
// _protectedPageAuthPasswordController
  ValueStream<CiString?> get protectedPageAuthPassword =>
      _protectedPageAuthPasswordController.stream;
  Stream<CiString?> get protectedPageAuthPasswordNew =>
      protectedPageAuthPassword.skip(1);
  Stream<CiString?> get protectedPageAuthPasswordChange =>
      protectedPageAuthPassword.distinct().skip(1);
  CiString? get protectedPageAuthPasswordValue =>
      _protectedPageAuthPasswordController.value;
}
