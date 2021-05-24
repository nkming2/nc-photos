// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/platform/downloader.dart' as itf;
import 'package:path/path.dart' as path;

class Downloader extends itf.Downloader {
  @override
  downloadFile(Account account, File file) async {
    final fileRepo = FileRepo(FileCachedDataSource());
    final fileContent = await fileRepo.getBinary(account, file);
    js.context.callMethod("webSaveAs", [
      html.Blob([fileContent]),
      path.basename(file.path),
    ]);
  }
}
