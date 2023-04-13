import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection/adapter.dart';
import 'package:nc_photos/entity/collection/adapter/read_only_adapter.dart';
import 'package:nc_photos/entity/collection/content_provider/location_group.dart';
import 'package:nc_photos/entity/collection_item.dart';
import 'package:nc_photos/entity/collection_item/basic_item.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/use_case/list_location_file.dart';

class CollectionLocationGroupAdapter
    with CollectionReadOnlyAdapter
    implements CollectionAdapter {
  CollectionLocationGroupAdapter(this._c, this.account, this.collection)
      : assert(require(_c)),
        _provider =
            collection.contentProvider as CollectionLocationGroupProvider;

  static bool require(DiContainer c) => ListLocationFile.require(c);

  @override
  Stream<List<CollectionItem>> listItem() async* {
    final files = <File>[];
    for (final r in account.roots) {
      final dir = File(path: file_util.unstripPath(account, r));
      files.addAll(await ListLocationFile(_c)(account, dir,
          _provider.location.place, _provider.location.countryCode));
    }
    yield files
        .where((f) => file_util.isSupportedFormat(f))
        .map((f) => BasicCollectionFileItem(f))
        .toList();
  }

  @override
  Future<CollectionItem> adaptToNewItem(CollectionItem original) async {
    if (original is CollectionFileItem) {
      return BasicCollectionFileItem(original.file);
    } else {
      throw UnsupportedError("Unsupported type: ${original.runtimeType}");
    }
  }

  @override
  Future<void> remove() {
    throw UnsupportedError("Operation not supported");
  }

  final DiContainer _c;
  final Account account;
  final Collection collection;

  final CollectionLocationGroupProvider _provider;
}
