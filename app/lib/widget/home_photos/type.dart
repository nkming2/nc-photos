part of '../home_photos2.dart';

abstract class _Item implements SelectableItemMetadata {
  const _Item();

  StaggeredTile get staggeredTile;

  Widget buildWidget(BuildContext context);
}

abstract class _FileItem extends _Item {
  const _FileItem({
    required this.file,
  });

  @override
  bool get isSelectable => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _FileItem && file.compareServerIdentity(other.file));

  @override
  int get hashCode => file.identityHashCode;

  final FileDescriptor file;
}

class _PhotoItem extends _FileItem {
  _PhotoItem({
    required super.file,
    required this.account,
  }) : _previewUrl = NetworkRectThumbnail.imageUrlForFile(account, file);

  @override
  StaggeredTile get staggeredTile => const StaggeredTile.count(1, 1);

  @override
  Widget buildWidget(BuildContext context) {
    return PhotoListImage(
      account: account,
      previewUrl: _previewUrl,
      isGif: file.fdMime == "image/gif",
      isFavorite: file.fdIsFavorite,
      heroKey: flutter_util.getImageHeroTag(file),
    );
  }

  final Account account;
  final String _previewUrl;
}

class _VideoItem extends _FileItem {
  _VideoItem({
    required super.file,
    required this.account,
  }) : _previewUrl = NetworkRectThumbnail.imageUrlForFile(account, file);

  @override
  StaggeredTile get staggeredTile => const StaggeredTile.count(1, 1);

  @override
  Widget buildWidget(BuildContext context) {
    return PhotoListVideo(
      account: account,
      previewUrl: _previewUrl,
      isFavorite: file.fdIsFavorite,
    );
  }

  final Account account;
  final String _previewUrl;
}

class _DateItem extends _Item {
  const _DateItem({
    required this.date,
  });

  @override
  bool get isSelectable => false;

  @override
  StaggeredTile get staggeredTile => const StaggeredTile.extent(99, 32);

  @override
  Widget buildWidget(BuildContext context) {
    return PhotoListDate(
      date: date,
    );
  }

  final DateTime date;
}

enum _ItemSort { dateTime, filename }

class _ItemTransformerArgument {
  const _ItemTransformerArgument({
    required this.account,
    required this.files,
    required this.sort,
    required this.memoriesDayRange,
    required this.locale,
  });

  final Account account;
  final List<FileDescriptor> files;
  final _ItemSort sort;
  final int memoriesDayRange;
  final Locale locale;
}

class _ItemTransformerResult {
  const _ItemTransformerResult({
    required this.items,
    required this.memoryCollections,
  });

  final List<_Item> items;
  final List<Collection> memoryCollections;
}

class _MemoryCollectionItem {
  static const width = 96.0;
  static const height = width * 1.15;
}

class _VisibleItem implements Comparable<_VisibleItem> {
  const _VisibleItem(this.index, this.item);

  @override
  bool operator ==(Object? other) =>
      other is _VisibleItem && index == other.index;

  @override
  int compareTo(_VisibleItem other) => index.compareTo(other.index);

  @override
  int get hashCode => index.hashCode;

  final int index;
  final _Item item;
}

enum _SelectionMenuOption {
  archive,
  delete,
  download,
}

@toString
class _ArchiveFailedError implements Exception {
  const _ArchiveFailedError(this.count);

  @override
  String toString() => _$toString();

  final int count;
}

@toString
class _RemoveFailedError implements Exception {
  const _RemoveFailedError(this.count);

  @override
  String toString() => _$toString();

  final int count;
}
