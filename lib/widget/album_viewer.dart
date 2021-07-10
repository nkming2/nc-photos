import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/session_storage.dart';
import 'package:nc_photos/share_handler.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/resync_album.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:nc_photos/widget/album_viewer_mixin.dart';
import 'package:nc_photos/widget/draggable_item_list_mixin.dart';
import 'package:nc_photos/widget/fancy_option_picker.dart';
import 'package:nc_photos/widget/photo_list_item.dart';
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/simple_input_dialog.dart';
import 'package:nc_photos/widget/viewer.dart';
import 'package:quiver/iterables.dart';

class AlbumViewerArguments {
  AlbumViewerArguments(this.account, this.album);

  final Account account;
  final Album album;
}

class AlbumViewer extends StatefulWidget {
  static const routeName = "/album-viewer";

  AlbumViewer({
    Key key,
    @required this.account,
    @required this.album,
  }) : super(key: key);

  AlbumViewer.fromArgs(AlbumViewerArguments args, {Key key})
      : this(
          key: key,
          account: args.account,
          album: args.album,
        );

  @override
  createState() => _AlbumViewerState();

  final Account account;
  final Album album;
}

class _AlbumViewerState extends State<AlbumViewer>
    with
        WidgetsBindingObserver,
        SelectableItemStreamListMixin<AlbumViewer>,
        DraggableItemListMixin<AlbumViewer>,
        AlbumViewerMixin<AlbumViewer> {
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

  @override
  enterEditMode() {
    super.enterEditMode();
    _editAlbum = _album.copyWith();
    setState(() {
      _transformItems();
    });

    if (!SessionStorage().hasShowDragRearrangeNotification) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(
            AppLocalizations.of(context).albumEditDragRearrangeNotification),
        duration: k.snackBarDurationNormal,
      ));
      SessionStorage().hasShowDragRearrangeNotification = true;
    }
  }

  @override
  validateEditMode() => _editFormKey?.currentState?.validate() == true;

  @override
  doneEditMode() {
    try {
      // persist the changes
      _editFormKey.currentState.save();
      final newAlbum = makeEdited(_editAlbum);
      if (newAlbum.copyWith(lastUpdated: _album.lastUpdated) != _album) {
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
        _transformItems();
      });
    }
  }

  void _initAlbum() {
    assert(widget.album.provider is AlbumStaticProvider);
    ResyncAlbum()(widget.account, widget.album).then((album) {
      if (_shouldPropagateResyncedAlbum(album)) {
        UpdateAlbum(AlbumRepo(AlbumCachedDataSource()))(widget.account, album)
            .catchError((e, stacktrace) {
          _log.shout("[_initAlbum] Failed while updating album", e, stacktrace);
        });
      }
      if (mounted) {
        setState(() {
          _album = album;
          _transformItems();
          initCover(widget.account, _backingFiles);
        });
      }
    });
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

    Widget content = CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildAppBar(context),
        SliverPadding(
          padding: const EdgeInsets.only(top: 8),
          sliver: isEditMode
              ? buildDraggableItemList(
                  maxCrossAxisExtent: thumbSize.toDouble(),
                  onMaxExtentChanged: (value) {
                    _itemListMaxExtent = value;
                  },
                )
              : buildItemStreamList(
                  maxCrossAxisExtent: thumbSize.toDouble(),
                ),
        ),
      ],
    );
    if (isEditMode) {
      content = Listener(
        onPointerMove: _onEditModePointerMove,
        child: content,
      );
    }
    return buildItemStreamListOuter(
      context,
      child: Theme(
        data: Theme.of(context).copyWith(
          accentColor: AppTheme.getOverscrollIndicatorColor(context),
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
      return buildNormalAppBar(context, widget.account, _album);
    }
  }

  Widget _buildSelectionAppBar(BuildContext context) {
    return buildSelectionAppBar(context, [
      if (platform_k.isAndroid)
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: AppLocalizations.of(context).shareSelectedTooltip,
          onPressed: () {
            _onSelectionAppBarSharePressed(context);
          },
        ),
      IconButton(
        icon: const Icon(Icons.remove),
        tooltip: AppLocalizations.of(context).removeSelectedFromAlbumTooltip,
        onPressed: () {
          _onSelectionAppBarRemovePressed();
        },
      )
    ]);
  }

  Widget _buildEditAppBar(BuildContext context) {
    return buildEditAppBar(context, widget.account, widget.album, actions: [
      IconButton(
        icon: Icon(Icons.text_fields),
        tooltip: AppLocalizations.of(context).albumAddTextTooltip,
        onPressed: _onEditAppBarAddTextPressed,
      ),
      IconButton(
        icon: Icon(Icons.sort_by_alpha),
        tooltip: AppLocalizations.of(context).sortTooltip,
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

  void _onSelectionAppBarSharePressed(BuildContext context) {
    assert(platform_k.isAndroid);
    final selected = selectedListItems
        .whereType<_FileListItem>()
        .map((e) => e.file)
        .toList();
    if (selected.isEmpty) {
      SnackBarManager().showSnackBar(SnackBar(
        content:
            Text(AppLocalizations.of(context).shareSelectedEmptyNotification),
        duration: k.snackBarDurationNormal,
      ));
      return;
    }
    ShareHandler().shareFiles(context, widget.account, selected).then((_) {
      setState(() {
        clearSelectedItems();
      });
    });
  }

  void _onSelectionAppBarRemovePressed() {
    final selectedIndexes =
        selectedListItems.map((e) => (e as _ListItem).index).toList();
    final newItems = _sortedItems
        .withIndex()
        .where((element) => !selectedIndexes.contains(element.item1))
        .map((e) => e.item2)
        .toList();

    final albumRepo = AlbumRepo(AlbumCachedDataSource());
    final newAlbum = _album.copyWith(
      provider: AlbumStaticProvider(
        items: newItems,
      ),
    );
    UpdateAlbum(albumRepo)(widget.account, newAlbum).then((_) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)
            .removeSelectedFromAlbumSuccessNotification(
                selectedIndexes.length)),
        duration: k.snackBarDurationNormal,
      ));
      setState(() {
        _album = newAlbum;
        _transformItems();
        initCover(widget.account, _backingFiles);
      });
    }).catchError((e, stacktrace) {
      _log.shout("[_onSelectionRemovePressed] Failed while updating album", e,
          stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(
            "${AppLocalizations.of(context).removeSelectedFromAlbumFailureNotification}: "
            "${exception_util.toUserString(e, context)}"),
        duration: k.snackBarDurationNormal,
      ));
    });
    setState(() {
      clearSelectedItems();
    });
  }

  void _onEditAppBarSortPressed() {
    final sortProvider = _editAlbum.sortProvider;
    showDialog(
      context: context,
      builder: (context) => FancyOptionPicker(
        title: AppLocalizations.of(context).sortOptionDialogTitle,
        items: [
          FancyOptionPickerItem(
            label: AppLocalizations.of(context).sortOptionTimeAscendingLabel,
            isSelected: sortProvider is AlbumTimeSortProvider &&
                sortProvider.isAscending,
            onSelect: () {
              _onSortOldestPressed();
              Navigator.of(context).pop();
            },
          ),
          FancyOptionPickerItem(
            label: AppLocalizations.of(context).sortOptionTimeDescendingLabel,
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
    _editAlbum = _editAlbum.copyWith(
      sortProvider: AlbumTimeSortProvider(isAscending: true),
    );
    setState(() {
      _transformItems();
    });
  }

  void _onSortNewestPressed() {
    _editAlbum = _editAlbum.copyWith(
      sortProvider: AlbumTimeSortProvider(isAscending: false),
    );
    setState(() {
      _transformItems();
    });
  }

  void _onEditModePointerMove(PointerMoveEvent event) {
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
      _log.fine("[_onEditModePointerMove] Begin scrolling down");
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
      _log.fine("[_onEditModePointerMove] Begin scrolling up");
      if (_scrollController.offset > 0) {
        _scrollController.animateTo(0,
            duration: Duration(
                milliseconds: (_scrollController.offset * 1.6).round()),
            curve: Curves.linear);
        _isDragScrollingDown = false;
      }
    } else if (_isDragScrollingDown != null) {
      _log.fine("[_onEditModePointerMove] Stop scrolling");
      _scrollController.jumpTo(_scrollController.offset);
      _isDragScrollingDown = null;
    }
  }

  void _onItemMoved(int fromIndex, int toIndex, bool isBefore) {
    if (fromIndex == toIndex) {
      return;
    }
    final item = _sortedItems.removeAt(fromIndex);
    final newIndex =
        toIndex + (isBefore ? 0 : 1) + (fromIndex < toIndex ? -1 : 0);
    _sortedItems.insert(newIndex, item);
    _editAlbum = _editAlbum.copyWith(
      sortProvider: AlbumNullSortProvider(),
      // save the current order
      provider: AlbumStaticProvider(
        items: _sortedItems,
      ),
    );
    setState(() {
      _transformItems();
    });
  }

  void _onEditAppBarAddTextPressed() {
    showDialog(
      context: context,
      builder: (context) => SimpleInputDialog(),
    ).then((value) {
      if (value == null) {
        return;
      }
      _editAlbum = _editAlbum.copyWith(
        provider: AlbumStaticProvider(
          items: [
            AlbumLabelItem(text: value),
            ..._sortedItems,
          ],
        ),
      );
      setState(() {
        _transformItems();
      });
    });
  }

  void _onLabelItemEditPressed(AlbumLabelItem item, int index) {
    showDialog(
      context: context,
      builder: (context) => SimpleInputDialog(
        initialText: item.text,
      ),
    ).then((value) {
      if (value == null) {
        return;
      }
      _sortedItems[index] = AlbumLabelItem(text: value);
      _editAlbum = _editAlbum.copyWith(
        provider: AlbumStaticProvider(
          items: _sortedItems,
        ),
      );
      setState(() {
        _transformItems();
      });
    });
  }

  void _transformItems() {
    if (_editAlbum != null) {
      // edit mode
      _sortedItems = _editAlbum.sortProvider.sort(_getAlbumItemsOf(_editAlbum));
    } else {
      _sortedItems = _album.sortProvider.sort(_getAlbumItemsOf(_album));
    }
    _backingFiles = _sortedItems
        .whereType<AlbumFileItem>()
        .map((e) => e.file)
        .where((element) => file_util.isSupportedFormat(element))
        .toList();

    final items = () sync* {
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
              onDropBefore: (dropItem) =>
                  _onItemMoved((dropItem as _ListItem).index, i, true),
              onDropAfter: (dropItem) =>
                  _onItemMoved((dropItem as _ListItem).index, i, false),
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
                  _onItemMoved((dropItem as _ListItem).index, i, true),
              onDropAfter: (dropItem) =>
                  _onItemMoved((dropItem as _ListItem).index, i, false),
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
              onEditPressed: () => _onLabelItemEditPressed(item, i),
              onDropBefore: (dropItem) =>
                  _onItemMoved((dropItem as _ListItem).index, i, true),
              onDropAfter: (dropItem) =>
                  _onItemMoved((dropItem as _ListItem).index, i, false),
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

  bool _shouldPropagateResyncedAlbum(Album album) {
    final origItems = _getAlbumItemsOf(widget.album);
    final resyncItems = _getAlbumItemsOf(album);
    if (origItems.length != resyncItems.length) {
      _log.info(
          "[_shouldPropagateResyncedAlbum] Item length differ: ${origItems.length}, ${resyncItems.length}");
      return true;
    }
    for (final z in zip([origItems, resyncItems])) {
      final a = z[0], b = z[1];
      bool isEqual;
      if (a is AlbumFileItem && b is AlbumFileItem) {
        // faster compare
        isEqual = a.equals(b, isDeep: false);
      } else {
        isEqual = a == b;
      }
      if (!isEqual) {
        _log.info(
            "[_shouldPropagateResyncedAlbum] Item differ:\nOriginal: ${z[0]}\nResynced: ${z[1]}");
        return true;
      }
    }
    _log.info("[_shouldPropagateResyncedAlbum] false");
    return false;
  }

  static List<AlbumItem> _getAlbumItemsOf(Album a) =>
      AlbumStaticProvider.of(a).items;

  Album _album;
  var _sortedItems = <AlbumItem>[];
  var _backingFiles = <File>[];

  final _scrollController = ScrollController();
  double _itemListMaxExtent;
  bool _isDragging = false;
  // == null if not drag scrolling
  bool _isDragScrollingDown;
  final _editFormKey = GlobalKey<FormState>();
  Album _editAlbum;

  static final _log = Logger("widget.album_viewer._AlbumViewerState");
}

abstract class _ListItem implements SelectableItem, DraggableItem {
  _ListItem({
    @required this.index,
    VoidCallback onTap,
    DragTargetAccept<DraggableItem> onDropBefore,
    DragTargetAccept<DraggableItem> onDropAfter,
    VoidCallback onDragStarted,
    VoidCallback onDragEndedAny,
  })  : _onTap = onTap,
        _onDropBefore = onDropBefore,
        _onDropAfter = onDropAfter,
        _onDragStarted = onDragStarted,
        _onDragEndedAny = onDragEndedAny;

  @override
  get onTap => _onTap;

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

  final VoidCallback _onTap;
  final DragTargetAccept<DraggableItem> _onDropBefore;
  final DragTargetAccept<DraggableItem> _onDropAfter;
  final VoidCallback _onDragStarted;
  final VoidCallback _onDragEndedAny;
}

abstract class _FileListItem extends _ListItem {
  _FileListItem({
    @required int index,
    @required this.file,
    VoidCallback onTap,
    DragTargetAccept<DraggableItem> onDropBefore,
    DragTargetAccept<DraggableItem> onDropAfter,
    VoidCallback onDragStarted,
    VoidCallback onDragEndedAny,
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
    @required int index,
    @required File file,
    @required this.account,
    @required this.previewUrl,
    VoidCallback onTap,
    DragTargetAccept<DraggableItem> onDropBefore,
    DragTargetAccept<DraggableItem> onDropAfter,
    VoidCallback onDragStarted,
    VoidCallback onDragEndedAny,
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
    @required int index,
    @required File file,
    @required this.account,
    @required this.previewUrl,
    VoidCallback onTap,
    DragTargetAccept<DraggableItem> onDropBefore,
    DragTargetAccept<DraggableItem> onDropAfter,
    VoidCallback onDragStarted,
    VoidCallback onDragEndedAny,
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
    @required int index,
    @required this.text,
    DragTargetAccept<DraggableItem> onDropBefore,
    DragTargetAccept<DraggableItem> onDropAfter,
    VoidCallback onDragStarted,
    VoidCallback onDragEndedAny,
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
    return Container(
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: Theme.of(context).textTheme.subtitle1,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  final String text;
}

class _EditLabelListItem extends _LabelListItem {
  _EditLabelListItem({
    @required int index,
    @required String text,
    @required this.onEditPressed,
    DragTargetAccept<DraggableItem> onDropBefore,
    DragTargetAccept<DraggableItem> onDropAfter,
    VoidCallback onDragStarted,
    VoidCallback onDragEndedAny,
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
    return Stack(
      children: [
        // needed to expand the touch sensitive area to the whole row
        Container(
          color: Colors.transparent,
        ),
        super.buildWidget(context),
        PositionedDirectional(
          top: 0,
          bottom: 0,
          end: 0,
          child: IconButton(
            icon: Icon(Icons.edit),
            tooltip: AppLocalizations.of(context).editTooltip,
            onPressed: onEditPressed,
          ),
        ),
      ],
    );
  }

  @override
  buildDragFeedbackWidget(BuildContext context) {
    return super.buildWidget(context);
  }

  final VoidCallback onEditPressed;
}
