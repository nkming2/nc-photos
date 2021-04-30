import 'dart:io';

import 'package:flutter/services.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/mobile/android/media_store.dart';
import 'package:nc_photos/platform/downloader.dart' as itf;
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/use_case/get_file_binary.dart';
import 'package:path/path.dart' as path;

class Downloader extends itf.Downloader {
  @override
  downloadFile(Account account, File file) {
    if (platform_k.isAndroid) {
      return _downloadFileAndroid(account, file);
    } else {
      throw UnimplementedError();
    }
  }

  Future<String> _downloadFileAndroid(Account account, File file) async {
    final fileRepo = FileRepo(FileCachedDataSource());
    final fileContent = await GetFileBinary(fileRepo)(account, file);
    try {
      return await MediaStore.saveFileToDownload(
          path.basename(file.path), fileContent);
    } on PlatformException catch (e) {
      if (e.code == MediaStore.exceptionCodePermissionError) {
        throw PermissionException();
      } else {
        rethrow;
      }
    }
  }
}
