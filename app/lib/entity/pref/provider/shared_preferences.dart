import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/use_case/compat/v34.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [Pref] stored with [SharedPreferences] lib
class PrefSharedPreferencesProvider extends PrefProvider {
  Future<void> init() async {
    // Obsolete, CompatV34 is compatible with pre v32 versions
    // if (await CompatV32.isPrefNeedMigration()) {
    //   await CompatV32.migratePref();
    // }
    if (await CompatV34.isPrefNeedMigration()) {
      await CompatV34.migratePref(platform.UniversalStorage());
    }
    return SharedPreferences.getInstance().then((pref) {
      _pref = pref;
    });
  }

  @override
  bool? getBool(PrefKeyInterface key) => _pref.getBool(key.toStringKey());

  @override
  Future<bool> setBool(PrefKeyInterface key, bool value) =>
      _pref.setBool(key.toStringKey(), value);

  @override
  int? getInt(PrefKeyInterface key) => _pref.getInt(key.toStringKey());

  @override
  Future<bool> setInt(PrefKeyInterface key, int value) =>
      _pref.setInt(key.toStringKey(), value);

  @override
  String? getString(PrefKeyInterface key) => _pref.getString(key.toStringKey());

  @override
  Future<bool> setString(PrefKeyInterface key, String value) =>
      _pref.setString(key.toStringKey(), value);

  @override
  List<String>? getStringList(PrefKeyInterface key) =>
      _pref.getStringList(key.toStringKey());

  @override
  Future<bool> setStringList(PrefKeyInterface key, List<String> value) =>
      _pref.setStringList(key.toStringKey(), value);

  @override
  Future<bool> remove(PrefKeyInterface key) => _pref.remove(key.toStringKey());

  @override
  Future<bool> clear() => _pref.clear();

  late SharedPreferences _pref;
}
