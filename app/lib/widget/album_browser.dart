import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/download_handler.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/list_extension.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/session_storage.dart';
import 'package:nc_photos/share_handler.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/ls_single_file.dart';
import 'package:nc_photos/use_case/preprocess_album.dart';
import 'package:nc_photos/use_case/remove_from_album.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:nc_photos/use_case/update_album_with_actual_items.dart';
import 'package:nc_photos/widget/album_browser_mixin.dart';
import 'package:nc_photos/widget/album_share_outlier_browser.dart';
import 'package:nc_photos/widget/draggable_item_list_mixin.dart';
import 'package:nc_photos/widget/fancy_option_picker.dart';
import 'package:nc_photos/widget/handler/add_selection_to_album_handler.dart';
import 'package:nc_photos/widget/photo_list_item.dart';
import 'package:nc_photos/widget/photo_list_util.dart' as photo_list_util;
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/share_album_dialog.dart';
import 'package:nc_photos/widget/shared_album_info_dialog.dart';
import 'package:nc_photos/widget/simple_input_dialog.dart';
import 'package:nc_photos/widget/viewer.dart';

class AlbumBrowserArguments {
  AlbumBrowserArguments(this.account, this.album);

  final Account account;
  final Album album;
}

class AlbumBrowser extends StatefulWidget {
  static const routeName = "/album-browser";

  static Route buildRoute(AlbumBrowserArguments args) => MaterialPageRoute(
        builder: (context) => AlbumBrowser.fromArgs(args),
      );

  const AlbumBrowser({
    Key? key,
    required this.account,
    required this.album,
  }) : super(key: key);

  AlbumBrowser.fromArgs(AlbumBrowserArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
          album: args.album,
        );

  @override
  createState() => _AlbumBrowserState();

  final Account account;
  final Album album;
}

