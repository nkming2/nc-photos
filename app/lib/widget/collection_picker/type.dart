part of '../collection_picker.dart';

@npLog
class _Item {
  _Item(this.collection) {
    try {
      _coverUrl = collection.getCoverUrl(k.coverSize, k.coverSize);
    } catch (e, stackTrace) {
      _log.warning("[_CollectionItem] Failed while getCoverUrl", e, stackTrace);
    }
  }

  String get name => collection.name;

  String? get coverUrl => _coverUrl;

  final Collection collection;
  String? _coverUrl;
}
