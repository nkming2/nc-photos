import 'package:flutter/material.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/android/android_info.dart';
import 'package:nc_photos/mobile/android/permission_util.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos_plugin/nc_photos_plugin.dart';

/// Handle platform permissions
class PermissionHandler {
  const PermissionHandler();

  Future<bool> ensureStorageWritePermission() async {
    if (platform_k.isAndroid) {
      if (AndroidInfo().sdkInt < AndroidVersion.R &&
          !await Permission.hasWriteExternalStorage()) {
        final results = await requestPermissionsForResult([
          Permission.WRITE_EXTERNAL_STORAGE,
        ]);
        if (results[Permission.WRITE_EXTERNAL_STORAGE] !=
            PermissionRequestResult.granted) {
          SnackBarManager().showSnackBar(SnackBar(
            content: Text(L10n.global().errorNoStoragePermission),
            duration: k.snackBarDurationNormal,
          ));
          return false;
        } else {
          return true;
        }
      }
    }
    return true;
  }
}
