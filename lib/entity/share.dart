import 'package:equatable/equatable.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';

enum ShareType {
  user,
  group,
  publicLink,
  email,
  federatedCloudShare,
  circle,
  talk,
}

extension ShareTypeExtension on ShareType {
  static ShareType fromValue(int shareTypeVal) {
    switch (shareTypeVal) {
      case 0:
        return ShareType.user;
      case 1:
        return ShareType.group;
      case 3:
        return ShareType.publicLink;
      case 4:
        return ShareType.email;
      case 6:
        return ShareType.federatedCloudShare;
      case 7:
        return ShareType.circle;
      case 10:
        return ShareType.talk;
      default:
        throw ArgumentError("Invalid shareType: $shareTypeVal");
    }
  }

  int toValue() {
    switch (this) {
      case ShareType.user:
        return 0;
      case ShareType.group:
        return 1;
      case ShareType.publicLink:
        return 3;
      case ShareType.email:
        return 4;
      case ShareType.federatedCloudShare:
        return 6;
      case ShareType.circle:
        return 7;
      case ShareType.talk:
        return 10;
    }
  }
}

class Share with EquatableMixin {
  Share({
    required this.id,
    required this.path,
    required this.shareType,
    required this.shareWith,
    required this.shareWithDisplayName,
    this.url,
  });

  @override
  toString() {
    return "$runtimeType {"
        "id: $id, "
        "path: $path, "
        "shareType: $shareType, "
        "shareWith: $shareWith, "
        "shareWithDisplayName: $shareWithDisplayName, "
        "url: $url, "
        "}";
  }

  @override
  get props => [
        id,
        path,
        shareType,
        shareWith,
        shareWithDisplayName,
        url,
      ];

  final String id;
  final String path;
  final ShareType shareType;
  final String? shareWith;
  final String shareWithDisplayName;
  final String? url;
}

class ShareRepo {
  ShareRepo(this.dataSrc);

  /// See [ShareDataSource.list]
  Future<List<Share>> list(Account account, File file) =>
      dataSrc.list(account, file);

  /// See [ShareDataSource.listDir]
  Future<List<Share>> listDir(Account account, File dir) =>
      dataSrc.listDir(account, dir);

  /// See [ShareDataSource.create]
  Future<Share> create(Account account, File file, String shareWith) =>
      dataSrc.create(account, file, shareWith);

  /// See [ShareDataSource.createLink]
  Future<Share> createLink(
    Account account,
    File file, {
    String? password,
  }) =>
      dataSrc.createLink(account, file, password: password);

  /// See [ShareDataSource.delete]
  Future<void> delete(Account account, Share share) =>
      dataSrc.delete(account, share);

  final ShareDataSource dataSrc;
}

abstract class ShareDataSource {
  /// List all shares from a given file
  Future<List<Share>> list(Account account, File file);

  /// List all shares from a given directory
  Future<List<Share>> listDir(Account account, File dir);

  /// Share a file/folder with a user
  Future<Share> create(Account account, File file, String shareWith);

  /// Share a file/folder with a share link
  ///
  /// If [password] is not null, the share link will be password protected
  Future<Share> createLink(
    Account account,
    File file, {
    String? password,
  });

  /// Remove the given share
  Future<void> delete(Account account, Share share);
}
