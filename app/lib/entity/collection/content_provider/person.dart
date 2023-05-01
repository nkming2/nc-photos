import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection/util.dart';
import 'package:nc_photos/entity/collection_item/util.dart';
import 'package:nc_photos/entity/person.dart';

class CollectionPersonProvider
    with EquatableMixin
    implements CollectionContentProvider {
  const CollectionPersonProvider({
    required this.account,
    required this.person,
  });

  @override
  String get fourCc => "PERS";

  @override
  String get id => person.name;

  @override
  int? get count => person.count;

  @override
  DateTime get lastModified => clock.now().toUtc();

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
    return api_util.getFacePreviewUrl(account, person.thumbFaceId,
        size: math.max(width, height));
  }

  @override
  List<Object?> get props => [account, person];

  final Account account;
  final Person person;
}
