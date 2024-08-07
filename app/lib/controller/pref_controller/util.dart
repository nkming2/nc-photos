part of '../pref_controller.dart';

extension on Pref {
  int? getHomeAlbumsSort() => provider.getInt(PrefKey.homeAlbumsSort);
  int getHomeAlbumsSortOr(int def) => getHomeAlbumsSort() ?? def;
  Future<bool> setHomeAlbumsSort(int value) =>
      provider.setInt(PrefKey.homeAlbumsSort, value);

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

  int? getGpsMapProvider() => provider.getInt(PrefKey.gpsMapProvider);
  int getGpsMapProviderOr(int def) => getGpsMapProvider() ?? def;
  Future<bool> setGpsMapProvider(int value) =>
      provider.setInt(PrefKey.gpsMapProvider, value);

  int? getSeedColor() => provider.getInt(PrefKey.seedColor);
  // int getSeedColorOr(int def) => getSeedColor() ?? def;
  Future<bool> setSeedColor(int? value) {
    if (value == null) {
      return provider.remove(PrefKey.seedColor);
    } else {
      return provider.setInt(PrefKey.seedColor, value);
    }
  }

  int? getSecondarySeedColor() => provider.getInt(PrefKey.secondarySeedColor);
  // int getSecondarySeedColorOr(int def) => getSecondarySeedColor() ?? def;
  Future<bool> setSecondarySeedColor(int? value) {
    if (value == null) {
      return provider.remove(PrefKey.secondarySeedColor);
    } else {
      return provider.setInt(PrefKey.secondarySeedColor, value);
    }
  }

  int? getProtectedPageAuthType() =>
      provider.getInt(PrefKey.protectedPageAuthType);
  // int getProtectedPageAuthTypeOr(int def) => getProtectedPageAuthType() ?? def;
  Future<bool> setProtectedPageAuthType(int? value) {
    if (value == null) {
      return provider.remove(PrefKey.protectedPageAuthType);
    } else {
      return provider.setInt(PrefKey.protectedPageAuthType, value);
    }
  }

  String? getProtectedPageAuthPin() =>
      provider.getString(PrefKey.protectedPageAuthPin);
  // String getProtectedPageAuthPinOr(String def) =>
  //     getProtectedPageAuthPin() ?? def;
  Future<bool> setProtectedPageAuthPin(String? value) {
    if (value == null) {
      return provider.remove(PrefKey.protectedPageAuthPin);
    } else {
      return provider.setString(PrefKey.protectedPageAuthPin, value);
    }
  }

  String? getProtectedPageAuthPassword() =>
      provider.getString(PrefKey.protectedPageAuthPassword);
  // String getProtectedPageAuthPasswordOr(String def) =>
  //     getProtectedPageAuthPassword() ?? def;
  Future<bool> setProtectedPageAuthPassword(String? value) {
    if (value == null) {
      return provider.remove(PrefKey.protectedPageAuthPassword);
    } else {
      return provider.setString(PrefKey.protectedPageAuthPassword, value);
    }
  }

  bool? isDontShowVideoPreviewHint() =>
      provider.getBool(PrefKey.dontShowVideoPreviewHint);
  bool isDontShowVideoPreviewHintOr(bool def) =>
      isDontShowVideoPreviewHint() ?? def;
  Future<bool> setDontShowVideoPreviewHint(bool value) =>
      provider.setBool(PrefKey.dontShowVideoPreviewHint, value);

  String? getMapBrowserPrevPosition() =>
      provider.getString(PrefKey.mapBrowserPrevPosition);
  Future<bool> setMapBrowserPrevPosition(String? value) {
    if (value == null) {
      return provider.remove(PrefKey.mapBrowserPrevPosition);
    } else {
      return provider.setString(PrefKey.mapBrowserPrevPosition, value);
    }
  }

  Future<bool> setNewHttpEngine(bool value) =>
      provider.setBool(PrefKey.isNewHttpEngine, value);
}

MapCoord? _tryMapCoordFromJson(dynamic json) {
  try {
    final j = (json as List).cast<double>();
    return MapCoord(j[0], j[1]);
  } catch (e, stackTrace) {
    _$__NpLog.log
        .severe("[_tryMapCoordFromJson] Failed to parse json", e, stackTrace);
    return null;
  }
}
