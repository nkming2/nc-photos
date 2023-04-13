import 'package:clock/clock.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection_item/util.dart';
import 'package:nc_photos/entity/tag.dart';

class CollectionTagProvider implements CollectionContentProvider {
  CollectionTagProvider({
    required this.account,
    required this.tags,
  }) : assert(tags.isNotEmpty);

  @override
  String get fourCc => "TAG-";

  @override
  String get id => tags.first.displayName;

  @override
  int? get count => null;

  @override
  DateTime get lastModified => clock.now().toUtc();

  @override
  List<CollectionCapability> get capabilities => [];

  @override
  CollectionItemSort get itemSort => CollectionItemSort.dateDescending;

  @override
  String? getCoverUrl(int width, int height) => null;

  final Account account;
  final List<Tag> tags;
}
