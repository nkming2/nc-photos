import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection/adapter.dart';
import 'package:nc_photos/entity/collection_item.dart';
import 'package:np_codegen/np_codegen.dart';

part 'list_collection_item.g.dart';

@npLog
class ListCollectionItem {
  const ListCollectionItem(this._c);

  Stream<List<CollectionItem>> call(Account account, Collection collection) =>
      CollectionAdapter.of(_c, account, collection).listItem();

  final DiContainer _c;
}
