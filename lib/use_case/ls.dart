import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/string_extension.dart';

class Ls {
  Ls(this.fileRepo);

  /// List all files under a dir
  ///
  /// The resulting list would normally also include the [root] dir. If
  /// [shouldExcludeRootDir] == true, such entry will be removed
  Future<List<File>> call(Account account, File root,
      {bool shouldExcludeRootDir = true}) async {
    final products = await fileRepo.list(account, root);
    if (shouldExcludeRootDir) {
      // filter out root file
      final trimmedRootPath = root.path.trimAny("/");
      return products
          .where((element) => element.path.trimAny("/") != trimmedRootPath)
          .toList();
    } else {
      return products;
    }
  }

  final FileRepo fileRepo;
}