class _AlbumBrowserState extends State<AlbumBrowser>
    with
        SelectableItemStreamListMixin<AlbumBrowser>,
        DraggableItemListMixin<AlbumBrowser>,
        AlbumBrowserMixin<AlbumBrowser> {
  _AlbumBrowserState() {
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
    setState(() {
      _transformItems();
    });

    if (!SessionStorage().hasShowDragRearrangeNotification) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().albumEditDragRearrangeNotification),
        duration: k.snackBarDurationNormal,
      ));
      SessionStorage().hasShowDragRearrangeNotification = true;
    }
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
        _transformItems();
      });
    }
  }

  Future<void> _initAlbum() async {
    var album = await _c.albumRepo.get(widget.account, widget.album.albumFile!);
    if (widget.album.shares?.isNotEmpty == true) {
      try {
        final file =
            await LsSingleFile(_c)(widget.account, album.albumFile!.path);
        if (file.etag != album.albumFile!.etag) {
          _log.info("[_initAlbum] Album modified in remote, forcing download");
          album = await _c.albumRepo.get(widget.account, File(path: file.path));
        }
      } catch (e, stackTrace) {
        _log.warning("[_initAlbum] Failed while syncing remote album file", e,
            stackTrace);
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(exception_util.toUserString(e)),
          duration: k.snackBarDurationNormal,
        ));
      }
    }
    await _setAlbum(album);

    if (album.shares?.isNotEmpty == true) {
      unawaited(_showSharedAlbumInfoDialog());
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

    Widget content = CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildAppBar(context),
        isEditMode
            ? buildDraggableItemList(
                maxCrossAxisExtent: thumbSize.toDouble(),
                onMaxExtentChanged: (value) {
                  _itemListMaxExtent = value;
                },
              )
            : buildItemStreamList(
                maxCrossAxisExtent: thumbSize.toDouble(),
              ),
      ],
    );
    if (isEditMode) {
      content = Listener(
        onPointerMove: _onEditPointerMove,
        child: content,
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
        child: content,
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    if (isEditMode) {
      return _buildEditAppBar(context);
    } else if (isSelectionMode) {
      return _buildSelectionAppBar(context);
    } else {
      return buildNormalAppBar(
        context,
        widget.account,
        _album!,
        actions: [
          if (_album!.albumFile!.isOwned(widget.account.userId) &&
              Pref().isLabEnableSharedAlbumOr(false))
            IconButton(
              onPressed: () => _onSharePressed(context),
              icon: const Icon(Icons.share),
              tooltip: L10n.global().shareTooltip,
            ),
        ],
        menuItemBuilder: (_) => [
          if (Pref().isLabEnableSharedAlbumOr(false))
            PopupMenuItem(
              value: _menuValueFixShares,
              child: Text(L10n.global().fixSharesTooltip),
            ),
          PopupMenuItem(
            value: _menuValueDownload,
            child: Text(L10n.global().downloadTooltip),
          ),
        ],
        onSelectedMenuItem: (option) => _onMenuSelected(context, option),
      );
    }
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
      IconButton(
        icon: const Icon(Icons.add),
        tooltip: L10n.global().addToAlbumTooltip,
        onPressed: () => _onSelectionAddPressed(context),
      ),
      PopupMenuButton<_SelectionMenuOption>(
        tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
        itemBuilder: (context) => [
          if (_canRemoveSelection)
            PopupMenuItem(
              value: _SelectionMenuOption.removeFromAlbum,
              child: Text(L10n.global().removeFromAlbumTooltip),
            ),
          PopupMenuItem(
            value: _SelectionMenuOption.download,
            child: Text(L10n.global().downloadTooltip),
          ),
        ],
        onSelected: (option) => _onSelectionMenuSelected(context, option),
      ),
    ]);
  }

  Widget _buildEditAppBar(BuildContext context) {
    return buildEditAppBar(context, widget.account, _album!, actions: [
      IconButton(
        icon: const Icon(Icons.text_fields),
        tooltip: L10n.global().albumAddTextTooltip,
        onPressed: _onEditAddTextPressed,
      ),
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
            album: _album));
  }

  Future<void> _onSharePressed(BuildContext context) async {
    await _showSharedAlbumInfoDialog();
    await showDialog(
      context: context,
      builder: (_) => ShareAlbumDialog(
        account: widget.account,
        album: _album!,
      ),
    );
  }

  void _onMenuSelected(BuildContext context, int option) {
    switch (option) {
      case _menuValueDownload:
        _onDownloadPressed();
        break;
      case _menuValueFixShares:
        _onFixSharesPressed();
        break;
      default:
        _log.shout("[_onMenuSelected] Unknown option: $option");
        break;
    }
  }

  void _onDownloadPressed() {
    DownloadHandler().downloadFiles(
      widget.account,
      _sortedItems.whereType<AlbumFileItem>().map((e) => e.file).toList(),
      parentDir: _album!.name,
    );
  }

  void _onFixSharesPressed() {
    Navigator.of(context).pushNamed(
      AlbumShareOutlierBrowser.routeName,
      arguments: AlbumShareOutlierBrowserArguments(widget.account, _album!),
    );
  }

  void _onSelectionMenuSelected(
      BuildContext context, _SelectionMenuOption option) {
    switch (option) {
      case _SelectionMenuOption.download:
        _onSelectionDownloadPressed();
        break;
      case _SelectionMenuOption.removeFromAlbum:
        _onSelectionRemovePressed();
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
    if (selected.isEmpty) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().shareSelectedEmptyNotification),
        duration: k.snackBarDurationNormal,
      ));
      return;
    }
    ShareHandler(
      context: context,
      clearSelection: () {
        setState(() {
          clearSelectedItems();
        });
      },
    ).shareFiles(widget.account, selected);
  }

  Future<void> _onSelectionAddPressed(BuildContext context) async {
    return AddSelectionToAlbumHandler()(
      context: context,
      account: widget.account,
      selectedFiles: selectedListItems
          .whereType<_FileListItem>()
          .map((e) => e.file)
          .toList(),
      clearSelection: () {
        if (mounted) {
          setState(() {
            clearSelectedItems();
          });
        }
      },
    );
  }

  Future<void> _onSelectionRemovePressed() async {
    final selectedIndexes =
        selectedListItems.whereType<_ListItem>().map((e) => e.index).toList();
    final selectedItems = _sortedItems
        .takeIndex(selectedIndexes)
        // can only remove owned files
        .where((element) =>
            _album!.albumFile!.isOwned(widget.account.userId) == true ||
            element.addedBy == widget.account.userId)
        .toList();
    setState(() {
      clearSelectedItems();
    });

    try {
      await RemoveFromAlbum(KiwiContainer().resolve<DiContainer>())(
          widget.account, _album!, selectedItems);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global()
            .removeSelectedFromAlbumSuccessNotification(selectedItems.length)),
        duration: k.snackBarDurationNormal,
      ));
    } catch (e, stackTrace) {
      _log.shout("[_onSelectionRemovePressed] Failed while updating album", e,
          stackTrace);
      SnackBarManager().showSnackBar(SnackBar(
        content:
            Text("${L10n.global().removeSelectedFromAlbumFailureNotification}: "
                "${exception_util.toUserString(e)}"),
        duration: k.snackBarDurationNormal,
      ));
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

  void _onEditPointerMove(PointerMoveEvent event) {
    assert(isEditMode);
    if (!_isDragging) {
      return;
    }
    if (event.position.dy >= MediaQuery.of(context).size.height - 100) {
      // near bottom of screen
      if (_isDragScrollingDown == true) {
        return;
      }
      final maxExtent =
          _itemListMaxExtent ?? _scrollController.position.maxScrollExtent;
      _log.fine("[_onEditPointerMove] Begin scrolling down");
      if (_scrollController.offset <
          _scrollController.position.maxScrollExtent) {
        _scrollController.animateTo(maxExtent,
            duration: Duration(
                milliseconds:
                    ((maxExtent - _scrollController.offset) * 1.6).round()),
            curve: Curves.linear);
        _isDragScrollingDown = true;
      }
    } else if (event.position.dy <= 100) {
      // near top of screen
      if (_isDragScrollingDown == false) {
        return;
      }
      _log.fine("[_onEditPointerMove] Begin scrolling up");
      if (_scrollController.offset > 0) {
        _scrollController.animateTo(0,
            duration: Duration(
                milliseconds: (_scrollController.offset * 1.6).round()),
            curve: Curves.linear);
        _isDragScrollingDown = false;
      }
    } else if (_isDragScrollingDown != null) {
      _log.fine("[_onEditPointerMove] Stop scrolling");
      _scrollController.jumpTo(_scrollController.offset);
      _isDragScrollingDown = null;
    }
  }

  void _onEditItemMoved(int fromIndex, int toIndex, bool isBefore) {
    if (fromIndex == toIndex) {
      return;
    }
    final item = _sortedItems.removeAt(fromIndex);
    final newIndex =
        toIndex + (isBefore ? 0 : 1) + (fromIndex < toIndex ? -1 : 0);
    _sortedItems.insert(newIndex, item);
    _editAlbum = _editAlbum!.copyWith(
      sortProvider: const AlbumNullSortProvider(),
      // save the current order
      provider: AlbumStaticProvider.of(_editAlbum!).copyWith(
        items: _sortedItems,
      ),
    );
    setState(() {
      _transformItems();
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
          if (sortProvider is AlbumNullSortProvider)
            FancyOptionPickerItem(
              label: L10n.global().sortOptionManualLabel,
              isSelected: true,
              onSelect: () {
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
      _transformItems();
    });
  }

  void _onEditSortNewestPressed() {
    _editAlbum = _editAlbum!.copyWith(
      sortProvider: const AlbumTimeSortProvider(isAscending: false),
    );
    setState(() {
      _transformItems();
    });
  }

  void _onEditSortFilenamePressed() {
    _editAlbum = _editAlbum!.copyWith(
      sortProvider: const AlbumFilenameSortProvider(isAscending: true),
    );
    setState(() {
      _transformItems();
    });
  }

  void _onEditSortFilenameDescendingPressed() {
    _editAlbum = _editAlbum!.copyWith(
      sortProvider: const AlbumFilenameSortProvider(isAscending: false),
    );
    setState(() {
      _transformItems();
    });
  }

  void _onEditAddTextPressed() {
    showDialog<String>(
      context: context,
      builder: (context) => SimpleInputDialog(
        buttonText: MaterialLocalizations.of(context).saveButtonLabel,
      ),
    ).then((value) {
      if (value == null) {
        return;
      }
      _editAlbum = _editAlbum!.copyWith(
        provider: AlbumStaticProvider.of(_editAlbum!).copyWith(
          items: [
            AlbumLabelItem(
              addedBy: widget.account.userId,
              addedAt: DateTime.now(),
              text: value,
            ),
            ..._sortedItems,
          ],
        ),
      );
      setState(() {
        _transformItems();
      });
    });
  }

  void _onEditLabelItemEditPressed(AlbumLabelItem item, int index) {
    showDialog<String>(
      context: context,
      builder: (context) => SimpleInputDialog(
        buttonText: MaterialLocalizations.of(context).saveButtonLabel,
        initialText: item.text,
      ),
    ).then((value) {
      if (value == null) {
        return;
      }
      _sortedItems[index] = item.copyWith(
        text: value,
      );
      _editAlbum = _editAlbum!.copyWith(
        provider: AlbumStaticProvider.of(_editAlbum!).copyWith(
          items: _sortedItems,
        ),
      );
      setState(() {
        _transformItems();
      });
    });
  }

  Future<void> _onAlbumUpdatedEvent(AlbumUpdatedEvent ev) async {
    if (ev.album.albumFile!.path == _album?.albumFile?.path) {
      await _setAlbum(ev.album);
    }
  }

  void _transformItems() {
    if (_editAlbum != null) {
      // edit mode
      _sortedItems =
          _editAlbum!.sortProvider.sort(_getAlbumItemsOf(_editAlbum!));
    } else {
      _sortedItems = _album!.sortProvider.sort(_getAlbumItemsOf(_album!));
    }
    _backingFiles = _sortedItems
        .whereType<AlbumFileItem>()
        .map((e) => e.file)
        .where((element) => file_util.isSupportedFormat(element))
        .toList();
    final dateHelper = photo_list_util.DateGroupHelper(
      isMonthOnly: false,
    );

    final items = () sync* {
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
              onDropBefore: (dropItem) =>
                  _onEditItemMoved((dropItem as _ListItem).index, i, true),
              onDropAfter: (dropItem) =>
                  _onEditItemMoved((dropItem as _ListItem).index, i, false),
              onDragStarted: () {
                _isDragging = true;
              },
              onDragEndedAny: () {
                _isDragging = false;
              },
            );
          } else if (file_util.isSupportedVideoFormat(item.file)) {
            yield _VideoListItem(
              index: i,
              file: item.file,
              account: widget.account,
              previewUrl: previewUrl,
              onTap: () => _onItemTap(i),
              onDropBefore: (dropItem) =>
                  _onEditItemMoved((dropItem as _ListItem).index, i, true),
              onDropAfter: (dropItem) =>
                  _onEditItemMoved((dropItem as _ListItem).index, i, false),
              onDragStarted: () {
                _isDragging = true;
              },
              onDragEndedAny: () {
                _isDragging = false;
              },
            );
          } else {
            _log.shout(
                "[_transformItems] Unsupported file format: ${item.file.contentType}");
          }
        } else if (item is AlbumLabelItem) {
          if (isEditMode) {
            yield _EditLabelListItem(
              index: i,
              text: item.text,
              onEditPressed: () => _onEditLabelItemEditPressed(item, i),
              onDropBefore: (dropItem) =>
                  _onEditItemMoved((dropItem as _ListItem).index, i, true),
              onDropAfter: (dropItem) =>
                  _onEditItemMoved((dropItem as _ListItem).index, i, false),
              onDragStarted: () {
                _isDragging = true;
              },
              onDragEndedAny: () {
                _isDragging = false;
              },
            );
          } else {
            yield _LabelListItem(
              index: i,
              text: item.text,
            );
          }
        }
      }
    }()
        .toList();
    itemStreamListItems = items;
    draggableItemList = items;
  }

  Future<void> _setAlbum(Album album) async {
    assert(album.provider is AlbumStaticProvider);
    final items = await PreProcessAlbum(_c)(widget.account, album);
    if (album.albumFile!.isOwned(widget.account.userId)) {
      album = await _updateAlbumPostResync(album, items);
    }
    album = album.copyWith(
      provider: AlbumStaticProvider.of(album).copyWith(
        items: items,
      ),
    );
    if (mounted) {
      setState(() {
        _album = album;
        _transformItems();
        initCover(widget.account, album);
      });
    }
  }

  Future<Album> _updateAlbumPostResync(
      Album album, List<AlbumItem> items) async {
    return await UpdateAlbumWithActualItems(_c.albumRepo)(
        widget.account, album, items);
  }

  Future<void> _showSharedAlbumInfoDialog() {
    if (!Pref().hasShownSharedAlbumInfoOr(false)) {
      return showDialog(
        context: context,
        builder: (_) => const SharedAlbumInfoDialog(),
        barrierDismissible: false,
      );
    } else {
      return Future.value();
    }
  }

  bool get _canRemoveSelection {
    if (_album!.albumFile!.isOwned(widget.account.userId) == true) {
      return true;
    }
    final selectedIndexes =
        selectedListItems.whereType<_ListItem>().map((e) => e.index).toList();
    final selectedItemsIt = _sortedItems.takeIndex(selectedIndexes);
    return selectedItemsIt.any((item) => item.addedBy == widget.account.userId);
  }

  static List<AlbumItem> _getAlbumItemsOf(Album a) =>
      AlbumStaticProvider.of(a).items;

  late final DiContainer _c;

  Album? _album;
  var _sortedItems = <AlbumItem>[];
  var _backingFiles = <File>[];

  final _scrollController = ScrollController();
  double? _itemListMaxExtent;
  bool _isDragging = false;
  // == null if not drag scrolling
  bool? _isDragScrollingDown;
  final _editFormKey = GlobalKey<FormState>();
  Album? _editAlbum;

  late AppEventListener<AlbumUpdatedEvent> _albumUpdatedListener;

  static final _log = Logger("widget.album_browser._AlbumBrowserState");

  static const _menuValueDownload = 0;
  static const _menuValueFixShares = 1;
}

