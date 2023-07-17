import 'package:nc_photos/entity/pref.dart';

/// [Pref] stored in memory, useful in unit tests
class PrefMemoryProvider extends PrefProvider {
  PrefMemoryProvider([
    Map<String, dynamic> initialData = const <String, dynamic>{},
  ]) : _data = Map.of(initialData);

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
    _data.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _data.clear();
    return true;
  }

  T? _get<T>(PrefKey key) => _data[key.toStringKey()];

  Future<bool> _set<T>(PrefKey key, T value) async {
    _data[key.toStringKey()] = value;
    return true;
  }

  final Map<String, dynamic> _data;
}
