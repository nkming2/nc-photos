part of '../home_photos2.dart';

abstract class _Item implements SelectableItemMetadata {
  const _Item();

  /// Unique id used to identify this item
  String get id;

  StaggeredTile get staggeredTile;

  Widget buildWidget(BuildContext context);
}

abstract class _FileItem extends _Item {
  const _FileItem({
    required this.file,
  });

  @override
  String get id => "file-${file.fdId}";

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
    required this.isMonthOnly,
  });

  @override
  String get id => "date-$date";

  @override
  bool get isSelectable => false;

  @override
  StaggeredTile get staggeredTile => const StaggeredTile.extent(99, 32);

  @override
  Widget buildWidget(BuildContext context) {
    return PhotoListDate(
      date: date,
      isMonthOnly: isMonthOnly,
    );
  }

  final Date date;
  final bool isMonthOnly;
}

enum _ItemSort { dateTime, filename }

class _ItemTransformerArgument {
  const _ItemTransformerArgument({
    required this.account,
    required this.files,
    this.summary,
    this.itemPerRow,
    this.itemSize,
    required this.sort,
    required this.isGroupByDay,
    required this.memoriesDayRange,
    required this.locale,
  });

  final Account account;
  final List<FileDescriptor> files;
  final DbFilesSummary? summary;
  final int? itemPerRow;
  final double? itemSize;
  final _ItemSort sort;
  final bool isGroupByDay;
  final int memoriesDayRange;
  final Locale locale;
}

class _ItemTransformerResult {
  const _ItemTransformerResult({
    required this.items,
    required this.memoryCollections,
    required this.dates,
  });

  final List<_Item> items;
  final List<Collection> memoryCollections;
  final Set<Date> dates;
}

class _MemoryCollectionItem {
  static const width = 96.0;
  static const height = width * 1.15;
}

@toString
class _VisibleDate implements Comparable<_VisibleDate> {
  const _VisibleDate(this.id, this.date);

  @override
  bool operator ==(Object? other) => other is _VisibleDate && id == other.id;

  @override
  int compareTo(_VisibleDate other) => id.compareTo(other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => _$toString();

  final String id;
  final Date date;
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

class _SummaryFileItem extends _Item {
  const _SummaryFileItem({
    required this.date,
    required this.index,
  });

  @override
  String get id => "summary-file-$date-$index";

  @override
  bool get isSelectable => false;

  @override
  StaggeredTile get staggeredTile => const StaggeredTile.count(1, 1);

  @override
  Widget buildWidget(BuildContext context) {
    return ShimmerLoading(
      isLoading: true,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Theme.of(context).listPlaceholderBackgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  final Date date;
  final int index;
}
