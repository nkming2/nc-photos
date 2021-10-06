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
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/lab.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/remove.dart';
import 'package:nc_photos/widget/album_browser_util.dart' as album_browser_util;
import 'package:nc_photos/widget/album_importer.dart';
import 'package:nc_photos/widget/album_search_delegate.dart';
import 'package:nc_photos/widget/archive_browser.dart';
import 'package:nc_photos/widget/builder/album_grid_item_builder.dart';
import 'package:nc_photos/widget/dynamic_album_browser.dart';
import 'package:nc_photos/widget/fancy_option_picker.dart';
import 'package:nc_photos/widget/home_app_bar.dart';
import 'package:nc_photos/widget/new_album_dialog.dart';
import 'package:nc_photos/widget/page_visibility_mixin.dart';
import 'package:nc_photos/widget/pending_albums.dart';
import 'package:nc_photos/widget/people_browser.dart';
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/selection_app_bar.dart';
import 'package:nc_photos/widget/sharing_browser.dart';
import 'package:nc_photos/widget/trashbin_browser.dart';
import 'package:tuple/tuple.dart';

class HomeAlbums extends StatefulWidget {
  const HomeAlbums({
    Key? key,
    required this.account,
  }) : super(key: key);

  @override
  createState() => _HomeAlbumsState();

  final Account account;
}

