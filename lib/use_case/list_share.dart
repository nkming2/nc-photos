import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';

/// List all shares from a given file
class ListShare {
  ListShare(this.shareRepo);

  Future<List<Share>> call(Account account, File file) =>
      shareRepo.list(account, file);

  final ShareRepo shareRepo;
}
