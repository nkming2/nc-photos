import 'package:flutter/services.dart';

class Share {
  static Future<void> shareItems(
          List<String> fileUris, List<String?> mimeTypes) =>
      _channel.invokeMethod("shareItems", <String, dynamic>{
        "fileUris": fileUris,
        "mimeTypes": mimeTypes,
      });

  static const _channel = const MethodChannel("com.nkming.nc_photos/share");
}