enum _SelectionMenuOption {
  download,
  removeFromAlbum,
}

abstract class _ListItem implements SelectableItem, DraggableItem {
  const _ListItem({
    required this.index,
    this.onTap,
    DragTargetAccept<DraggableItem>? onDropBefore,
    DragTargetAccept<DraggableItem>? onDropAfter,
    VoidCallback? onDragStarted,
    VoidCallback? onDragEndedAny,
  })  : _onDropBefore = onDropBefore,
        _onDropAfter = onDropAfter,
        _onDragStarted = onDragStarted,
        _onDragEndedAny = onDragEndedAny;

  @override
  get isTappable => onTap != null;

  @override
  get isSelectable => true;

  @override
  get isDraggable => true;

  @override
  get onDropBefore => _onDropBefore;

  @override
  get onDropAfter => _onDropAfter;

  @override
  get onDragStarted => _onDragStarted;

  @override
  get onDragEndedAny => _onDragEndedAny;

  @override
  get staggeredTile => const StaggeredTile.count(1, 1);

  @override
  buildDragFeedbackWidget(BuildContext context) => null;

  @override
  toString() {
    return "$runtimeType {"
        "index: $index, "
        "}";
  }

  final int index;

  final VoidCallback? onTap;
  final DragTargetAccept<DraggableItem>? _onDropBefore;
  final DragTargetAccept<DraggableItem>? _onDropAfter;
  final VoidCallback? _onDragStarted;
  final VoidCallback? _onDragEndedAny;
}

