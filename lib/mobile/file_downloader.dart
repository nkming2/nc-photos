import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/mobile/android/download.dart';
import 'package:nc_photos/mobile/android/media_store.dart';
import 'package:nc_photos/platform/file_downloader.dart' as itf;
import 'package:nc_photos/platform/k.dart' as platform_k;

class FileDownloader extends itf.FileDownloader {
  @override
  downloadUrl({
    required String url,
    Map<String, String>? headers,
    String? mimeType,
    required String filename,
    bool? shouldNotify,
  }) {
    if (platform_k.isAndroid) {
      return _downloadUrlAndroid(
        url: url,
        headers: headers,
        mimeType: mimeType,
        filename: filename,
        shouldNotify: shouldNotify,
      );
    } else {
      throw UnimplementedError();
    }
  }

  Future<String> _downloadUrlAndroid({
    required String url,
    Map<String, String>? headers,
    String? mimeType,
    required String filename,
    bool? shouldNotify,
  }) async {
    try {
      _log.info("[_downloadUrlAndroid] Start downloading '$url'");
      final id = await Download.downloadUrl(
        url: url,
        headers: headers,
        mimeType: mimeType,
        filename: filename,
        shouldNotify: shouldNotify,
      );
      late final String uri;
      final completer = Completer();
      onDownloadComplete(DownloadCompleteEvent ev) {
        if (ev.downloadId == id) {
          _log.info(
              "[_downloadUrlAndroid] Finished downloading '$url' to '${ev.uri}'");
          uri = ev.uri;
          completer.complete();
        }
      }

      StreamSubscription<DownloadCompleteEvent>? subscription;
      try {
        subscription = DownloadEvent.listenDownloadComplete()
          ..onData(onDownloadComplete)
          ..onError((e, stackTrace) {
            completer.completeError(e, stackTrace);
          });
        await completer.future;
      } finally {
        subscription?.cancel();
      }
      return uri;
    } on PlatformException catch (e) {
      switch (e.code) {
        case MediaStore.exceptionCodePermissionError:
          throw PermissionException();

        case Download.exceptionCodeDownloadError:
          throw DownloadException(e.message);

        case DownloadEvent.exceptionCodeUserCanceled:
          throw JobCanceledException(e.message);

        default:
          rethrow;
      }
    }
  }

  static final _log = Logger("mobile.file_downloader.FileDownloader");
}
