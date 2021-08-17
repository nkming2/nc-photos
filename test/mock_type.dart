import 'dart:typed_data';

import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/or_null.dart';

/// Mock of [FileRepo] where all methods will throw UnimplementedError
class MockFileRepo implements FileRepo {
  @override
  Future<void> copy(Object account, File f, String destination,
      {bool? shouldOverwrite}) {
    throw UnimplementedError();
  }

  @override
  Future<void> createDir(Account account, String path) {
    throw UnimplementedError();
  }

  @override
  FileDataSource get dataSrc => throw UnimplementedError();

  @override
  Future<Uint8List> getBinary(Account account, File file) {
    throw UnimplementedError();
  }

  @override
  Future<List<File>> list(Account account, File root) async {
    throw UnimplementedError();
  }

  @override
  Future<void> move(Account account, File f, String destination,
      {bool? shouldOverwrite}) {
    throw UnimplementedError();
  }

  @override
  Future<void> putBinary(Account account, String path, Uint8List content) {
    throw UnimplementedError();
  }

  @override
  Future<void> remove(Account account, File file) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateProperty(Account account, File file,
      {OrNull<Metadata>? metadata,
      OrNull<bool>? isArchived,
      OrNull<DateTime>? overrideDateTime}) {
    throw UnimplementedError();
  }
}
