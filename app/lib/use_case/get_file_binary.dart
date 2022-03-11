import 'dart:typed_data';

import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';

class GetFileBinary {
  GetFileBinary(this.fileRepo);

  /// Get the binary content of a file
  Future<Uint8List> call(Account account, File file) =>
      fileRepo.getBinary(account, file);

  final FileRepo fileRepo;
}
