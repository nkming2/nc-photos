part of '../home_collections.dart';

enum _ItemType {
  ncAlbum,
  album,
  dirAlbum,
  tagAlbum,
}

@npLog
class _Item implements SelectableItemMetadata {
  _Item(this.collection) {
    if (collection.count != null) {
      _subtitle = L10n.global().albumSize(collection.count!);
    }
    try {
      _coverUrl = collection.getCoverUrl(k.coverSize, k.coverSize);
    } catch (e, stackTrace) {
      _log.warning("[_CollectionItem] Failed while getCoverUrl", e, stackTrace);
    }
    _initType();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _Item && collection.compareIdentity(other.collection));

  @override
  int get hashCode => collection.identityHashCode;

  @override
  bool get isSelectable => true;

  String get name => collection.name;

  String? get subtitle => _subtitle;

  String? get coverUrl => _coverUrl;

  _ItemType get itemType => _itemType;

  void _initType() {
    _ItemType? type;
    if (collection.contentProvider is CollectionNcAlbumProvider) {
      type = _ItemType.ncAlbum;
    } else if (collection.contentProvider is CollectionAlbumProvider) {
      final provider = collection.contentProvider as CollectionAlbumProvider;
      if (provider.album.provider is AlbumStaticProvider) {
        type = _ItemType.album;
      } else if (provider.album.provider is AlbumDirProvider) {
        type = _ItemType.dirAlbum;
      } else if (provider.album.provider is AlbumTagProvider) {
        type = _ItemType.tagAlbum;
      }
    }
    if (type == null) {
      throw UnsupportedError("Collection type not supported");
    }
    _itemType = type;
  }

  final Collection collection;
  String? _subtitle;
  String? _coverUrl;
  late _ItemType _itemType;
}
