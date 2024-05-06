// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api.dart';

// **************************************************************************
// CopyWithLintRuleGenerator
// **************************************************************************

// ignore_for_file: library_private_types_in_public_api, duplicate_ignore

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class $DbFilesSummaryItemCopyWithWorker {
  DbFilesSummaryItem call({int? count});
}

class _$DbFilesSummaryItemCopyWithWorkerImpl
    implements $DbFilesSummaryItemCopyWithWorker {
  _$DbFilesSummaryItemCopyWithWorkerImpl(this.that);

  @override
  DbFilesSummaryItem call({dynamic count}) {
    return DbFilesSummaryItem(count: count as int? ?? that.count);
  }

  final DbFilesSummaryItem that;
}

extension $DbFilesSummaryItemCopyWith on DbFilesSummaryItem {
  $DbFilesSummaryItemCopyWithWorker get copyWith => _$copyWith;
  $DbFilesSummaryItemCopyWithWorker get _$copyWith =>
      _$DbFilesSummaryItemCopyWithWorkerImpl(this);
}

abstract class $DbFilesSummaryCopyWithWorker {
  DbFilesSummary call({Map<Date, DbFilesSummaryItem>? items});
}

class _$DbFilesSummaryCopyWithWorkerImpl
    implements $DbFilesSummaryCopyWithWorker {
  _$DbFilesSummaryCopyWithWorkerImpl(this.that);

  @override
  DbFilesSummary call({dynamic items}) {
    return DbFilesSummary(
        items: items as Map<Date, DbFilesSummaryItem>? ?? that.items);
  }

  final DbFilesSummary that;
}

extension $DbFilesSummaryCopyWith on DbFilesSummary {
  $DbFilesSummaryCopyWithWorker get copyWith => _$copyWith;
  $DbFilesSummaryCopyWithWorker get _$copyWith =>
      _$DbFilesSummaryCopyWithWorkerImpl(this);
}

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

extension _$DbSyncIdResultToString on DbSyncIdResult {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "DbSyncIdResult {insert: [length: ${insert.length}], delete: [length: ${delete.length}], update: [length: ${update.length}]}";
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

extension _$DbFilesSummaryItemToString on DbFilesSummaryItem {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "DbFilesSummaryItem {count: $count}";
  }
}

extension _$DbFilesSummaryToString on DbFilesSummary {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "DbFilesSummary {items: {length: ${items.length}}}";
  }
}