class _HomeAlbumsState extends State<HomeAlbums>
    with
        SelectableItemStreamListMixin,
        RouteAware,
        PageVisibilityMixin<HomeAlbums> {
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
        buildItemStreamListOuter(
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
                SliverPadding(
                  padding: const EdgeInsets.all(8),
                  sliver: buildItemStreamList(
                    maxCrossAxisExtent: 256,
                    mainAxisSpacing: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (state is ListAlbumBlocLoading)
          const Align(
            alignment: Alignment.bottomCenter,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    if (isSelectionMode) {
      return _buildSelectionAppBar(context);
    } else {
      return _buildNormalAppBar(context);
    }
  }

  Widget _buildSelectionAppBar(BuildContext conetxt) {
    return SelectionAppBar(
      count: selectedListItems.length,
      onClosePressed: () {
        setState(() {
          clearSelectedItems();
        });
      },
      actions: [
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: L10n.global().deleteTooltip,
          onPressed: () {
            _onSelectionDeletePressed();
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
          tooltip: L10n.global().searchTooltip,
        ),
      ],
      menuActions: [
        PopupMenuItem(
          value: _menuValueSort,
          child: Text(L10n.global().sortTooltip),
        ),
        PopupMenuItem(
          value: _menuValueImport,
          child: Text(L10n.global().importFoldersTooltip),
        ),
      ],
      onSelectedMenuActions: (option) {
        switch (option) {
          case _menuValueSort:
            _onSortPressed(context);
            break;

          case _menuValueImport:
            _onImportPressed(context);
            break;
        }
      },
    );
  }

  SelectableItem _buildPersonItem(BuildContext context) {
    return _ButtonListItem(
      icon: Icons.person_outlined,
      label: L10n.global().collectionPeopleLabel,
      onTap: () {
        if (!isSelectionMode) {
          Navigator.of(context).pushNamed(PeopleBrowser.routeName,
              arguments: PeopleBrowserArguments(widget.account));
        }
      },
    );
  }

  SelectableItem _buildArchiveItem(BuildContext context) {
    return _ButtonListItem(
      icon: Icons.archive_outlined,
      label: L10n.global().albumArchiveLabel,
      onTap: () {
        if (!isSelectionMode) {
          Navigator.of(context).pushNamed(ArchiveBrowser.routeName,
              arguments: ArchiveBrowserArguments(widget.account));
        }
      },
    );
  }

  SelectableItem _buildTrashbinItem(BuildContext context) {
    return _ButtonListItem(
      icon: Icons.delete_outlined,
      label: L10n.global().albumTrashLabel,
      onTap: () {
        if (!isSelectionMode) {
          Navigator.of(context).pushNamed(TrashbinBrowser.routeName,
              arguments: TrashbinBrowserArguments(widget.account));
        }
      },
    );
  }

  SelectableItem _buildSharingItem(BuildContext context) {
    return _ButtonListItem(
      icon: Icons.share_outlined,
      label: L10n.global().collectionSharingLabel,
      onTap: () {
        if (!isSelectionMode) {
          Navigator.of(context).pushNamed(SharingBrowser.routeName,
              arguments: SharingBrowserArguments(widget.account));
        }
      },
    );
  }

  SelectableItem _buildShareItem(BuildContext context) {
    return _ButtonListItem(
      icon: Icons.share_outlined,
      label: "Sharing (Lab)",
      isShowIndicator: Pref.inst().hasNewSharedAlbumOr(false),
      onTap: () {
        if (!isSelectionMode) {
          Navigator.of(context).pushNamed(PendingAlbums.routeName,
              arguments: PendingAlbumsArguments(widget.account));
        }
      },
    );
  }

  SelectableItem _buildNewAlbumItem(BuildContext context) {
    return _ButtonListItem(
      icon: Icons.add,
      label: L10n.global().createAlbumTooltip,
      onTap: () {
        if (!isSelectionMode) {
          _onNewAlbumItemTap(context);
        }
      },
    );
  }

  void _onStateChange(BuildContext context, ListAlbumBlocState state) {
    if (state is ListAlbumBlocInit) {
      itemStreamListItems = [];
    } else if (state is ListAlbumBlocSuccess || state is ListAlbumBlocLoading) {
      _transformItems(state.items);
    } else if (state is ListAlbumBlocFailure) {
      _transformItems(state.items);
      if (isPageVisible()) {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(exception_util.toUserString(state.exception)),
          duration: k.snackBarDurationNormal,
        ));
      }
    } else if (state is ListAlbumBlocInconsistent) {
      _reqQuery();
    }
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
        content: Text(L10n.global().createAlbumFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
    });
  }

  void _onSearchPressed(BuildContext context) {
    showSearch(
      context: context,
      delegate: AlbumSearchDelegate(context, widget.account),
    ).then((value) {
      if (value is Album) {
        _openAlbum(context, value);
      }
    });
  }

  void _onSortPressed(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FancyOptionPicker(
        title: L10n.global().sortOptionDialogTitle,
        items: [
          FancyOptionPickerItem(
            label: L10n.global().sortOptionTimeDescendingLabel,
            isSelected: _getSortFromPref() == _Sort.dateDescending,
            onSelect: () {
              _onSortSelected(_Sort.dateDescending);
              Navigator.of(context).pop();
            },
          ),
          FancyOptionPickerItem(
            label: L10n.global().sortOptionTimeAscendingLabel,
            isSelected: _getSortFromPref() == _Sort.dateAscending,
            onSelect: () {
              _onSortSelected(_Sort.dateAscending);
              Navigator.of(context).pop();
            },
          ),
          FancyOptionPickerItem(
            label: L10n.global().sortOptionAlbumNameLabel,
            isSelected: _getSortFromPref() == _Sort.nameAscending,
            onSelect: () {
              _onSortSelected(_Sort.nameAscending);
              Navigator.of(context).pop();
            },
          ),
          FancyOptionPickerItem(
            label: L10n.global().sortOptionAlbumNameDescendingLabel,
            isSelected: _getSortFromPref() == _Sort.nameDescending,
            onSelect: () {
              _onSortSelected(_Sort.nameDescending);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _onSortSelected(_Sort sort) async {
    await Pref.inst().setHomeAlbumsSort(sort.index);
    setState(() {
      _transformItems(_bloc.state.items);
    });
  }

  void _onImportPressed(BuildContext context) {
    Navigator.of(context).pushNamed(AlbumImporter.routeName,
        arguments: AlbumImporterArguments(widget.account));
  }

  Future<void> _onSelectionDeletePressed() async {
    final selected = selectedListItems
        .whereType<_AlbumListItem>()
        .map((e) => e.album)
        .toList();
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(
          L10n.global().deleteSelectedProcessingNotification(selected.length)),
      duration: k.snackBarDurationShort,
    ));
    final selectedFiles = selected.map((e) => e.albumFile!).toList();
    setState(() {
      clearSelectedItems();
    });
    final fileRepo = FileRepo(FileCachedDataSource());
    final albumRepo = AlbumRepo(AlbumCachedDataSource());
    final failures = <File>[];
    for (final f in selectedFiles) {
      try {
        await Remove(fileRepo, albumRepo)(widget.account, f);
      } catch (e, stacktrace) {
        _log.shout(
            "[_onSelectionDeletePressed] Failed while removing file" +
                (shouldLogFileName ? ": ${f.path}" : ""),
            e,
            stacktrace);
        failures.add(f);
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
  }

  /// Transform an Album list to grid items
  void _transformItems(List<ListAlbumBlocItem> items) {
    final sort = _getSortFromPref();
    final isAscending = _isSortAscending(sort);
    final sortedAlbums = items.map<Tuple2<dynamic, ListAlbumBlocItem>>((e) {
      switch (sort) {
        case _Sort.nameAscending:
        case _Sort.nameDescending:
          return Tuple2(e.album.name, e);

        case _Sort.dateAscending:
        case _Sort.dateDescending:
        default:
          return Tuple2(
              e.album.provider.latestItemTime ?? e.album.lastUpdated, e);
      }
    }).sorted((a, b) {
      final x = isAscending ? a : b;
      final y = isAscending ? b : a;
      final tmp = x.item1.compareTo(y.item1);
      if (tmp != 0) {
        return tmp;
      } else {
        return x.item2.album.name.compareTo(y.item2.album.name);
      }
    }).map((e) => e.item2);
    itemStreamListItems = [
      _buildPersonItem(context),
      _buildSharingItem(context),
      if (Lab().enableSharedAlbum) _buildShareItem(context),
      _buildArchiveItem(context),
      _buildTrashbinItem(context),
      _buildNewAlbumItem(context),
      _SeparatorListItem(),
      ...sortedAlbums.map((e) => _AlbumListItem(
            account: widget.account,
            album: e.album,
            isSharedByMe: e.isSharedByMe,
            isSharedToMe: e.isSharedToMe,
            onTap: () {
              _openAlbum(context, e.album);
            },
          )),
    ];
  }

  void _openAlbum(BuildContext context, Album album) {
    album_browser_util.open(context, widget.account, album);
  }

  void _reqQuery() {
    _bloc.add(ListAlbumBlocQuery(widget.account));
  }

  late ListAlbumBloc _bloc;

  static final _log = Logger("widget.home_albums._HomeAlbumsState");
  static const _menuValueImport = 0;
  static const _menuValueSort = 1;
}

abstract class _ListItem implements SelectableItem {
  _ListItem({
    VoidCallback? onTap,
  }) : _myOnTap = onTap;

  @override
  get onTap => _myOnTap;

  @override
  get isSelectable => true;

  @override
  get staggeredTile => const StaggeredTile.count(1, 1);

  final VoidCallback? _myOnTap;
}

class _ButtonListItem extends _ListItem {
  _ButtonListItem({
    required this.icon,
    required this.label,
    VoidCallback? onTap,
    this.isShowIndicator = false,
  }) : _onTap = onTap;

  @override
  get isSelectable => false;

  @override
  get staggeredTile => const StaggeredTile.fit(1);

  @override
  buildWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: _onTap,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.getListItemBackgroundColor(context),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: AppTheme.getPrimaryTextColor(context),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(label),
                  ),
                  if (isShowIndicator)
                    const Icon(
                      Icons.circle,
                      color: Colors.red,
                      size: 8,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  final IconData icon;
  final String label;
  final bool isShowIndicator;

  final VoidCallback? _onTap;
}

class _SeparatorListItem extends _ListItem {
  @override
  get isSelectable => false;

  @override
  get staggeredTile => const StaggeredTile.extent(99, 1);

  @override
  buildWidget(BuildContext context) => Container();
}

class _AlbumListItem extends _ListItem {
  _AlbumListItem({
    required this.account,
    required this.album,
    required this.isSharedByMe,
    required this.isSharedToMe,
    VoidCallback? onTap,
  }) : super(onTap: onTap);

  @override
  operator ==(Object other) {
    return other is _AlbumListItem &&
        album.albumFile!.path == other.album.albumFile!.path;
  }

  @override
  get hashCode => album.albumFile!.path.hashCode;

  @override
  buildWidget(BuildContext context) {
    return AlbumGridItemBuilder(
      account: account,
      album: album,
      isShared: isSharedByMe || isSharedToMe,
    ).build(context);
  }

  final Account account;
  final Album album;
  final bool isSharedByMe;
  final bool isSharedToMe;
}

enum _Sort {
  dateDescending,
  dateAscending,
  nameAscending,
  nameDescending,
}

_Sort _getSortFromPref() {
  try {
    return _Sort.values[Pref.inst().getHomeAlbumsSort()!];
  } catch (_) {
    // default
    return _Sort.dateDescending;
  }
}

bool _isSortAscending(_Sort sort) =>
    sort == _Sort.dateAscending || sort == _Sort.nameAscending;
