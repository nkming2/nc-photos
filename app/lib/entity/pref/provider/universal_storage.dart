import 'dart:convert';

import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;

/// [Pref] backed by [UniversalStorage]
class PrefUniversalStorageProvider extends PrefProvider {
  PrefUniversalStorageProvider(this.name);

  Future<void> init() async {
    final prefStr = await platform.UniversalStorage().getString(name) ?? "{}";
    _data
      ..clear()
      ..addAll(jsonDecode(prefStr));
  }

  @override
  bool? getBool(PrefKey key) => _get<bool>(key);
  @override
  Future<bool> setBool(PrefKey key, bool value) => _set(key, value);

  @override
  int? getInt(PrefKey key) => _get<int>(key);
  @override
  Future<bool> setInt(PrefKey key, int value) => _set(key, value);

  @override
  String? getString(PrefKey key) => _get<String>(key);
  @override
  Future<bool> setString(PrefKey key, String value) => _set(key, value);

  @override
  List<String>? getStringList(PrefKey key) => _get<List<String>>(key);
  @override
  Future<bool> setStringList(PrefKey key, List<String> value) =>
      _set(key, value);

  @override
  Future<bool> remove(PrefKey key) async {
    final newData = Map.of(_data)..remove(key.toStringKey());
    await platform.UniversalStorage().putString(name, jsonEncode(newData));
    _data.remove(key.toStringKey());
    return true;
  }

  @override
  Future<bool> clear() async {
    await platform.UniversalStorage().remove(name);
    _data.clear();
    return true;
  }

  T? _get<T>(PrefKey key) => _data[key.toStringKey()];

  Future<bool> _set<T>(PrefKey key, T value) async {
    final newData = Map.of(_data)
      ..addEntries([MapEntry(key.toStringKey(), value)]);
    await platform.UniversalStorage().putString(name, jsonEncode(newData));
    _data[key.toStringKey()] = value;
    return true;
  }

  final String name;
  final _data = <String, dynamic>{};
}
