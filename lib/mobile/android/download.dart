import 'dart:async';

import 'package:flutter/services.dart';

class Download {
  static Future<int> downloadUrl({
    required String url,
    Map<String, String>? headers,
    String? mimeType,
    required String filename,
    bool? shouldNotify,
  }) async {
    return (await _channel.invokeMethod<int>("downloadUrl", <String, dynamic>{
      "url": url,
      "headers": headers,
      "mimeType": mimeType,
      "filename": filename,
      "shouldNotify": shouldNotify,
    }))!;
  }

  /// The download job has failed
  static const exceptionCodeDownloadError = "downloadError";

  static const _channel = MethodChannel("com.nkming.nc_photos/download");
}

class DownloadEvent {
  static StreamSubscription<DownloadCompleteEvent> listenDownloadComplete() =>
      _stream.listen(null);

  /// User canceled the download job
  static const exceptionCodeUserCanceled = "userCanceled";

  static const _downloadCompleteChannel = EventChannel(
      "com.nkming.nc_photos/download_event/action_download_complete");

  static late final _stream = _downloadCompleteChannel
      .receiveBroadcastStream()
      .map((data) => DownloadCompleteEvent(
            data["downloadId"],
            data["uri"],
          ))
      .handleError(
    (e, stackTrace) {
      throw AndroidDownloadError(e.details["downloadId"], e, stackTrace);
    },
    test: (e) =>
        e is PlatformException &&
        e.details is Map &&
        e.details["downloadId"] is int,
  );
}

class DownloadCompleteEvent {
  const DownloadCompleteEvent(this.downloadId, this.uri);

  final int downloadId;
  final String uri;
}

class AndroidDownloadError implements Exception {
  const AndroidDownloadError(this.downloadId, this.error, this.stackTrace);

  final int downloadId;
  final dynamic error;
  final StackTrace stackTrace;
}
