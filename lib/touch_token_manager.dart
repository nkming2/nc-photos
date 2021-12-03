import 'dart:convert';

import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/use_case/get_file_binary.dart';
import 'package:nc_photos/use_case/put_file_binary.dart';
import 'package:nc_photos/use_case/remove.dart';

/// Manage touch token for files
///
/// Touch tokens are used to broadcast file changes that don't trigger an ETag
/// update to other devices. Such changes include custom properties like
/// metadata. In order to detect these hidden changes, you should get both
/// local and remote tokens and compare them. Beware that getting the remote
/// token requires downloading a file from the server so you may want to avoid
/// doing it on every query
class TouchTokenManager {
  Future<void> setRemoteToken(
      FileRepo fileRepo, Account account, File file, String? token) async {
    _log.info(
        "[setRemoteToken] Set remote token for file '${file.path}': $token");
    final path = _getRemotePath(account, file);
    if (token == null) {
      return Remove(KiwiContainer().resolve<DiContainer>())(account, [file],
          shouldCleanUp: false);
    } else {
      return PutFileBinary(fileRepo)(
          account, path, const Utf8Encoder().convert(token),
          shouldCreateMissingDir: true);
    }
  }

  /// Return the touch token for [file] from remote source, or null if no such
  /// file
  Future<String?> getRemoteToken(
      FileRepo fileRepo, Account account, File file) async {
    final path = _getRemotePath(account, file);
    try {
      final content = await GetFileBinary(fileRepo)(account, File(path: path));
      return const Utf8Decoder().convert(content);
    } on ApiException catch (e) {
      if (e.response.statusCode == 404) {
        return null;
      } else {
        rethrow;
      }
    }
  }

  Future<void> setLocalToken(Account account, File file, String? token) {
    _log.info(
        "[setLocalToken] Set local token for file '${file.path}': $token");
    final name = _getLocalStorageName(account, file);
    if (token == null) {
      return platform.UniversalStorage().remove(name);
    } else {
      return platform.UniversalStorage().putString(name, token);
    }
  }

  Future<String?> getLocalToken(Account account, File file) async {
    final name = _getLocalStorageName(account, file);
    return platform.UniversalStorage().getString(name);
  }

  String _getRemotePath(Account account, File file) {
    final strippedPath = file.strippedPath;
    if (strippedPath == ".") {
      return "${remote_storage_util.getRemoteTouchDir(account)}/token.txt";
    } else {
      return "${remote_storage_util.getRemoteTouchDir(account)}/${file.strippedPath}/token.txt";
    }
  }

  String _getLocalStorageName(Account account, File file) {
    final strippedPath = file.strippedPath;
    if (strippedPath == ".") {
      return "touch/${account.url.replaceFirst('://', '_')}/${account.username}/token";
    } else {
      return "touch/${account.url.replaceFirst('://', '_')}/${account.username}/${file.strippedPath}/token";
    }
  }

  static final _log = Logger("touch_token_manager.TouchTokenManager");
}
