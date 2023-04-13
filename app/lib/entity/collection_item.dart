import 'package:nc_photos/entity/file_descriptor.dart';

/// An item in a [Collection]
abstract class CollectionItem {
  const CollectionItem();
}

abstract class CollectionFileItem implements CollectionItem {
  const CollectionFileItem();

  FileDescriptor get file;
}

abstract class CollectionLabelItem implements CollectionItem {
  const CollectionLabelItem();

  /// An object used to identify this instance
  ///
  /// [id] should be unique and stable
  Object get id;
  String get text;
}
