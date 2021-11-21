import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';

class LsSingleFile {
  LsSingleFile(this.fileRepo);

  Future<File> call(Account account, String path) =>
      fileRepo.listSingle(account, File(path: path));

  final FileRepo fileRepo;
}
