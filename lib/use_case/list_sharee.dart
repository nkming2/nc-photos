import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/sharee.dart';

/// List all sharees of an account
class ListSharee {
  ListSharee(this.shareeRepo);

  Future<List<Sharee>> call(Account account) => shareeRepo.list(account);

  final ShareeRepo shareeRepo;
}
