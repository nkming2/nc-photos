import 'dart:typed_data';

import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';

class PutFileBinary {
  PutFileBinary(this.fileRepo);

  /// Upload file to [path]
  Future<void> call(Account account, String path, Uint8List content) =>
      fileRepo.putBinary(account, path, content);

  final FileRepo fileRepo;
}
