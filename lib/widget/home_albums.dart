import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/list_album.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/remove.dart';
import 'package:nc_photos/widget/album_browser.dart';
import 'package:nc_photos/widget/album_grid_item.dart';
import 'package:nc_photos/widget/album_importer.dart';
import 'package:nc_photos/widget/album_search_delegate.dart';
import 'package:nc_photos/widget/archive_browser.dart';
import 'package:nc_photos/widget/builder/album_grid_item_builder.dart';
import 'package:nc_photos/widget/dynamic_album_browser.dart';
import 'package:nc_photos/widget/home_app_bar.dart';
import 'package:nc_photos/widget/new_album_dialog.dart';
import 'package:nc_photos/widget/page_visibility_mixin.dart';
import 'package:nc_photos/widget/selection_app_bar.dart';
import 'package:nc_photos/widget/trashbin_browser.dart';
import 'package:tuple/tuple.dart';

class HomeAlbums extends StatefulWidget {
  HomeAlbums({
    Key? key,
    required this.account,
  }) : super(key: key);

  @override
  createState() => _HomeAlbumsState();

  final Account account;
}

class _HomeAlbumsState extends State<HomeAlbums>
    with RouteAware, PageVisibilityMixin<HomeAlbums> {
  @override
  initState() {
    super.initState();
    _initBloc();
  }

  @override
  build(BuildContext context) {
    return BlocListener<ListAlbumBloc, ListAlbumBlocState>(
      bloc: _bloc,
      listener: (context, state) => _onStateChange(context, state),
      child: BlocBuilder<ListAlbumBloc, ListAlbumBlocState>(
        bloc: _bloc,
        builder: (context, state) => _buildContent(context, state),
      ),
    );
  }

  void _initBloc() {
    ListAlbumBloc bloc;
    final blocId =
        "${widget.account.scheme}://${widget.account.username}@${widget.account.address}";
    try {
      _log.fine("[_initBloc] Resolving bloc for '$blocId'");
      bloc = KiwiContainer().resolve<ListAlbumBloc>("ListAlbumBloc($blocId)");
    } catch (e) {
      // no created instance for this account, make a new one
      _log.info("[_initBloc] New bloc instance for account: ${widget.account}");
      bloc = ListAlbumBloc();
      KiwiContainer().registerInstance<ListAlbumBloc>(bloc,
          name: "ListAlbumBloc($blocId)");
    }

    _bloc = bloc;
    if (_bloc.state is ListAlbumBlocInit) {
      _log.info("[_initBloc] Initialize bloc");
      _reqQuery();
    } else {
      // process the current state
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        setState(() {
          _onStateChange(context, _bloc.state);
        });
      });
    }
  }

  Widget _buildContent(BuildContext context, ListAlbumBlocState state) {
    return Stack(
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            accentColor: AppTheme.getOverscrollIndicatorColor(context),
          ),
          child: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverStaggeredGrid.extentBuilder(
                  maxCrossAxisExtent: 256,
                  mainAxisSpacing: 8,
                  itemCount: _items.length + (_isSelectionMode ? 0 : 3),
                  itemBuilder: _buildItem,
                  staggeredTileBuilder: (index) {
                    return const StaggeredTile.count(1, 1);
                  },
                ),
              ),
            ],
          ),
        ),
        if (state is ListAlbumBlocLoading)
          Align(
            alignment: Alignment.bottomCenter,
            child: const LinearProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    if (_isSelectionMode) {
      return _buildSelectionAppBar(context);
    } else {
      return _buildNormalAppBar(context);
    }
  }

  Widget _buildSelectionAppBar(BuildContext conetxt) {
    return SelectionAppBar(
      count: _selectedItems.length,
      onClosePressed: () {
        setState(() {
          _selectedItems.clear();
        });
      },
      actions: [
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: L10n.of(context).deleteSelectedTooltip,
          onPressed: () {
            _onSelectionAppBarDeletePressed();
          },
        ),
      ],
    );
  }

  Widget _buildNormalAppBar(BuildContext context) {
    return HomeSliverAppBar(
      account: widget.account,
      actions: [
        IconButton(
          onPressed: () => _onSearchPressed(context),
          icon: const Icon(Icons.search),
          tooltip: L10n.of(context).searchTooltip,
        ),
      ],
      menuActions: [
        PopupMenuItem(
          value: _menuValueImport,
          child: Text(L10n.of(context).importFoldersTooltip),
        ),
      ],
      onSelectedMenuActions: (option) {
        switch (option) {
          case _menuValueImport:
            _onAppBarImportPressed(context);
            break;
        }
      },
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    if (index < _items.length) {
      return _buildAlbumItem(context, index);
    } else if (index == _items.length) {
      return _buildArchiveItem(context);
    } else if (index == _items.length + 1) {
      return _buildTrashbinItem(context);
    } else {
      return _buildNewAlbumItem(context);
    }
  }

  Widget _buildAlbumItem(BuildContext context, int index) {
    final item = _items[index];
    return AlbumGridItemBuilder(
      account: widget.account,
      album: item.album,
      isSelected: _selectedItems.contains(item),
      onTap: () => _onItemTap(item),
      onLongPress: _isSelectionMode ? null : () => _onItemLongPress(item),
    ).build(context);
  }

  Widget _buildArchiveItem(BuildContext context) {
    return AlbumGridItem(
      cover: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: AppTheme.getListItemBackgroundColor(context),
          constraints: const BoxConstraints.expand(),
          child: Icon(
            Icons.archive,
            color: Colors.white.withOpacity(.8),
            size: 88,
          ),
        ),
      ),
      title: L10n.of(context).albumArchiveLabel,
      onTap: () {
        Navigator.of(context).pushNamed(ArchiveBrowser.routeName,
            arguments: ArchiveBrowserArguments(widget.account));
      },
    );
  }

  Widget _buildTrashbinItem(BuildContext context) {
    return AlbumGridItem(
      cover: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: AppTheme.getListItemBackgroundColor(context),
          constraints: const BoxConstraints.expand(),
          child: Icon(
            Icons.delete,
            color: Colors.white.withOpacity(.8),
            size: 88,
          ),
        ),
      ),
      title: L10n.of(context).albumTrashLabel,
      onTap: () {
        Navigator.of(context).pushNamed(TrashbinBrowser.routeName,
            arguments: TrashbinBrowserArguments(widget.account));
      },
    );
  }

  Widget _buildNewAlbumItem(BuildContext context) {
    return AlbumGridItem(
      cover: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: AppTheme.getListItemBackgroundColor(context),
          constraints: const BoxConstraints.expand(),
          child: Icon(
            Icons.add,
            color: Colors.white.withOpacity(.8),
            size: 88,
          ),
        ),
      ),
      title: L10n.of(context).createAlbumTooltip,
      onTap: () => _onNewAlbumItemTap(context),
    );
  }

  void _onStateChange(BuildContext context, ListAlbumBlocState state) {
    if (state is ListAlbumBlocInit) {
      _items.clear();
    } else if (state is ListAlbumBlocSuccess || state is ListAlbumBlocLoading) {
      _transformItems(state.albums);
    } else if (state is ListAlbumBlocFailure) {
      _transformItems(state.albums);
      if (isPageVisible()) {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(exception_util.toUserString(state.exception, context)),
          duration: k.snackBarDurationNormal,
        ));
      }
    } else if (state is ListAlbumBlocInconsistent) {
      _reqQuery();
    }
  }

  void _onItemTap(_GridItem item) {
    if (_isSelectionMode) {
      if (!_items.contains(item)) {
        _log.warning("[_onItemTap] Item not found in backing list, ignoring");
        return;
      }
      if (_selectedItems.contains(item)) {
        // unselect
        setState(() {
          _selectedItems.remove(item);
        });
      } else {
        // select
        setState(() {
          _selectedItems.add(item);
        });
      }
    } else {
      _openAlbum(item.album);
    }
  }

  void _onItemLongPress(_GridItem item) {
    if (!_items.contains(item)) {
      _log.warning(
          "[_onItemLongPress] Item not found in backing list, ignoring");
      return;
    }
    setState(() {
      _selectedItems.add(item);
    });
  }

  void _onNewAlbumItemTap(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => NewAlbumDialog(
        account: widget.account,
      ),
    ).then((album) {
      if (album == null || album is! Album) {
        return;
      }
      if (album.provider is AlbumDynamicProvider) {
        // open the album automatically to refresh its content, otherwise it'll
        // be empty
        Navigator.of(context).pushNamed(DynamicAlbumBrowser.routeName,
            arguments: DynamicAlbumBrowserArguments(widget.account, album));
      }
    }).catchError((e, stacktrace) {
      _log.severe(
          "[_onNewAlbumItemTap] Failed while showDialog", e, stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.of(context).createAlbumFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
    });
  }

  void _onAppBarImportPressed(BuildContext context) {
    Navigator.of(context).pushNamed(AlbumImporter.routeName,
        arguments: AlbumImporterArguments(widget.account));
  }

  Future<void> _onSelectionAppBarDeletePressed() async {
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(L10n.of(context)
          .deleteSelectedProcessingNotification(_selectedItems.length)),
      duration: k.snackBarDurationShort,
    ));
    final selectedFiles =
        _selectedItems.map((e) => e.album.albumFile!).toList();
    setState(() {
      _selectedItems.clear();
    });
    final fileRepo = FileRepo(FileCachedDataSource());
    final albumRepo = AlbumRepo(AlbumCachedDataSource());
    final failures = <File>[];
    for (final f in selectedFiles) {
      try {
        await Remove(fileRepo, albumRepo)(widget.account, f);
      } catch (e, stacktrace) {
        _log.shout(
            "[_onSelectionAppBarDeletePressed] Failed while removing file" +
                (kDebugMode ? ": ${f.path}" : ""),
            e,
            stacktrace);
        failures.add(f);
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
  }

  void _onSearchPressed(BuildContext context) {
    showSearch(
      context: context,
      delegate: AlbumSearchDelegate(context, widget.account),
    ).then((value) {
      if (value is Album) {
        _openAlbum(value);
      }
    });
  }

  /// Transform an Album list to grid items
  void _transformItems(List<Album> albums) {
    final sortedAlbums = albums
        .map((e) => Tuple2(e.provider.latestItemTime ?? e.lastUpdated, e))
        .sorted((a, b) {
      // then sort in descending order
      final tmp = b.item1.compareTo(a.item1);
      if (tmp != 0) {
        return tmp;
      } else {
        return a.item2.name.compareTo(b.item2.name);
      }
    }).map((e) => e.item2);
    _items.clear();
    _items.addAll(sortedAlbums.map((e) => _GridItem(e)));

    _transformSelectedItems();
  }

  /// Map selected items to the new item list
  void _transformSelectedItems() {
    final newSelectedItems = _selectedItems
        .map((from) {
          try {
            return _items.whereType<_GridItem>().firstWhere(
                (to) => from.album.albumFile!.path == to.album.albumFile!.path);
          } catch (_) {
            return null;
          }
        })
        .whereType<_GridItem>()
        .toList();
    _selectedItems
      ..clear()
      ..addAll(newSelectedItems);
  }

  void _openAlbum(Album album) {
    if (album.provider is AlbumStaticProvider) {
      Navigator.of(context).pushNamed(AlbumBrowser.routeName,
          arguments: AlbumBrowserArguments(widget.account, album));
    } else {
      Navigator.of(context).pushNamed(DynamicAlbumBrowser.routeName,
          arguments: DynamicAlbumBrowserArguments(widget.account, album));
    }
  }

  void _reqQuery() {
    _bloc.add(ListAlbumBlocQuery(widget.account));
  }

  bool get _isSelectionMode => _selectedItems.isNotEmpty;

  late ListAlbumBloc _bloc;

  final _items = <_GridItem>[];
  final _selectedItems = <_GridItem>[];

  static final _log = Logger("widget.home_albums._HomeAlbumsState");
  static const _menuValueImport = 0;
}

class _GridItem {
  _GridItem(this.album);

  Album album;
}
