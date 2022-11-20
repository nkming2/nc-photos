import 'package:flutter/foundation.dart';

/// Store simple contents across different platforms
///
/// On mobile, the contents will be persisted as a file. On web, the contents
/// will be stored in local storage
abstract class UniversalStorage {
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

/// UniversalStorage backed by memory, useful in unit tests
@visibleForTesting
class UniversalMemoryStorage implements UniversalStorage {
  @override
  putBinary(String name, Uint8List content) async {
    data[name] = content;
  }

  @override
  getBinary(String name) async => data[name];

  @override
  putString(String name, String content) async {
    data[name] = content;
  }

  @override
  getString(String name) async => data[name];

  @override
  remove(String name) async {
    data.remove(name);
  }

  final data = <String, dynamic>{};
}
