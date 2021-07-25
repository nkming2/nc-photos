import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/share_handler.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/populate_album.dart';
import 'package:nc_photos/use_case/remove.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:nc_photos/use_case/update_dynamic_album_cover.dart';
import 'package:nc_photos/use_case/update_dynamic_album_time.dart';
import 'package:nc_photos/widget/album_viewer_mixin.dart';
import 'package:nc_photos/widget/fancy_option_picker.dart';
import 'package:nc_photos/widget/photo_list_item.dart';
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/viewer.dart';

class DynamicAlbumViewerArguments {
  DynamicAlbumViewerArguments(this.account, this.album);

  final Account account;
  final Album album;
}

class DynamicAlbumViewer extends StatefulWidget {
  static const routeName = "/dynamic-album-viewer";

  static Route buildRoute(DynamicAlbumViewerArguments args) =>
      MaterialPageRoute(
        builder: (context) => DynamicAlbumViewer.fromArgs(args),
      );

  DynamicAlbumViewer({
    Key? key,
    required this.account,
    required this.album,
  }) : super(key: key);

  DynamicAlbumViewer.fromArgs(DynamicAlbumViewerArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
          album: args.album,
        );

  @override
  createState() => _DynamicAlbumViewerState();

  final Account account;
  final Album album;
}

