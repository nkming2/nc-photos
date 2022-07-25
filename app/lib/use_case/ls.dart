import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/string_extension.dart';

class Ls {
  Ls(this.fileRepo);

  /// List all files under a dir
  ///
  /// The dir itself is not included in the returned list
  Future<List<File>> call(Account account, File dir) async {
    final products = await fileRepo.list(account, dir);
    // filter out root file
    final trimmedRootPath = dir.path.trimAny("/");
    return products
        .where((element) => element.path.trimAny("/") != trimmedRootPath)
        .toList();
  }

  final FileRepo fileRepo;
}

class LsMinimal implements Ls {
  const LsMinimal(this.fileRepo);

  /// List all files under a dir with minimal data
  ///
  /// The dir itself is not included in the returned list
  @override
  Future<List<File>> call(Account account, File dir) async {
    final products = await fileRepo.listMinimal(account, dir);
    // filter out root file
    final trimmedRootPath = dir.path.trimAny("/");
    return products
        .where((element) => element.path.trimAny("/") != trimmedRootPath)
        .toList();
  }

  @override
  final FileRepo fileRepo;
}
