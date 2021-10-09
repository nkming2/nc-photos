import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/download_handler.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/share_handler.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/preprocess_album.dart';
import 'package:nc_photos/use_case/remove.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:nc_photos/use_case/update_album_with_actual_items.dart';
import 'package:nc_photos/widget/album_browser_mixin.dart';
import 'package:nc_photos/widget/fancy_option_picker.dart';
import 'package:nc_photos/widget/photo_list_helper.dart';
import 'package:nc_photos/widget/photo_list_item.dart';
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/viewer.dart';

class DynamicAlbumBrowserArguments {
  DynamicAlbumBrowserArguments(this.account, this.album);

  final Account account;
  final Album album;
}

class DynamicAlbumBrowser extends StatefulWidget {
  static const routeName = "/dynamic-album-browser";

  static Route buildRoute(DynamicAlbumBrowserArguments args) =>
      MaterialPageRoute(
        builder: (context) => DynamicAlbumBrowser.fromArgs(args),
      );

  const DynamicAlbumBrowser({
    Key? key,
    required this.account,
    required this.album,
  }) : super(key: key);

  DynamicAlbumBrowser.fromArgs(DynamicAlbumBrowserArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
          album: args.album,
        );

  @override
  createState() => _DynamicAlbumBrowserState();

  final Account account;
  final Album album;
}

