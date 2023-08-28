import 'package:flutter/foundation.dart';
import 'package:np_universal_storage/src/universal_storage.dart';

/// UniversalStorage backed by memory, useful in unit tests
@visibleForTesting
class UniversalMemoryStorage implements UniversalStorage {
  @override
  Future<void> putBinary(String name, Uint8List content) async {
    data[name] = content;
  }

  @override
  Future<Uint8List?> getBinary(String name) async => data[name];

  @override
  Future<void> putString(String name, String content) async {
    data[name] = content;
  }

  @override
  Future<String?> getString(String name) async => data[name];

  @override
  Future<void> remove(String name) async {
    data.remove(name);
  }

  final data = <String, dynamic>{};
}