abstract class _FileListItem extends _ListItem {
  _FileListItem({
    required int index,
    required this.file,
    VoidCallback? onTap,
    DragTargetAccept<DraggableItem>? onDropBefore,
    DragTargetAccept<DraggableItem>? onDropAfter,
    VoidCallback? onDragStarted,
    VoidCallback? onDragEndedAny,
  }) : super(
          index: index,
          onTap: onTap,
          onDropBefore: onDropBefore,
          onDropAfter: onDropAfter,
          onDragStarted: onDragStarted,
          onDragEndedAny: onDragEndedAny,
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
    DragTargetAccept<DraggableItem>? onDropBefore,
    DragTargetAccept<DraggableItem>? onDropAfter,
    VoidCallback? onDragStarted,
    VoidCallback? onDragEndedAny,
  }) : super(
          index: index,
          file: file,
          onTap: onTap,
          onDropBefore: onDropBefore,
          onDropAfter: onDropAfter,
          onDragStarted: onDragStarted,
          onDragEndedAny: onDragEndedAny,
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
    DragTargetAccept<DraggableItem>? onDropBefore,
    DragTargetAccept<DraggableItem>? onDropAfter,
    VoidCallback? onDragStarted,
    VoidCallback? onDragEndedAny,
  }) : super(
          index: index,
          file: file,
          onTap: onTap,
          onDropBefore: onDropBefore,
          onDropAfter: onDropAfter,
          onDragStarted: onDragStarted,
          onDragEndedAny: onDragEndedAny,
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

class _LabelListItem extends _ListItem {
  _LabelListItem({
    required int index,
    required this.text,
    DragTargetAccept<DraggableItem>? onDropBefore,
    DragTargetAccept<DraggableItem>? onDropAfter,
    VoidCallback? onDragStarted,
    VoidCallback? onDragEndedAny,
  }) : super(
          index: index,
          onDropBefore: onDropBefore,
          onDropAfter: onDropAfter,
          onDragStarted: onDragStarted,
          onDragEndedAny: onDragEndedAny,
        );

  @override
  get staggeredTile => const StaggeredTile.extent(99, 56);

  @override
  buildWidget(BuildContext context) {
    return PhotoListLabel(
      text: text,
    );
  }

  final String text;
}

class _EditLabelListItem extends _LabelListItem {
  _EditLabelListItem({
    required int index,
    required String text,
    required this.onEditPressed,
    DragTargetAccept<DraggableItem>? onDropBefore,
    DragTargetAccept<DraggableItem>? onDropAfter,
    VoidCallback? onDragStarted,
    VoidCallback? onDragEndedAny,
  }) : super(
          index: index,
          text: text,
          onDropBefore: onDropBefore,
          onDropAfter: onDropAfter,
          onDragStarted: onDragStarted,
          onDragEndedAny: onDragEndedAny,
        );

  @override
  buildWidget(BuildContext context) {
    return PhotoListLabelEdit(
      text: text,
      onEditPressed: onEditPressed,
    );
  }

  @override
  buildDragFeedbackWidget(BuildContext context) {
    return super.buildWidget(context);
  }

  final VoidCallback? onEditPressed;
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