class _DynamicAlbumBrowserState extends State<DynamicAlbumBrowser>
    with
        SelectableItemStreamListMixin<DynamicAlbumBrowser>,
        AlbumBrowserMixin<DynamicAlbumBrowser> {
  @override
  initState() {
    super.initState();
    _initAlbum();

    _albumUpdatedListener =
        AppEventListener<AlbumUpdatedEvent>(_onAlbumUpdatedEvent);
    _albumUpdatedListener.begin();
  }

  @override
  dispose() {
    super.dispose();
    _albumUpdatedListener.end();
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

  @override
  @protected
  get canEdit => _album?.albumFile?.isOwned(widget.account.username) == true;

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
        UpdateAlbum(albumRepo)(
          widget.account,
          newAlbum,
        ).catchError((e, stackTrace) {
          _log.shout("[doneEditMode] Failed while UpdateAlbum", e, stackTrace);
          SnackBarManager().showSnackBar(SnackBar(
            content: Text(exception_util.toUserString(e)),
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

  Future<void> _initAlbum() async {
    assert(widget.album.provider is AlbumDynamicProvider);
    final items = await PreProcessAlbum()(widget.account, widget.album);
    final album = await _updateAlbumPostPopulate(widget.album, items);
    if (mounted) {
      setState(() {
        _album = album;
        _transformItems(items);
        initCover(widget.account, widget.album);
      });
    }
  }

  Widget _buildContent(BuildContext context) {
    if (_album == null) {
      return CustomScrollView(
        slivers: [
          buildNormalAppBar(context, widget.account, widget.album),
          const SliverToBoxAdapter(
            child: LinearProgressIndicator(),
          ),
        ],
      );
    }
    return buildItemStreamListOuter(
      context,
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                secondary: AppTheme.getOverscrollIndicatorColor(context),
              ),
        ),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverIgnorePointer(
              ignoring: isEditMode,
              sliver: SliverOpacity(
                opacity: isEditMode ? .25 : 1,
                sliver: buildItemStreamList(
                  maxCrossAxisExtent: thumbSize.toDouble(),
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
    final menuItems = <PopupMenuEntry<int>>[
      PopupMenuItem(
        value: _menuValueDownload,
        child: Text(L10n.global().downloadTooltip),
      ),
    ];
    if (canEdit) {
      menuItems.add(PopupMenuItem(
        value: _menuValueConvertBasic,
        child: Text(L10n.global().convertBasicAlbumMenuLabel),
      ));
    }

    return buildNormalAppBar(
      context,
      widget.account,
      _album!,
      menuItemBuilder: (_) => menuItems,
      onSelectedMenuItem: (option) {
        switch (option) {
          case _menuValueConvertBasic:
            _onConvertBasicPressed(context);
            break;
          case _menuValueDownload:
            _onDownloadPressed();
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
      IconButton(
        icon: const Icon(Icons.share),
        tooltip: L10n.global().shareTooltip,
        onPressed: () {
          _onSelectionSharePressed(context);
        },
      ),
      PopupMenuButton<_SelectionMenuOption>(
        tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _SelectionMenuOption.download,
            child: Text(L10n.global().downloadTooltip),
          ),
          PopupMenuItem(
            value: _SelectionMenuOption.delete,
            child: Text(L10n.global().deleteTooltip),
          ),
        ],
        onSelected: (option) => _onSelectionMenuSelected(context, option),
      ),
    ]);
  }

  Widget _buildEditAppBar(BuildContext context) {
    return buildEditAppBar(context, widget.account, widget.album, actions: [
      IconButton(
        icon: const Icon(Icons.sort_by_alpha),
        tooltip: L10n.global().sortTooltip,
        onPressed: _onEditSortPressed,
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
        arguments: ViewerArguments(widget.account, _backingFiles, fileIndex,
            album: widget.album));
  }

  Future<void> _onConvertBasicPressed(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.global().convertBasicAlbumConfirmationDialogTitle),
        content: Text(L10n.global().convertBasicAlbumConfirmationDialogContent),
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
    );
    if (result != true) {
      return;
    }
    _log.info(
        "[_onConvertBasicPressed] Converting album '${_album!.name}' to static");
    final albumRepo = AlbumRepo(AlbumCachedDataSource());
    try {
      await UpdateAlbum(albumRepo)(
          widget.account,
          _album!.copyWith(
            provider: AlbumStaticProvider(
              latestItemTime: _album!.provider.latestItemTime,
              items: _sortedItems,
            ),
            coverProvider: AlbumAutoCoverProvider(),
          ));
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().convertBasicAlbumSuccessNotification),
        duration: k.snackBarDurationNormal,
      ));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      _log.shout(
          "[_onConvertBasicPressed] Failed while converting to basic album",
          e,
          stackTrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  void _onDownloadPressed() {
    DownloadHandler().downloadFiles(
      widget.account,
      _sortedItems.whereType<AlbumFileItem>().map((e) => e.file).toList(),
      parentDir: _album!.name,
    );
  }

  void _onSelectionMenuSelected(
      BuildContext context, _SelectionMenuOption option) {
    switch (option) {
      case _SelectionMenuOption.delete:
        _onSelectionDeletePressed();
        break;
      case _SelectionMenuOption.download:
        _onSelectionDownloadPressed();
        break;
      default:
        _log.shout("[_onSelectionMenuSelected] Unknown option: $option");
        break;
    }
  }

  void _onSelectionSharePressed(BuildContext context) {
    final selected = selectedListItems
        .whereType<_FileListItem>()
        .map((e) => e.file)
        .toList();
    ShareHandler(
      context: context,
      clearSelection: () {
        setState(() {
          clearSelectedItems();
        });
      },
    ).shareFiles(widget.account, selected);
  }

  void _onSelectionDeletePressed() async {
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(L10n.global()
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
            "[_onSelectionDeletePressed] Failed while removing file" +
                (shouldLogFileName ? ": ${item.file.path}" : ""),
            e,
            stacktrace);
        failures.add(item);
      }
    }

    if (failures.isEmpty) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().deleteSelectedSuccessNotification),
        duration: k.snackBarDurationNormal,
      ));
    } else {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(
            L10n.global().deleteSelectedFailureNotification(failures.length)),
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

  void _onSelectionDownloadPressed() {
    final selected = selectedListItems
        .whereType<_FileListItem>()
        .map((e) => e.file)
        .toList();
    DownloadHandler().downloadFiles(widget.account, selected);
    setState(() {
      clearSelectedItems();
    });
  }

  void _onEditSortPressed() {
    final sortProvider = _editAlbum!.sortProvider;
    showDialog(
      context: context,
      builder: (context) => FancyOptionPicker(
        title: L10n.global().sortOptionDialogTitle,
        items: [
          FancyOptionPickerItem(
            label: L10n.global().sortOptionTimeDescendingLabel,
            isSelected: sortProvider is AlbumTimeSortProvider &&
                !sortProvider.isAscending,
            onSelect: () {
              _onEditSortNewestPressed();
              Navigator.of(context).pop();
            },
          ),
          FancyOptionPickerItem(
            label: L10n.global().sortOptionTimeAscendingLabel,
            isSelected: sortProvider is AlbumTimeSortProvider &&
                sortProvider.isAscending,
            onSelect: () {
              _onEditSortOldestPressed();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _onEditSortOldestPressed() {
    _editAlbum = _editAlbum!.copyWith(
      sortProvider: const AlbumTimeSortProvider(isAscending: true),
    );
    setState(() {
      _transformItems(_sortedItems);
    });
  }

  void _onEditSortNewestPressed() {
    _editAlbum = _editAlbum!.copyWith(
      sortProvider: const AlbumTimeSortProvider(isAscending: false),
    );
    setState(() {
      _transformItems(_sortedItems);
    });
  }

  Future<void> _onAlbumUpdatedEvent(AlbumUpdatedEvent ev) async {
    if (ev.album.albumFile!.path == _album?.albumFile?.path) {
      final album = await _updateAlbumPostPopulate(ev.album, _sortedItems);
      setState(() {
        _album = album;
        initCover(widget.account, album);
      });
    }
  }

  void _transformItems(List<AlbumItem> items) {
    _sortedItems = (_editAlbum ?? _album)!.sortProvider.sort(items);
    _onSortedItemsUpdated();
  }

  void _onSortedItemsUpdated() {
    _backingFiles = _sortedItems
        .whereType<AlbumFileItem>()
        .map((e) => e.file)
        .where((element) => file_util.isSupportedFormat(element))
        .toList();
    final dateHelper = PhotoListDateGroupHelper(
      isMonthOnly: false,
    );

    itemStreamListItems = () sync* {
      for (int i = 0; i < _sortedItems.length; ++i) {
        final item = _sortedItems[i];
        if (item is AlbumFileItem) {
          final previewUrl = api_util.getFilePreviewUrl(
            widget.account,
            item.file,
            width: k.photoThumbSize,
            height: k.photoThumbSize,
          );
          if ((_editAlbum ?? _album)?.sortProvider is AlbumTimeSortProvider &&
              Pref.inst().isAlbumBrowserShowDateOr()) {
            final date = dateHelper.onFile(item.file);
            if (date != null) {
              yield _DateListItem(date: date);
            }
          }

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

  Future<Album> _updateAlbumPostPopulate(
      Album album, List<AlbumItem> items) async {
    final albumRepo = AlbumRepo(AlbumCachedDataSource());
    return await UpdateAlbumWithActualItems(albumRepo)(
        widget.account, album, items);
  }

  Album? _album;
  var _sortedItems = <AlbumItem>[];
  var _backingFiles = <File>[];

  final _editFormKey = GlobalKey<FormState>();
  Album? _editAlbum;

  late AppEventListener<AlbumUpdatedEvent> _albumUpdatedListener;

  static final _log =
      Logger("widget.dynamic_album_browser._DynamicAlbumBrowserState");
  static const _menuValueConvertBasic = 0;
  static const _menuValueDownload = 1;
}

enum _SelectionMenuOption {
  delete,
  download,
}

abstract class _ListItem implements SelectableItem {
  const _ListItem({
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

class _DateListItem extends _ListItem {
  const _DateListItem({
    required this.date,
  }) : super(index: -1);

  @override
  get isSelectable => false;

  @override
  get staggeredTile => const StaggeredTile.extent(99, 32);

  @override
  buildWidget(BuildContext context) {
    return PhotoListDate(
      date: date,
    );
  }

  final DateTime date;
}
