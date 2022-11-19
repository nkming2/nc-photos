import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/list_album.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album_util.dart' as album_util;
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/material3.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/platform/features.dart' as features;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/remove_album.dart';
import 'package:nc_photos/use_case/unimport_shared_album.dart';
import 'package:nc_photos/widget/album_browser_util.dart' as album_browser_util;
import 'package:nc_photos/widget/album_importer.dart';
import 'package:nc_photos/widget/archive_browser.dart';
import 'package:nc_photos/widget/builder/album_grid_item_builder.dart';
import 'package:nc_photos/widget/dynamic_album_browser.dart';
import 'package:nc_photos/widget/enhanced_photo_browser.dart';
import 'package:nc_photos/widget/fancy_option_picker.dart';
import 'package:nc_photos/widget/handler/double_tap_exit_handler.dart';
import 'package:nc_photos/widget/home_app_bar.dart';
import 'package:nc_photos/widget/new_album_dialog.dart';
import 'package:nc_photos/widget/page_visibility_mixin.dart';
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/selection_app_bar.dart';
import 'package:nc_photos/widget/sharing_browser.dart';
import 'package:nc_photos/widget/trashbin_browser.dart';

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
    _accountPrefUpdatedEventListener.begin();
  }

  @override
  dispose() {
    _accountPrefUpdatedEventListener.end();
    super.dispose();
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

  @override
  onItemTap(SelectableItem item, int index) {
    item.as<_ListItem>()?.onTap?.call();
  }

  @override
  onBackButtonPressed() async {
    if (isSelectionMode) {
      return super.onBackButtonPressed();
    } else {
      return DoubleTapExitHandler()();
    }
  }

  void _initBloc() {
    if (_bloc.state is ListAlbumBlocInit) {
      _log.info("[_initBloc] Initialize bloc");
      _reqQuery();
    } else {
      // process the current state
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
          child: RefreshIndicator(
            onRefresh: () async {
              _onRefreshPressed();
              await _waitRefresh();
            },
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  sliver: buildItemStreamList(
                    maxCrossAxisExtent: 256,
                    childBorderRadius: BorderRadius.zero,
                    indicatorAlignment: const Alignment(-.92, -.92),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: _calcBottomAppBarExtent(context),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: double.infinity,
            height: _calcBottomAppBarExtent(context),
            child: ClipRect(
              child: BackdropFilter(
                filter: Theme.of(context).appBarBlurFilter,
                child: const ColoredBox(
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
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
    return BlocBuilder(
      bloc: _bloc,
      buildWhen: (previous, current) =>
          previous is ListAlbumBlocLoading != current is ListAlbumBlocLoading,
      builder: (context, state) {
        return HomeSliverAppBar(
          account: widget.account,
          isShowProgressIcon: state is ListAlbumBlocLoading,
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
      isShowIndicator: AccountPref.of(widget.account).hasNewSharedAlbumOr(),
      onTap: () {
        if (!isSelectionMode) {
          Navigator.of(context).pushNamed(SharingBrowser.routeName,
              arguments: SharingBrowserArguments(widget.account));
        }
      },
    );
  }

  SelectableItem _buildEnhancedPhotosItem(BuildContext context) {
    return _ButtonListItem(
      icon: Icons.auto_fix_high_outlined,
      label: L10n.global().collectionEditedPhotosLabel,
      onTap: () {
        if (!isSelectionMode) {
          Navigator.of(context).pushNamed(EnhancedPhotoBrowser.routeName,
              arguments: const EnhancedPhotoBrowserArguments(null));
        }
      },
    );
  }

  SelectableItem _buildNewAlbumItem(BuildContext context) {
    return _ButtonListItem(
      icon: Icons.add,
      label: L10n.global().createCollectionTooltip,
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

  Future<void> _onNewAlbumItemTap(BuildContext context) async {
    try {
      final album = await showDialog<Album>(
        context: context,
        builder: (_) => NewAlbumDialog(
          account: widget.account,
        ),
      );
      if (album == null) {
        return;
      }
      if (album.provider is AlbumDynamicProvider) {
        // open the album automatically to refresh its content, otherwise it'll
        // be empty
        unawaited(
          Navigator.of(context).pushNamed(DynamicAlbumBrowser.routeName,
              arguments: DynamicAlbumBrowserArguments(widget.account, album)),
        );
      }
    } catch (e, stacktrace) {
      _log.shout("[_onNewAlbumItemTap] Failed", e, stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().createAlbumFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  void _onRefreshPressed() {
    _reqQuery();
  }

  void _onSortPressed(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FancyOptionPicker(
        title: L10n.global().sortOptionDialogTitle,
        items: [
          FancyOptionPickerItem(
            label: L10n.global().sortOptionTimeDescendingLabel,
            isSelected:
                _getSortFromPref() == album_util.AlbumSort.dateDescending,
            onSelect: () {
              _onSortSelected(album_util.AlbumSort.dateDescending);
              Navigator.of(context).pop();
            },
          ),
          FancyOptionPickerItem(
            label: L10n.global().sortOptionTimeAscendingLabel,
            isSelected:
                _getSortFromPref() == album_util.AlbumSort.dateAscending,
            onSelect: () {
              _onSortSelected(album_util.AlbumSort.dateAscending);
              Navigator.of(context).pop();
            },
          ),
          FancyOptionPickerItem(
            label: L10n.global().sortOptionAlbumNameLabel,
            isSelected:
                _getSortFromPref() == album_util.AlbumSort.nameAscending,
            onSelect: () {
              _onSortSelected(album_util.AlbumSort.nameAscending);
              Navigator.of(context).pop();
            },
          ),
          FancyOptionPickerItem(
            label: L10n.global().sortOptionAlbumNameDescendingLabel,
            isSelected:
                _getSortFromPref() == album_util.AlbumSort.nameDescending,
            onSelect: () {
              _onSortSelected(album_util.AlbumSort.nameDescending);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onSortSelected(album_util.AlbumSort sort) async {
    await Pref().setHomeAlbumsSort(sort.index);
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
    setState(() {
      clearSelectedItems();
    });
    final failures = <Album>[];
    for (final a in selected) {
      try {
        if (a.albumFile?.isOwned(widget.account.userId) == true) {
          // delete owned albums
          await RemoveAlbum(KiwiContainer().resolve<DiContainer>())(
              widget.account, a);
        } else {
          // remove shared albums from collection
          await UnimportSharedAlbum(KiwiContainer().resolve<DiContainer>())(
              widget.account, a);
        }
      } catch (e, stackTrace) {
        _log.shout(
            "[_onSelectionDeletePressed] Failed while removing album: '${a.name}'",
            e,
            stackTrace);
        failures.add(a);
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

  void _onAccountPrefUpdatedEvent(AccountPrefUpdatedEvent ev) {
    if (ev.key == PrefKey.isEnableFaceRecognitionApp ||
        ev.key == PrefKey.hasNewSharedAlbum) {
      if (identical(ev.pref, AccountPref.of(widget.account))) {
        setState(() {
          _transformItems(_bloc.state.items);
        });
      }
    }
  }

  /// Transform an Album list to grid items
  void _transformItems(List<ListAlbumBlocItem> items) {
    final sort = _getSortFromPref();
    final sortedAlbums =
        album_util.sorted(items.map((e) => e.album).toList(), sort);
    itemStreamListItems = [
      _buildSharingItem(context),
      if (features.isSupportEnhancement) _buildEnhancedPhotosItem(context),
      _buildArchiveItem(context),
      _buildTrashbinItem(context),
      _buildNewAlbumItem(context),
      _SeparatorListItem(),
      ...sortedAlbums.map((a) => _AlbumListItem(
            account: widget.account,
            album: a,
            onTap: () {
              _openAlbum(context, a);
            },
          )),
    ];
  }

  void _openAlbum(BuildContext context, Album album) {
    album_browser_util.push(context, widget.account, album);
  }

  void _reqQuery() {
    _bloc.add(ListAlbumBlocQuery(widget.account));
  }

  Future<void> _waitRefresh() async {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      if (_bloc.state is! ListAlbumBlocLoading) {
        return;
      }
    }
  }

  double _calcBottomAppBarExtent(BuildContext context) =>
      NavigationBarTheme.of(context).height!;

  late final _bloc = ListAlbumBloc.of(widget.account);
  late final _accountPrefUpdatedEventListener =
      AppEventListener<AccountPrefUpdatedEvent>(_onAccountPrefUpdatedEvent);

  static final _log = Logger("widget.home_albums._HomeAlbumsState");
  static const _menuValueImport = 0;
  static const _menuValueSort = 1;
}

abstract class _ListItem implements SelectableItem {
  _ListItem({
    VoidCallback? onTap,
  }) : _myOnTap = onTap;

  @override
  get isTappable => _myOnTap != null;

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
  Widget buildWidget(BuildContext context) => _ButtonListItemView(
        icon: icon,
        label: label,
        onTap: _onTap,
        isShowIndicator: isShowIndicator,
      );

  final IconData icon;
  final String label;
  final bool isShowIndicator;

  final VoidCallback? _onTap;
}

class _ButtonListItemView extends StatelessWidget {
  const _ButtonListItemView({
    required this.icon,
    required this.label,
    this.onTap,
    this.isShowIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: M3.of(context).assistChip.enabled.container,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ActionChip(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          labelPadding: const EdgeInsetsDirectional.fromSTEB(8, 0, 0, 0),
          // specify icon size explicitly to workaround size flickering during
          // theme transition
          avatar: Icon(icon, size: 18),
          label: Row(
            children: [
              Expanded(child: Text(label)),
              if (isShowIndicator)
                Icon(
                  Icons.circle,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 8,
                ),
            ],
          ),
          onPressed: onTap,
        ),
      ),
    );
  }

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isShowIndicator;
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
      isShared: album.shares?.isNotEmpty == true,
    ).build(context);
  }

  final Account account;
  final Album album;
}

album_util.AlbumSort _getSortFromPref() {
  try {
    return album_util.AlbumSort.values[Pref().getHomeAlbumsSort()!];
  } catch (_) {
    // default
    return album_util.AlbumSort.dateDescending;
  }
}
