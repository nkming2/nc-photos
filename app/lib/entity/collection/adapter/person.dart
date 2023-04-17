import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection/adapter.dart';
import 'package:nc_photos/entity/collection/adapter/read_only_adapter.dart';
import 'package:nc_photos/entity/collection/content_provider/person.dart';
import 'package:nc_photos/entity/collection_item.dart';
import 'package:nc_photos/entity/collection_item/basic_item.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/use_case/list_face.dart';
import 'package:nc_photos/use_case/populate_person.dart';

class CollectionPersonAdapter
    with CollectionReadOnlyAdapter
    implements CollectionAdapter {
  CollectionPersonAdapter(this._c, this.account, this.collection)
      : assert(require(_c)),
        _provider = collection.contentProvider as CollectionPersonProvider;

  static bool require(DiContainer c) =>
      ListFace.require(c) && PopulatePerson.require(c);

  @override
  Stream<List<CollectionItem>> listItem() async* {
    final faces = await ListFace(_c)(account, _provider.person);
    final files = await PopulatePerson(_c)(account, faces);
    final rootDirs = account.roots
        .map((e) => File(path: file_util.unstripPath(account, e)))
        .toList();
    yield files
        .where((f) =>
            file_util.isSupportedFormat(f) &&
            rootDirs.any((dir) => file_util.isUnderDir(f, dir)))
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

  @override
  bool isPermitted(CollectionCapability capability) =>
      _provider.capabilities.contains(capability);

  final DiContainer _c;
  final Account account;
  final Collection collection;

  final CollectionPersonProvider _provider;
}
