import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file_descriptor.dart';

class ListArchivedFile {
  const ListArchivedFile(this._c);

  /// Return list of archived files
  Future<List<FileDescriptor>> call(Account account, String shareDirPath) =>
      _c.fileRepo2.getFileDescriptors(account, shareDirPath, isArchived: true);

  final DiContainer _c;
}
