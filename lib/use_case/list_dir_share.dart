import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/share.dart';

class ListDirShareItem {
  const ListDirShareItem(this.file, this.shares);

  /// The File returned contains only fileId and path. If you need other fields,
  /// you must query the file again
  final File file;
  final List<Share> shares;
}

class ListDirShare {
  const ListDirShare(this.shareRepo);

  /// List all shares from a given dir
  Future<List<ListDirShareItem>> call(Account account, File dir) async {
    final shares = await shareRepo.listDir(account, dir);
    final shareGroups = <int, List<Share>>{};
    for (final s in shares) {
      shareGroups[s.itemSource] ??= <Share>[];
      shareGroups[s.itemSource]!.add(s);
    }
    return shareGroups.entries
        .map((e) => ListDirShareItem(
            File(
              path: file_util.unstripPath(account, e.value.first.path),
              fileId: e.key,
            ),
            e.value))
        .toList();
  }

  final ShareRepo shareRepo;
}
