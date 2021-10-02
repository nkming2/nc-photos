import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/mobile/android/download.dart' as android;
import 'package:nc_photos/mobile/android/media_store.dart';
import 'package:nc_photos/platform/download.dart' as itf;
import 'package:nc_photos/platform/k.dart' as platform_k;

class DownloadBuilder extends itf.DownloadBuilder {
  @override
  build({
    required String url,
    Map<String, String>? headers,
    String? mimeType,
    required String filename,
    String? parentDir,
    bool? shouldNotify,
  }) {
    if (platform_k.isAndroid) {
      return _AndroidDownload(
        url: url,
        headers: headers,
        mimeType: mimeType,
        filename: filename,
        parentDir: parentDir,
        shouldNotify: shouldNotify,
      );
    } else {
      throw UnimplementedError();
    }
  }
}

class _AndroidDownload extends itf.Download {
  _AndroidDownload({
    required this.url,
    this.headers,
    this.mimeType,
    required this.filename,
    this.parentDir,
    this.shouldNotify,
  });

  @override
  call() async {
    final String path;
    if (parentDir?.isNotEmpty == true) {
      path = "$parentDir/$filename";
    } else {
      path = filename;
    }

    try {
      _log.info("[call] Start downloading '$url'");
      _downloadId = await android.Download.downloadUrl(
        url: url,
        headers: headers,
        mimeType: mimeType,
        filename: path,
        shouldNotify: shouldNotify,
      );
      _log.info("[call] #$_downloadId -> '$url'");
      late final String uri;
      final completer = Completer();
      onDownloadComplete(android.DownloadCompleteEvent ev) {
        if (ev.downloadId == _downloadId) {
          _log.info("[call] Finished downloading '$url' to '${ev.uri}'");
          uri = ev.uri;
          completer.complete();
        }
      }

      StreamSubscription<android.DownloadCompleteEvent>? subscription;
      try {
        subscription = android.DownloadEvent.listenDownloadComplete()
          ..onData(onDownloadComplete)
          ..onError((e, stackTrace) {
            if (e is android.AndroidDownloadError) {
              if (e.downloadId != _downloadId) {
                // not us, ignore
                return;
              }
              completer.completeError(e.error, e.stackTrace);
            } else {
              completer.completeError(e, stackTrace);
            }
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

        case android.Download.exceptionCodeDownloadError:
          throw DownloadException(e.message);

        case android.DownloadEvent.exceptionCodeUserCanceled:
          throw JobCanceledException(e.message);

        default:
          rethrow;
      }
    }
  }

  @override
  cancel() async {
    if (_downloadId != null) {
      _log.info("[cancel] Cancel #$_downloadId");
      return await android.Download.cancel(id: _downloadId!);
    } else {
      return false;
    }
  }

  final String url;
  final Map<String, String>? headers;
  final String? mimeType;
  final String filename;
  final String? parentDir;
  final bool? shouldNotify;
  int? _downloadId;

  static final _log = Logger("mobile.download._AndroidDownload");
}