class _DynamicAlbumViewerState extends State<DynamicAlbumViewer>
    with
        SelectableItemStreamListMixin<DynamicAlbumViewer>,
        AlbumViewerMixin<DynamicAlbumViewer> {
  @override
  initState() {
    super.initState();
    _initAlbum();
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: Builder(
          builder: (context) {
            if (isEditMode) {
              return Form(
                key: _editFormKey,
                child: _buildContent(context),
              );
            } else {
              return _buildContent(context);
            }
          },
        ),
      ),
    );
  }

  @protected
  get canEdit => _album != null;

  @override
  enterEditMode() {
    super.enterEditMode();
    _editAlbum = _album!.copyWith();
  }

  @override
  validateEditMode() => _editFormKey.currentState?.validate() == true;

  @override
  doneEditMode() {
    try {
      // persist the changes
      _editFormKey.currentState!.save();
      final newAlbum = makeEdited(_editAlbum!);
      if (newAlbum.copyWith(lastUpdated: OrNull(_album!.lastUpdated)) !=
          _album) {
        _log.info("[doneEditMode] Album modified: $newAlbum");
        final albumRepo = AlbumRepo(AlbumCachedDataSource());
        setState(() {
          _album = newAlbum;
        });
        UpdateAlbum(albumRepo)(widget.account, newAlbum)
            .catchError((e, stacktrace) {
          SnackBarManager().showSnackBar(SnackBar(
            content: Text(exception_util.toUserString(e, context)),
            duration: k.snackBarDurationNormal,
          ));
        });
      } else {
        _log.fine("[doneEditMode] Album not modified");
      }
    } finally {
      setState(() {
        // reset edits
        _editAlbum = null;
        // update the list to show the real album
        _transformItems(_sortedItems);
      });
    }
  }

  void _initAlbum() {
    assert(widget.album.provider is AlbumDynamicProvider);
    PopulateAlbum()(widget.account, widget.album).then((items) {
      if (mounted) {
        setState(() {
          _album = widget.album;
          _transformItems(items);
          initCover(widget.account, _backingFiles);
          _updateAlbumPostPopulate(items);
        });
      }
    });
  }

  void _updateAlbumPostPopulate(List<AlbumItem> items) {
    List<File> timeDescSortedFiles;
    if (widget.album.sortProvider is AlbumTimeSortProvider) {
      if ((widget.album.sortProvider as AlbumTimeSortProvider).isAscending) {
        timeDescSortedFiles = _backingFiles.reversed.toList();
      } else {
        timeDescSortedFiles = _backingFiles;
      }
    } else {
      timeDescSortedFiles = AlbumTimeSortProvider(isAscending: false)
          .sort(items)
          .whereType<AlbumFileItem>()
          .map((e) => e.file)
          .where((element) => file_util.isSupportedFormat(element))
          .toList();
    }

    bool shouldUpdate = false;
    final albumUpdatedCover = UpdateDynamicAlbumCover()
        .updateWithSortedFiles(_album!, timeDescSortedFiles);
    if (!identical(albumUpdatedCover, _album)) {
      _log.info("[_updateAlbumPostPopulate] Update album cover");
      shouldUpdate = true;
    }
    _album = albumUpdatedCover;

    final albumUpdatedTime = UpdateDynamicAlbumTime()
        .updateWithSortedFiles(_album!, timeDescSortedFiles);
    if (!identical(albumUpdatedTime, _album)) {
      _log.info(
          "[_updateAlbumPostPopulate] Update album time: ${albumUpdatedTime.provider.latestItemTime}");
      shouldUpdate = true;
    }
    _album = albumUpdatedTime;

    if (shouldUpdate) {
      UpdateAlbum(AlbumRepo(AlbumCachedDataSource()))(widget.account, _album!);
    }
  }

  Widget _buildContent(BuildContext context) {
    if (_album == null) {
      return CustomScrollView(
        slivers: [
          buildNormalAppBar(context, widget.account, widget.album),
          const SliverToBoxAdapter(
            child: const LinearProgressIndicator(),
          ),
        ],
      );
    }
    return buildItemStreamListOuter(
      context,
      child: Theme(
        data: Theme.of(context).copyWith(
          accentColor: AppTheme.getOverscrollIndicatorColor(context),
        ),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.only(top: 8),
              sliver: SliverIgnorePointer(
                ignoring: isEditMode,
                sliver: SliverOpacity(
                  opacity: isEditMode ? .25 : 1,
                  sliver: buildItemStreamList(
                    maxCrossAxisExtent: thumbSize.toDouble(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    if (isEditMode) {
      return _buildEditAppBar(context);
    } else if (isSelectionMode) {
      return _buildSelectionAppBar(context);
    } else {
      return _buildNormalAppBar(context);
    }
  }

  Widget _buildNormalAppBar(BuildContext context) {
    return buildNormalAppBar(
      context,
      widget.account,
      _album!,
      menuItemBuilder: (context) => [
        PopupMenuItem(
          value: _menuValueConvertBasic,
          child: Text(L10n.of(context).convertBasicAlbumMenuLabel),
        ),
      ],
      onSelectedMenuItem: (option) {
        switch (option) {
          case _menuValueConvertBasic:
            _onAppBarConvertBasicPressed(context);
            break;

          default:
            _log.shout("[_buildNormalAppBar] Unknown value: $option");
            break;
        }
      },
    );
  }

  Widget _buildSelectionAppBar(BuildContext context) {
    return buildSelectionAppBar(context, [
      if (platform_k.isAndroid)
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: L10n.of(context).shareSelectedTooltip,
          onPressed: () {
            _onSelectionAppBarSharePressed(context);
          },
        ),
      PopupMenuButton(
        tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _SelectionAppBarOption.delete,
            child: Text(L10n.of(context).deleteSelectedTooltip),
          ),
        ],
        onSelected: (option) {
          if (option == _SelectionAppBarOption.delete) {
            _onSelectionAppBarDeletePressed();
          }
        },
      ),
    ]);
  }

  Widget _buildEditAppBar(BuildContext context) {
    return buildEditAppBar(context, widget.account, widget.album, actions: [
      IconButton(
        icon: Icon(Icons.sort_by_alpha),
        tooltip: L10n.of(context).sortTooltip,
        onPressed: _onEditAppBarSortPressed,
      ),
    ]);
  }

  void _onItemTap(int index) {
    // convert item index to file index
    var fileIndex = index;
    for (int i = 0; i < index; ++i) {
      if (_sortedItems[i] is! AlbumFileItem ||
          !file_util
              .isSupportedFormat((_sortedItems[i] as AlbumFileItem).file)) {
        --fileIndex;
      }
    }
    Navigator.pushNamed(context, Viewer.routeName,
        arguments: ViewerArguments(widget.account, _backingFiles, fileIndex));
  }

  void _onAppBarConvertBasicPressed(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).convertBasicAlbumConfirmationDialogTitle),
        content:
            Text(L10n.of(context).convertBasicAlbumConfirmationDialogContent),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    ).then((value) {
      if (value != true) {
        return;
      }
      _log.info(
          "[_onAppBarConvertBasicPressed] Converting album '${_album!.name}' to static");
      final albumRepo = AlbumRepo(AlbumCachedDataSource());
      UpdateAlbum(albumRepo)(
        widget.account,
        _album!.copyWith(
          provider: AlbumStaticProvider(items: _sortedItems),
          coverProvider: AlbumAutoCoverProvider(),
        ),
      ).then((value) {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(L10n.of(context).convertBasicAlbumSuccessNotification),
          duration: k.snackBarDurationNormal,
        ));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }).catchError((e, stacktrace) {
        _log.shout(
            "[_onAppBarConvertBasicPressed] Failed while converting to basic album",
            e,
            stacktrace);
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(exception_util.toUserString(e, context)),
          duration: k.snackBarDurationNormal,
        ));
      });
    });
  }

  void _onSelectionAppBarSharePressed(BuildContext context) {
    assert(platform_k.isAndroid);
    final selected = selectedListItems
        .whereType<_FileListItem>()
        .map((e) => e.file)
        .toList();
    ShareHandler().shareFiles(context, widget.account, selected).then((_) {
      setState(() {
        clearSelectedItems();
      });
    });
  }

  void _onSelectionAppBarDeletePressed() async {
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(L10n.of(context)
          .deleteSelectedProcessingNotification(selectedListItems.length)),
      duration: k.snackBarDurationShort,
    ));

    final selected = selectedListItems.whereType<_FileListItem>().toList();
    setState(() {
      clearSelectedItems();
    });

    final fileRepo = FileRepo(FileCachedDataSource());
    final albumRepo = AlbumRepo(AlbumCachedDataSource());
    final successes = <_FileListItem>[];
    final failures = <_FileListItem>[];
    for (final item in selected) {
      try {
        await Remove(fileRepo, albumRepo).call(widget.account, item.file);
        successes.add(item);
      } catch (e, stacktrace) {
        _log.shout(
            "[_onSelectionAppBarDeletePressed] Failed while removing file" +
                (kDebugMode ? ": ${item.file.path}" : ""),
            e,
            stacktrace);
        failures.add(item);
      }
    }

    if (failures.isEmpty) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.of(context).deleteSelectedSuccessNotification),
        duration: k.snackBarDurationNormal,
      ));
    } else {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.of(context)
            .deleteSelectedFailureNotification(failures.length)),
        duration: k.snackBarDurationNormal,
      ));
    }
    if (successes.isNotEmpty) {
      final indexes = successes.map((e) => e.index).sorted();
      setState(() {
        for (final i in indexes.reversed) {
          _sortedItems.removeAt(i);
        }
        _onSortedItemsUpdated();
      });
    }
  }

  void _onEditAppBarSortPressed() {
    final sortProvider = _editAlbum!.sortProvider;
    showDialog(
      context: context,
      builder: (context) => FancyOptionPicker(
        title: L10n.of(context).sortOptionDialogTitle,
        items: [
          FancyOptionPickerItem(
            label: L10n.of(context).sortOptionTimeAscendingLabel,
            isSelected: sortProvider is AlbumTimeSortProvider &&
                sortProvider.isAscending,
            onSelect: () {
              _onSortOldestPressed();
              Navigator.of(context).pop();
            },
          ),
          FancyOptionPickerItem(
            label: L10n.of(context).sortOptionTimeDescendingLabel,
            isSelected: sortProvider is AlbumTimeSortProvider &&
                !sortProvider.isAscending,
            onSelect: () {
              _onSortNewestPressed();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _onSortOldestPressed() {
    _editAlbum = _editAlbum!.copyWith(
      sortProvider: AlbumTimeSortProvider(isAscending: true),
    );
    setState(() {
      _transformItems(_sortedItems);
    });
  }

  void _onSortNewestPressed() {
    _editAlbum = _editAlbum!.copyWith(
      sortProvider: AlbumTimeSortProvider(isAscending: false),
    );
    setState(() {
      _transformItems(_sortedItems);
    });
  }

  void _transformItems(List<AlbumItem> items) {
    if (_editAlbum != null) {
      // edit mode
      _sortedItems = _editAlbum!.sortProvider.sort(items);
    } else {
      _sortedItems = _album!.sortProvider.sort(items);
    }
    _onSortedItemsUpdated();
  }

  void _onSortedItemsUpdated() {
    _backingFiles = _sortedItems
        .whereType<AlbumFileItem>()
        .map((e) => e.file)
        .where((element) => file_util.isSupportedFormat(element))
        .toList();
    itemStreamListItems = () sync* {
      for (int i = 0; i < _sortedItems.length; ++i) {
        final item = _sortedItems[i];
        if (item is AlbumFileItem) {
          final previewUrl = api_util.getFilePreviewUrl(
            widget.account,
            item.file,
            width: thumbSize,
            height: thumbSize,
          );
          if (file_util.isSupportedImageFormat(item.file)) {
            yield _ImageListItem(
              index: i,
              file: item.file,
              account: widget.account,
              previewUrl: previewUrl,
              onTap: () => _onItemTap(i),
            );
          } else if (file_util.isSupportedVideoFormat(item.file)) {
            yield _VideoListItem(
              index: i,
              file: item.file,
              account: widget.account,
              previewUrl: previewUrl,
              onTap: () => _onItemTap(i),
            );
          }
        }
      }
    }()
        .toList();
  }

  Album? _album;
  var _sortedItems = <AlbumItem>[];
  var _backingFiles = <File>[];

  final _editFormKey = GlobalKey<FormState>();
  Album? _editAlbum;

  static final _log =
      Logger("widget.dynamic_album_viewer._DynamicAlbumViewerState");
  static const _menuValueConvertBasic = 0;
}

abstract class _ListItem implements SelectableItem {
  _ListItem({
    required this.index,
    VoidCallback? onTap,
  }) : _onTap = onTap;

  @override
  get onTap => _onTap;

  @override
  get isSelectable => true;

  @override
  get staggeredTile => const StaggeredTile.count(1, 1);

  @override
  toString() {
    return "$runtimeType {"
        "index: $index, "
        "}";
  }

  final int index;

  final VoidCallback? _onTap;
}

abstract class _FileListItem extends _ListItem {
  _FileListItem({
    required int index,
    required this.file,
    VoidCallback? onTap,
  }) : super(
          index: index,
          onTap: onTap,
        );

  final File file;
}

class _ImageListItem extends _FileListItem {
  _ImageListItem({
    required int index,
    required File file,
    required this.account,
    required this.previewUrl,
    VoidCallback? onTap,
  }) : super(
          index: index,
          file: file,
          onTap: onTap,
        );

  @override
  buildWidget(BuildContext context) {
    return PhotoListImage(
      account: account,
      previewUrl: previewUrl,
      isGif: file.contentType == "image/gif",
    );
  }

  final Account account;
  final String previewUrl;
}

class _VideoListItem extends _FileListItem {
  _VideoListItem({
    required int index,
    required File file,
    required this.account,
    required this.previewUrl,
    VoidCallback? onTap,
  }) : super(
          index: index,
          file: file,
          onTap: onTap,
        );

  @override
  buildWidget(BuildContext context) {
    return PhotoListVideo(
      account: account,
      previewUrl: previewUrl,
    );
  }

  final Account account;
  final String previewUrl;
}

enum _SelectionAppBarOption {
  delete,
}
