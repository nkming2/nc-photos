import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';

/// List all shares by other users from a given file
class ListShareWithMe {
  ListShareWithMe(this.shareRepo);

  Future<List<Share>> call(Account account, File file) =>
      shareRepo.reverseList(account, file);

  final ShareRepo shareRepo;
}
