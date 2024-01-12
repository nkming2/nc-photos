import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file_descriptor.dart';

class ListFile {
  const ListFile(this._c);

  Stream<List<FileDescriptor>> call(Account account, String shareDirPath) =>
      _c.fileRepo2.getFileDescriptors(account, shareDirPath);

  final DiContainer _c;
}
