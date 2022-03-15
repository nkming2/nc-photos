import 'dart:async';

import 'package:flutter/services.dart';

class Lock {
  static Future<bool> tryLock(int lockId) async {
    return (await _channel.invokeMethod<bool>("tryLock", <String, dynamic>{
      "lockId": lockId,
    }))!;
  }

  static Future<void> unlock(int lockId) =>
      _channel.invokeMethod("unlock", <String, dynamic>{
        "lockId": lockId,
      });

  static const _channel = MethodChannel("com.nkming.nc_photos.plugin/lock");
}

class Notification {
  static Future<int?> notifyDownloadSuccessful(List<String> fileUris,
          List<String?> mimeTypes, int? notificationId) =>
      _channel.invokeMethod("notifyDownloadSuccessful", <String, dynamic>{
        "fileUris": fileUris,
        "mimeTypes": mimeTypes,
        "notificationId": notificationId,
      });

  static Future<int?> notifyDownloadProgress(int progress, int max,
          String? currentItemTitle, int? notificationId) =>
      _channel.invokeMethod("notifyDownloadProgress", <String, dynamic>{
        "progress": progress,
        "max": max,
        "currentItemTitle": currentItemTitle,
        "notificationId": notificationId,
      });

  static Future<int?> notifyLogSaveSuccessful(String fileUri) =>
      _channel.invokeMethod("notifyLogSaveSuccessful", <String, dynamic>{
        "fileUri": fileUri,
      });

  static Future<void> dismiss(int notificationId) =>
      _channel.invokeMethod("dismiss", <String, dynamic>{
        "notificationId": notificationId,
      });

  static const _channel =
      MethodChannel("com.nkming.nc_photos.plugin/notification");
}
