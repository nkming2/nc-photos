import 'dart:convert';
import 'dart:typed_data';

import 'package:np_universal_storage/src/universal_storage.dart' as itf;
import 'package:shared_preferences/shared_preferences.dart';

const String _prefix = "_universal_storage";

class UniversalStorage implements itf.UniversalStorage {
  @override
  Future<void> putBinary(String name, Uint8List content) async {
    // SharedPreferences happens to save to local storage on web, we'll just use
    // that
    final pref = await SharedPreferences.getInstance();
    await pref.setString("$_prefix.$name", base64UrlEncode(content));
  }

  @override
  Future<Uint8List?> getBinary(String name) async {
    final pref = await SharedPreferences.getInstance();
    final contentStr = pref.getString("$_prefix.$name");
    if (contentStr == null) {
      return null;
    } else {
      return base64Decode(contentStr);
    }
  }

  @override
  Future<void> putString(String name, String content) async {
    // SharedPreferences happens to save to local storage on web, we'll just use
    // that
    final pref = await SharedPreferences.getInstance();
    await pref.setString("$_prefix.$name", content);
  }

  @override
  Future<String?> getString(String name) async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString("$_prefix.$name");
  }

  @override
  Future<void> remove(String name) async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove("$_prefix.$name");
  }
}
