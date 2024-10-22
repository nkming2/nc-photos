part of '../account_pref_controller.dart';

extension on AccountPref {
  bool? hasNewSharedAlbum() =>
      provider.getBool(AccountPrefKey.hasNewSharedAlbum);
  // Future<bool> setNewSharedAlbum(bool value) =>
  //     provider.setBool(AccountPrefKey.hasNewSharedAlbum, value);
}
