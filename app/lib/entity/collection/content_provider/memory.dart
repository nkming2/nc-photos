import 'package:equatable/equatable.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection/util.dart';
import 'package:nc_photos/entity/collection_item/util.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:to_string/to_string.dart';

part 'memory.g.dart';

@toString
class CollectionMemoryProvider
    with EquatableMixin
    implements CollectionContentProvider {
  const CollectionMemoryProvider({
    required this.account,
    required this.year,
    required this.month,
    required this.day,
    this.cover,
  });

  @override
  String get fourCc => "MEMY";

  @override
  String get id => "$year-$month-$day";

  @override
  int? get count => null;

  @override
  DateTime get lastModified => DateTime(year, month, day);

  @override
  List<CollectionCapability> get capabilities => [];

  @override
  CollectionItemSort get itemSort => CollectionItemSort.dateDescending;

  @override
  List<CollectionShare> get shares => [];

  @override
  String? getCoverUrl(
    int width,
    int height, {
    bool? isKeepAspectRatio,
  }) {
    return cover?.run((cover) => api_util.getFilePreviewUrl(
          account,
          cover,
          width: width,
          height: height,
          isKeepAspectRatio: isKeepAspectRatio ?? false,
        ));
  }

  @override
  String toString() => _$toString();

  @override
  List<Object?> get props => [account, year, month, day, cover];

  final Account account;
  final int year;
  final int month;
  final int day;
  final FileDescriptor? cover;
}
