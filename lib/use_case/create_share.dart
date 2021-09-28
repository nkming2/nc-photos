import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';

class CreateLinkShare {
  const CreateLinkShare(this.shareRepo);

  Future<Share> call(
    Account account,
    File file, {
    String? password,
  }) =>
      shareRepo.createLink(account, file, password: password);

  final ShareRepo shareRepo;
}
