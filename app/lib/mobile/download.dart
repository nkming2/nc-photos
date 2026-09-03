import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/platform/download.dart' as itf;
import 'package:nc_photos/use_case/download_file2.dart';
import 'package:nc_photos_plugin/nc_photos_plugin.dart';
import 'package:np_http/np_http.dart';
import 'package:np_log/np_log.dart';
import 'package:np_platform_local_media/np_platform_local_media.dart';

part 'download.g.dart';

class DownloadBuilder extends itf.DownloadBuilder {
  @override
  itf.Download build({
    required String url,
    Map<String, String>? headers,
    String? mimeType,
    required String filename,
    String? parentDir,
    required bool isPublic,
    bool? shouldNotify,
    void Function(double progress)? onProgress,
  }) {
    return _Download(
      url: url,
      headers: headers,
      mimeType: mimeType,
      filename: filename,
      parentDir: parentDir,
      isPublic: isPublic,
      onProgress: onProgress,
    );
  }
}

@npLog
class _Download extends itf.Download {
  _Download({
    required this.url,
    this.headers,
    this.mimeType,
    required this.filename,
    this.parentDir,
    required this.isPublic,
    this.onProgress,
  });

  @override
  Future<String> call() async {
    if (_isInitialDownload) {
      await _downloadFileManager.cleanUp();
      await _internalFileManager.cleanUp();
      setIsInitialDownload(false);
    }
    final (:dir, :file) = await _downloadFileManager.createNamedFile(filename);
    try {
      // download file to a temp dir
      final fileWrite = file.openWrite();
      try {
        final uri = Uri.parse(url);
        final response = await sendHttpRequest(
          () => http.Request("GET", uri)..headers.addAll(headers ?? {}),
        );
        bool isEnd = false;
        Object? error;
        final size = response.contentLength;
        var received = 0;
        final subscription = response.stream.listen(
          (value) {
            fileWrite.add(value);
            received += value.length;
            if (size != null && size > 0) {
              onProgress?.call((received / size).clamp(0, 1));
            }
          },
          onDone: () {
            isEnd = true;
          },
          onError: (e, stackTrace) {
            _log.severe("Failed while request", e, stackTrace);
            isEnd = true;
            error = e;
          },
          cancelOnError: true,
        );
        // wait until download finished
        while (!isEnd) {
          if (shouldInterrupt) {
            await subscription.cancel();
            break;
          }
          await Future.delayed(const Duration(seconds: 1));
        }
        if (error != null) {
          throw error!;
        }
      } finally {
        await fileWrite.flush();
        await fileWrite.close();
      }
      if (shouldInterrupt) {
        throw const JobCanceledException();
      }

      // copy the file to the actual dir
      if (isPublic) {
        return await LocalMedia.copyPrivateFileToPublicDir(
          file.path,
          srcMime: mimeType,
          dstDir: parentDir,
        );
      } else {
        final dstFile = await _copyFileToInternal(file);
        return await ContentUri.getUriForFile(dstFile.absolute.path);
      }
    } finally {
      await dir.delete(recursive: true);
    }
  }

  @override
  bool cancel() {
    shouldInterrupt = true;
    return true;
  }

  Future<File> _copyFileToInternal(File src) async {
    final (:dir, :file) = await _internalFileManager.createNamedFile(filename);
    await src.copy(file.path);
    return file;
  }

  final String url;
  final Map<String, String>? headers;
  final String? mimeType;
  final String filename;
  final String? parentDir;
  final bool isPublic;
  final void Function(double progress)? onProgress;

  bool shouldInterrupt = false;

  // ignore: deprecated_member_use_from_same_package
  static bool get _isInitialDownload => LegacyDownloadCompat.isInitialDownload;
  static void setIsInitialDownload(bool value) {
    LegacyDownloadCompat.setIsInitialDownload(value);
  }

  // ignore: deprecated_member_use_from_same_package
  static const _downloadFileManager = LegacyDownloadCompat.downloadFileManager;
  // ignore: deprecated_member_use_from_same_package
  static const _internalFileManager = LegacyDownloadCompat.internalFileManager;
}
