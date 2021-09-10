import 'package:flutter/services.dart';

class Notification {
  static Future<void> notifyItemsDownloadSuccessful(
          List<String> fileUris, List<String?> mimeTypes) =>
      _channel.invokeMethod("notifyItemsDownloadSuccessful", <String, dynamic>{
        "fileUris": fileUris,
        "mimeTypes": mimeTypes,
      });

  static Future<void> notifyLogSaveSuccessful(String fileUri) =>
      _channel.invokeMethod("notifyLogSaveSuccessful", <String, dynamic>{
        "fileUri": fileUri,
      });

  static const _channel =
      const MethodChannel("com.nkming.nc_photos/notification");
}
