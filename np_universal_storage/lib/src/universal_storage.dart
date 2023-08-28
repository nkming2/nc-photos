import 'dart:typed_data';

import 'package:np_universal_storage/src/native/universal_storage.dart'
    if (dart.library.html) 'package:np_universal_storage/src/web/universal_storage.dart'
    as impl;

/// Store simple contents across different platforms
///
/// On mobile, the contents will be persisted as a file. On web, the contents
/// will be stored in local storage
abstract class UniversalStorage {
  factory UniversalStorage() => impl.UniversalStorage();

  Future<void> putBinary(String name, Uint8List content);

  /// Return the content associated with [name], or null if no such association
  /// exists
  Future<Uint8List?> getBinary(String name);

  Future<void> putString(String name, String content);

  /// Return the string associated with [name], or null if no such association
  /// exists
  Future<String?> getString(String name);

  Future<void> remove(String name);
}
