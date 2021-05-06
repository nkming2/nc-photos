import 'dart:async';

import 'package:exifdart/exifdart_io.dart';
import 'package:exifdart/exifdart_memory.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/image_size_getter_util.dart';
import 'package:nc_photos/platform/metadata_loader.dart' as itf;

class MetadataLoader implements itf.MetadataLoader {
  @override
  loadCacheFile(Account account, File file) async {
    final getFileFuture =
        _getFileTask.getFileUntil(api_util.getFileUrl(account, file));
    final result = await Future.any([
      getFileFuture,
      Future.delayed(Duration(seconds: 10)),
    ]);
    if (_getFileTask.isGood && result is FileInfo) {
      return _onGetFile(file, result);
    } else {
      // timeout
      _getFileTask.cancel();
      throw TimeoutException("Timeout loading file: ${file.strippedPath}");
    }
  }

  @override
  loadNewFile(Account account, File file) async {
    final response =
        await Api(account).files().get(path: api_util.getFileUrlRelative(file));
    if (!response.isGood) {
      _log.severe("[loadNewFile] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }
    return itf.MetadataLoader.loadMetadata(
      file: file,
      exifdartReaderBuilder: () => MemoryBlobReader(response.body),
      imageSizeGetterInputBuilder: () => AsyncMemoryInput(response.body),
    );
  }

  @override
  loadFile(Account account, File file) async {
    final store = DefaultCacheManager().store;
    final info = await store.getFile(api_util.getFileUrl(account, file));
    if (info == null) {
      // no cache
      return loadNewFile(account, file);
    } else {
      return _onGetFile(file, info);
    }
  }

  @override
  cancel() {
    _getFileTask.cancel();
  }

  Future<Map<String, dynamic>> _onGetFile(File file, FileInfo info) {
    return itf.MetadataLoader.loadMetadata(
      file: file,
      exifdartReaderBuilder: () => FileReader(info.file),
      imageSizeGetterInputBuilder: () => AsyncFileInput(info.file),
    );
  }

  final _getFileTask = CancelableGetFile(DefaultCacheManager().store);

  static final _log = Logger("mobile.metadata_loader.MetadataLoader");
}
