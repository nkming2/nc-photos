import 'package:flutter/services.dart';

class Notification {
  static Future<void> notifyItemDownloadSuccessful(
          String fileUri, String mimeType) =>
      _channel.invokeMethod("notifyItemDownloadSuccessful", <String, dynamic>{
        "fileUri": fileUri,
        "mimeType": mimeType,
      });

  static const _channel =
      const MethodChannel("com.nkming.nc_photos/notification");
}
