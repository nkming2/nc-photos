import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';

class LsSingleFile {
  LsSingleFile(this.dataSrc);

  Future<File> call(Account account, String path) async {
    final files = await dataSrc.list(account, File(path: path), depth: 0);
    assert(files.length == 1);
    return files.first;
  }

  final FileWebdavDataSource dataSrc;
}
