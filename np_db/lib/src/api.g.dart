// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$NpDbNpLog on NpDb {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("src.api.NpDb");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$DbFileKeyToString on DbFileKey {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "DbFileKey {${fileId == null ? "" : "fileId: $fileId, "}${relativePath == null ? "" : "relativePath: $relativePath"}}";
  }
}

extension _$DbLocationGroupToString on DbLocationGroup {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "DbLocationGroup {place: $place, countryCode: $countryCode, count: $count, latestFileId: $latestFileId, latestDateTime: $latestDateTime}";
  }
}

extension _$DbLocationGroupResultToString on DbLocationGroupResult {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "DbLocationGroupResult {name: [length: ${name.length}], admin1: [length: ${admin1.length}], admin2: [length: ${admin2.length}], countryCode: [length: ${countryCode.length}]}";
  }
}
