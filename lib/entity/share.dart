import 'package:equatable/equatable.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';

class Share with EquatableMixin {
  Share({
    required this.id,
    required this.shareType,
    required this.shareWith,
    required this.shareWithDisplayName,
  });

  @override
  toString() {
    return "$runtimeType {"
        "id: $id, "
        "shareType: $shareType, "
        "shareWith: $shareWith, "
        "shareWithDisplayName: $shareWithDisplayName, "
        "}";
  }

  @override
  get props => [
        id,
        shareType,
        shareWith,
        shareWithDisplayName,
      ];

  final String id;
  final int shareType;
  final String shareWith;
  final String shareWithDisplayName;
}

class ShareRepo {
  ShareRepo(this.dataSrc);

  /// See [ShareDataSource.list]
  Future<List<Share>> list(Account account, File file) =>
      this.dataSrc.list(account, file);

  /// See [ShareDataSource.create]
  Future<Share> create(Account account, File file, String shareWith) =>
      this.dataSrc.create(account, file, shareWith);

  /// See [ShareDataSource.delete]
  Future<void> delete(Account account, Share share) =>
      this.dataSrc.delete(account, share);

  final ShareDataSource dataSrc;
}

abstract class ShareDataSource {
  /// List all shares from a given file
  Future<List<Share>> list(Account account, File file);

  /// Share a file/folder with a user
  Future<Share> create(Account account, File file, String shareWith);

  /// Remove the given share
  Future<void> delete(Account account, Share share);
}
