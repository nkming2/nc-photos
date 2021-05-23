import 'dart:convert';
import 'dart:typed_data';

import 'package:nc_photos/platform/universal_storage.dart' as itf;
import 'package:shared_preferences/shared_preferences.dart';

const String _prefix = "_universal_storage";

class UniversalStorage extends itf.UniversalStorage {
  @override
  putBinary(String name, Uint8List content) async {
    // SharedPreferences happens to save to local storage on web, we'll just use
    // that
    final pref = await SharedPreferences.getInstance();
    await pref.setString("$_prefix.$name", base64UrlEncode(content));
  }

  @override
  getBinary(String name) async {
    final pref = await SharedPreferences.getInstance();
    final contentStr = pref.getString("$_prefix.$name");
    if (contentStr == null) {
      return null;
    } else {
      return base64Decode(contentStr);
    }
  }

  @override
  putString(String name, String content) async {
    // SharedPreferences happens to save to local storage on web, we'll just use
    // that
    final pref = await SharedPreferences.getInstance();
    await pref.setString("$_prefix.$name", content);
  }

  @override
  getString(String name) async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString("$_prefix.$name");
  }

  @override
  remove(String name) async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove("$_prefix.$name");
  }
}
