import 'package:collection/collection.dart' show compareNatural;
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_init.dart' as app_init;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/widget/photo_list_item.dart';
import 'package:nc_photos/widget/photo_list_util.dart';
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';

class PhotoListItemBuilderArguments {
  const PhotoListItemBuilderArguments(
    this.account,
    this.files, {
    this.isArchived = false,
    required this.sorter,
    this.grouper,
    this.shouldBuildSmartAlbums = false,
    this.shouldShowFavoriteBadge = false,
    required this.locale,
  });

  final Account account;
  final List<File> files;
  final bool isArchived;
  final PhotoListItemSorter? sorter;
  final PhotoListItemGrouper? grouper;
  final bool shouldBuildSmartAlbums;
  final bool shouldShowFavoriteBadge;

  /// Locale is needed to get localized string
  final Locale locale;
}

class PhotoListItemBuilderResult {
  const PhotoListItemBuilderResult(
    this.backingFiles,
    this.listItems, {
    this.smartAlbums = const [],
  });

  final List<File> backingFiles;
  final List<SelectableItem> listItems;
  final List<Album> smartAlbums;
}

typedef PhotoListItemSorter = int Function(File, File);

abstract class PhotoListItemGrouper {
  const PhotoListItemGrouper();

  SelectableItem? onFile(File file);
}

class PhotoListFileDateGrouper implements PhotoListItemGrouper {
  PhotoListFileDateGrouper({
    required this.isMonthOnly,
  }) : helper = DateGroupHelper(isMonthOnly: isMonthOnly);

  @override
  onFile(File file) => helper
      .onFile(file)
      ?.run((date) => PhotoListDateItem(date: date, isMonthOnly: isMonthOnly));

  final bool isMonthOnly;
  final DateGroupHelper helper;
}

int photoListFileDateTimeSorter(File a, File b) =>
    compareFileDateTimeDescending(a, b);

int photoListFilenameSorter(File a, File b) =>
    compareNatural(b.filename, a.filename);

PhotoListItemBuilderResult buildPhotoListItem(
    PhotoListItemBuilderArguments arg) {
  app_init.initLog();
  return _PhotoListItemBuilder(
    isArchived: arg.isArchived,
    sorter: arg.sorter,
    grouper: arg.grouper,
    shouldBuildSmartAlbums: arg.shouldBuildSmartAlbums,
    shouldShowFavoriteBadge: arg.shouldShowFavoriteBadge,
    locale: arg.locale,
  )(arg.account, arg.files);
}

class _PhotoListItemBuilder {
  const _PhotoListItemBuilder({
    required this.isArchived,
    required this.sorter,
    required this.grouper,
    required this.shouldBuildSmartAlbums,
    required this.shouldShowFavoriteBadge,
    required this.locale,
  });

  PhotoListItemBuilderResult call(Account account, List<File> files) {
    final s = Stopwatch()..start();
    try {
      return _fromSortedItems(account, _sortItems(files));
    } finally {
      _log.info("[call] Elapsed time: ${s.elapsedMilliseconds}ms");
    }
  }

  List<File> _sortItems(List<File> files) {
    final filtered = files.where((f) => (f.isArchived ?? false) == isArchived);
    if (sorter == null) {
      return filtered.toList();
    } else {
      return filtered.stableSorted(sorter);
    }
  }

  PhotoListItemBuilderResult _fromSortedItems(
      Account account, List<File> files) {
    final today = DateTime.now();
    final memoryAlbumHelper =
        shouldBuildSmartAlbums ? MemoryAlbumHelper(today) : null;
    final listItems = <SelectableItem>[];
    for (int i = 0; i < files.length; ++i) {
      final f = files[i];
      final item = _buildListItem(i, account, f);
      if (item != null) {
        grouper?.onFile(f)?.run((item) => listItems.add(item));
        memoryAlbumHelper?.addFile(f);
        listItems.add(item);
      }
    }
    final smartAlbums = memoryAlbumHelper
        ?.build((year) => L10n.of(locale).memoryAlbumName(today.year - year));
    return PhotoListItemBuilderResult(
      files,
      listItems,
      smartAlbums: smartAlbums ?? [],
    );
  }

  SelectableItem? _buildListItem(int i, Account account, File file) {
    final previewUrl = api_util.getFilePreviewUrl(account, file,
        width: k.photoThumbSize, height: k.photoThumbSize);
    if (file_util.isSupportedImageFormat(file)) {
      return PhotoListImageItem(
        fileIndex: i,
        file: file,
        account: account,
        previewUrl: previewUrl,
        shouldShowFavoriteBadge: shouldShowFavoriteBadge,
      );
    } else if (file_util.isSupportedVideoFormat(file)) {
      return PhotoListVideoItem(
        fileIndex: i,
        file: file,
        account: account,
        previewUrl: previewUrl,
        shouldShowFavoriteBadge: shouldShowFavoriteBadge,
      );
    } else {
      _log.shout(
          "[_buildListItem] Unsupported file format: ${file.contentType}");
      return null;
    }
  }

  final bool isArchived;
  final PhotoListItemSorter? sorter;
  final PhotoListItemGrouper? grouper;
  final bool shouldBuildSmartAlbums;
  final bool shouldShowFavoriteBadge;
  final Locale locale;

  static final _log =
      Logger("widget.builder.photo_list_item_builder._PhotoListItemBuilder");
}
