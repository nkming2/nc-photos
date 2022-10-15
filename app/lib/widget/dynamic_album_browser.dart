import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/download_handler.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/flutter_util.dart' as flutter_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/object_extension.dart';
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
import 'package:nc_photos/widget/photo_list_item.dart';
import 'package:nc_photos/widget/photo_list_util.dart' as photo_list_util;
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
  _DynamicAlbumBrowserState() {
    final c = KiwiContainer().resolve<DiContainer>();
    assert(require(c));
    assert(PreProcessAlbum.require(c));
    _c = c;
  }

  static bool require(DiContainer c) => DiContainer.has(c, DiType.albumRepo);

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
  onItemTap(SelectableItem item, int index) {
    item.as<_ListItem>()?.onTap?.call();
  }

  @override
  @protected
  get canEdit => _album?.albumFile?.isOwned(widget.account.userId) == true;

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
        setState(() {
          _album = newAlbum;
        });
        UpdateAlbum(_c.albumRepo)(
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
    final List<AlbumItem> items;
    final Album album;
    try {
      items = await PreProcessAlbum(_c)(widget.account, widget.album);
      album = await _updateAlbumPostPopulate(widget.album, items);
    } catch (e, stackTrace) {
      _log.severe("[_initAlbum] Failed while PreProcessAlbum", e, stackTrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
      return;
    }
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
        child: Text(L10n.global().convertAlbumTooltip),
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
        title: Text(L10n.global().convertAlbumTooltip),
        content: Text(L10n.global().convertAlbumConfirmationDialogContent),
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
    try {
      await UpdateAlbum(_c.albumRepo)(
          widget.account,
          _album!.copyWith(
            provider: AlbumStaticProvider(
              latestItemTime: _album!.provider.latestItemTime,
              items: _sortedItems,
            ),
            coverProvider: AlbumAutoCoverProvider(),
          ));
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().convertAlbumSuccessNotification),
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
    final c = KiwiContainer().resolve<DiContainer>();
    DownloadHandler(c).downloadFiles(
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
    final c = KiwiContainer().resolve<DiContainer>();
    final selected = selectedListItems
        .whereType<_FileListItem>()
        .map((e) => e.file)
        .toList();
    ShareHandler(
      c,
      context: context,
      clearSelection: () {
        setState(() {
          clearSelectedItems();
        });
      },
    ).shareFiles(widget.account, selected);
  }

  Future<void> _onSelectionDeletePressed() async {
    SnackBarManager().showSnackBar(
      SnackBar(
        content: Text(L10n.global()
            .deleteSelectedProcessingNotification(selectedListItems.length)),
        duration: k.snackBarDurationShort,
      ),
      canBeReplaced: true,
    );

    final selected = selectedListItems.whereType<_FileListItem>().toList();
    setState(() {
      clearSelectedItems();
    });

    final successes = <_FileListItem>[];
    await Remove(KiwiContainer().resolve<DiContainer>())(
      widget.account,
      selected.map((e) => e.file).toList(),
      onRemoveFileFailed: (file, e, stackTrace) {
        _log.shout(
            "[_onSelectionDeletePressed] Failed while removing file: ${logFilename(file.path)}",
            e,
            stackTrace);
        successes.removeWhere((item) => item.file.compareServerIdentity(file));
      },
    );

    if (successes.length == selected.length) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().deleteSelectedSuccessNotification),
        duration: k.snackBarDurationNormal,
      ));
    } else {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().deleteSelectedFailureNotification(
            selected.length - successes.length)),
        duration: k.snackBarDurationNormal,
      ));
    }
    if (successes.isNotEmpty) {
      final indexes = successes.map((e) => e.index).sorted(Comparable.compare);
      setState(() {
        for (final i in indexes.reversed) {
          _sortedItems.removeAt(i);
        }
        _onSortedItemsUpdated();
      });
    }
  }

  void _onSelectionDownloadPressed() {
    final c = KiwiContainer().resolve<DiContainer>();
    final selected = selectedListItems
        .whereType<_FileListItem>()
        .map((e) => e.file)
        .toList();
    DownloadHandler(c).downloadFiles(widget.account, selected);
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
          FancyOptionPickerItem(
            label: L10n.global().sortOptionFilenameAscendingLabel,
            isSelected: sortProvider is AlbumFilenameSortProvider &&
                sortProvider.isAscending,
            onSelect: () {
              _onEditSortFilenamePressed();
              Navigator.of(context).pop();
            },
          ),
          FancyOptionPickerItem(
            label: L10n.global().sortOptionFilenameDescendingLabel,
            isSelected: sortProvider is AlbumFilenameSortProvider &&
                !sortProvider.isAscending,
            onSelect: () {
              _onEditSortFilenameDescendingPressed();
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

  void _onEditSortFilenamePressed() {
    _editAlbum = _editAlbum!.copyWith(
      sortProvider: const AlbumFilenameSortProvider(isAscending: true),
    );
    setState(() {
      _transformItems(_sortedItems);
    });
  }

  void _onEditSortFilenameDescendingPressed() {
    _editAlbum = _editAlbum!.copyWith(
      sortProvider: const AlbumFilenameSortProvider(isAscending: false),
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
    final dateHelper = photo_list_util.DateGroupHelper(
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
              Pref().isAlbumBrowserShowDateOr()) {
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
    return await UpdateAlbumWithActualItems(_c.albumRepo)(
        widget.account, album, items);
  }

  late final DiContainer _c;

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
    this.onTap,
  });

  @override
  get isTappable => onTap != null;

  @override
  get isSelectable => true;

  @override
  get staggeredTile => const StaggeredTile.count(1, 1);

  @override
  toString() => "$runtimeType {"
      "index: $index, "
      "}";

  final int index;

  final VoidCallback? onTap;
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
    required super.index,
    required super.file,
    required this.account,
    required this.previewUrl,
    super.onTap,
  });

  @override
  buildWidget(BuildContext context) => PhotoListImage(
        account: account,
        previewUrl: previewUrl,
        isGif: file.contentType == "image/gif",
        heroKey: flutter_util.getImageHeroTag(file),
      );

  final Account account;
  final String previewUrl;
}

class _VideoListItem extends _FileListItem {
  _VideoListItem({
    required super.index,
    required super.file,
    required this.account,
    required this.previewUrl,
    super.onTap,
  });

  @override
  buildWidget(BuildContext context) => PhotoListVideo(
        account: account,
        previewUrl: previewUrl,
      );

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
  buildWidget(BuildContext context) => PhotoListDate(
        date: date,
      );

  final DateTime date;
}
