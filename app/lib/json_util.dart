import 'dart:convert';

import 'package:nc_photos/object_extension.dart';

/// Convert a boolean to an indexable type in json for DB
///
/// This is needed because IndexedDB currently does not support creating an
/// index on a boolean value
Object? boolToJson(bool? value) => value?.run((v) => v ? 1 : 0);

/// Convert a boolean from an indexable type in json for DB
bool? boolFromJson(Object? value) => value?.run((v) => v != 0);

Object? tryJsonDecode(String source) {
  try {
    return jsonDecode(source);
  } catch (_) {
    return null;
  }
}

Object? jsonDecodeOr(String source, dynamic def) =>
    tryJsonDecode(source) ?? def;
