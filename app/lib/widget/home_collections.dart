import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:copy_with/copy_with.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc_util.dart';
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/controller/account_controller.dart';
import 'package:nc_photos/controller/collections_controller.dart';
import 'package:nc_photos/controller/pref_controller.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection/content_provider/album.dart';
import 'package:nc_photos/entity/collection/content_provider/nc_album.dart';
import 'package:nc_photos/entity/collection/util.dart' as collection_util;
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/np_api_util.dart';
import 'package:nc_photos/platform/features.dart' as features;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/album_importer.dart';
import 'package:nc_photos/widget/archive_browser.dart';
import 'package:nc_photos/widget/collection_browser.dart';
import 'package:nc_photos/widget/collection_grid_item.dart';
import 'package:nc_photos/widget/enhanced_photo_browser.dart';
import 'package:nc_photos/widget/fancy_option_picker.dart';
import 'package:nc_photos/widget/home_app_bar.dart';
import 'package:nc_photos/widget/navigation_bar_blur_filter.dart';
import 'package:nc_photos/widget/new_collection_dialog.dart';
import 'package:nc_photos/widget/page_visibility_mixin.dart';
import 'package:nc_photos/widget/selectable_item_list.dart';
import 'package:nc_photos/widget/selection_app_bar.dart';
import 'package:nc_photos/widget/sharing_browser.dart';
import 'package:nc_photos/widget/trashbin_browser.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';

part 'home_collections.g.dart';
part 'home_collections/bloc.dart';
part 'home_collections/state_event.dart';
part 'home_collections/type.dart';

typedef _BlocBuilder = BlocBuilder<_Bloc, _State>;

/// Show and manage a list of [Collection]s
class HomeCollections extends StatelessWidget {
  const HomeCollections({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _Bloc(
        account: context.read<AccountController>().account,
        controller: context.read<AccountController>().collectionsController,
        prefController: context.read(),
      ),
      child: const _WrappedHomeCollections(),
    );
  }
}

class _WrappedHomeCollections extends StatefulWidget {
  const _WrappedHomeCollections();

  @override
  State<StatefulWidget> createState() => _WrappedHomeCollectionsState();
}

@npLog
class _WrappedHomeCollectionsState extends State<_WrappedHomeCollections>
    with RouteAware, PageVisibilityMixin {
  @override
  void initState() {
    super.initState();
    _bloc.add(const _LoadCollections());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<_Bloc, _State>(
          listenWhen: (previous, current) =>
              previous.collections != current.collections,
          listener: (context, state) {
            _bloc.add(_TransformItems(state.collections));
          },
        ),
        BlocListener<_Bloc, _State>(
          listenWhen: (previous, current) =>
              previous.loadError != current.loadError,
          listener: (context, state) {
            if (state.loadError != null && isPageVisible()) {
              SnackBarManager().showSnackBar(SnackBar(
                content:
                    Text(exception_util.toUserString(state.loadError!.error)),
                duration: k.snackBarDurationNormal,
              ));
            }
          },
        ),
        BlocListener<_Bloc, _State>(
          listenWhen: (previous, current) =>
              previous.removeError != current.removeError,
          listener: (context, state) {
            if (state.removeError != null && isPageVisible()) {
              SnackBarManager().showSnackBar(const SnackBar(
                content: Text('Failed to remove some collections'),
                duration: k.snackBarDurationNormal,
              ));
            }
          },
        ),
      ],
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _BlocBuilder(
                buildWhen: (previous, current) =>
                    previous.selectedItems.isEmpty !=
                    current.selectedItems.isEmpty,
                builder: (context, state) => state.selectedItems.isEmpty
                    ? const _AppBar()
                    : const _SelectionAppBar(),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                sliver: _BlocBuilder(
                  buildWhen: (previous, current) =>
                      previous.selectedItems.isEmpty !=
                      current.selectedItems.isEmpty,
                  builder: (context, state) => _ButtonGrid(
                    account: _bloc.account,
                    isEnabled: state.selectedItems.isEmpty,
                    onSharingPressed: () {
                      Navigator.of(context).pushNamed(SharingBrowser.routeName,
                          arguments: SharingBrowserArguments(_bloc.account));
                    },
                    onEnhancedPhotosPressed: () {
                      Navigator.of(context).pushNamed(
                          EnhancedPhotoBrowser.routeName,
                          arguments: const EnhancedPhotoBrowserArguments(null));
                    },
                    onArchivePressed: () {
                      Navigator.of(context).pushNamed(ArchiveBrowser.routeName,
                          arguments: ArchiveBrowserArguments(_bloc.account));
                    },
                    onTrashbinPressed: () {
                      Navigator.of(context).pushNamed(TrashbinBrowser.routeName,
                          arguments: TrashbinBrowserArguments(_bloc.account));
                    },
                    onNewCollectionPressed: () {
                      _onNewCollectionPressed(context);
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 8),
              ),
              _BlocBuilder(
                buildWhen: (previous, current) =>
                    previous.transformedItems != current.transformedItems ||
                    previous.selectedItems != current.selectedItems,
                builder: (context, state) => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  sliver: SelectableItemList(
                    maxCrossAxisExtent: 256,
                    childBorderRadius: BorderRadius.zero,
                    indicatorAlignment: const Alignment(-.92, -.92),
                    items: state.transformedItems,
                    itemBuilder: (_, __, metadata) {
                      final item = metadata as _Item;
                      return _ItemView(
                        account: _bloc.account,
                        item: item,
                      );
                    },
                    staggeredTileBuilder: (_, __) =>
                        const StaggeredTile.count(1, 1),
                    selectedItems: state.selectedItems,
                    onSelectionChange: (_, selected) {
                      _bloc.add(_SetSelectedItems(items: selected.cast()));
                    },
                    onItemTap: (context, _, metadata) {
                      final item = metadata as _Item;
                      Navigator.of(context).pushNamed(
                        CollectionBrowser.routeName,
                        arguments: CollectionBrowserArguments(item.collection),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: NavigationBarTheme.of(context).height,
                ),
              ),
            ],
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: NavigationBarBlurFilter(),
          ),
        ],
      ),
    );
  }

  Future<void> _onNewCollectionPressed(BuildContext context) async {
    try {
      final collection = await showDialog<Collection>(
        context: context,
        builder: (_) => NewCollectionDialog(
          account: _bloc.account,
        ),
      );
      if (collection == null) {
        return;
      }
      // open the newly created collection
      unawaited(Navigator.of(context).pushNamed(
        CollectionBrowser.routeName,
        arguments: CollectionBrowserArguments(collection),
      ));
    } catch (e, stacktrace) {
      _log.shout("[_onNewCollectionPressed] Failed", e, stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().createAlbumFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  late final _Bloc _bloc = context.read();
}

class _AppBar extends StatelessWidget {
  const _AppBar();

  @override
  Widget build(BuildContext context) {
    return _BlocBuilder(
      buildWhen: (previous, current) => previous.isLoading != current.isLoading,
      builder: (context, state) => HomeSliverAppBar(
        account: context.read<_Bloc>().account,
        isShowProgressIcon: state.isLoading,
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
      ),
    );
  }

  Future<void> _onSortPressed(BuildContext context) async {
    final sort = context.read<_Bloc>().state.sort;
    final result = await showDialog<collection_util.CollectionSort>(
      context: context,
      builder: (context) => FancyOptionPicker(
        title: L10n.global().sortOptionDialogTitle,
        items: [
          FancyOptionPickerItem(
            label: L10n.global().sortOptionTimeDescendingLabel,
            isSelected: sort == collection_util.CollectionSort.dateDescending,
            onSelect: () {
              Navigator.of(context)
                  .pop(collection_util.CollectionSort.dateDescending);
            },
          ),
          FancyOptionPickerItem(
            label: L10n.global().sortOptionTimeAscendingLabel,
            isSelected: sort == collection_util.CollectionSort.dateAscending,
            onSelect: () {
              Navigator.of(context)
                  .pop(collection_util.CollectionSort.dateAscending);
            },
          ),
          FancyOptionPickerItem(
            label: L10n.global().sortOptionAlbumNameLabel,
            isSelected: sort == collection_util.CollectionSort.nameAscending,
            onSelect: () {
              Navigator.of(context)
                  .pop(collection_util.CollectionSort.nameAscending);
            },
          ),
          FancyOptionPickerItem(
            label: L10n.global().sortOptionAlbumNameDescendingLabel,
            isSelected: sort == collection_util.CollectionSort.nameDescending,
            onSelect: () {
              Navigator.of(context)
                  .pop(collection_util.CollectionSort.nameDescending);
            },
          ),
        ],
      ),
    );
    if (result == null) {
      return;
    }
    context.read<_Bloc>().add(_SetCollectionSort(result));
  }

  void _onImportPressed(BuildContext context) {
    Navigator.of(context).pushNamed(AlbumImporter.routeName,
        arguments: AlbumImporterArguments(context.read<_Bloc>().account));
  }

  static const _menuValueImport = 0;
  static const _menuValueSort = 1;
}

@npLog
class _SelectionAppBar extends StatelessWidget {
  const _SelectionAppBar();

  @override
  Widget build(BuildContext context) {
    return _BlocBuilder(
      buildWhen: (previous, current) =>
          previous.selectedItems != current.selectedItems,
      builder: (context, state) => SelectionAppBar(
        count: state.selectedItems.length,
        onClosePressed: () {
          context.read<_Bloc>().add(const _SetSelectedItems(items: {}));
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: L10n.global().deleteTooltip,
            onPressed: () {
              context.read<_Bloc>().add(const _RemoveSelectedItems());
            },
          ),
        ],
      ),
    );
  }
}

class _ButtonGrid extends StatelessWidget {
  const _ButtonGrid({
    required this.account,
    required this.isEnabled,
    this.onSharingPressed,
    this.onEnhancedPhotosPressed,
    this.onArchivePressed,
    this.onTrashbinPressed,
    this.onNewCollectionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SliverStaggeredGrid.extent(
      maxCrossAxisExtent: 256,
      staggeredTiles: List.filled(5, const StaggeredTile.fit(1)),
      children: [
        _ButtonGridItemView(
          icon: Icons.share_outlined,
          label: L10n.global().collectionSharingLabel,
          isShowIndicator: AccountPref.of(account).hasNewSharedAlbumOr(),
          isEnabled: isEnabled,
          onTap: () {
            onSharingPressed?.call();
          },
        ),
        if (features.isSupportEnhancement)
          _ButtonGridItemView(
            icon: Icons.auto_fix_high_outlined,
            label: L10n.global().collectionEditedPhotosLabel,
            isEnabled: isEnabled,
            onTap: () {
              onEnhancedPhotosPressed?.call();
            },
          ),
        _ButtonGridItemView(
          icon: Icons.archive_outlined,
          label: L10n.global().albumArchiveLabel,
          isEnabled: isEnabled,
          onTap: () {
            onArchivePressed?.call();
          },
        ),
        _ButtonGridItemView(
          icon: Icons.delete_outlined,
          label: L10n.global().albumTrashLabel,
          isEnabled: isEnabled,
          onTap: () {
            onTrashbinPressed?.call();
          },
        ),
        _ButtonGridItemView(
          icon: Icons.add,
          label: L10n.global().createCollectionTooltip,
          isEnabled: isEnabled,
          onTap: () {
            onNewCollectionPressed?.call();
          },
        ),
      ],
    );
  }

  final Account account;
  final bool isEnabled;
  final VoidCallback? onSharingPressed;
  final VoidCallback? onEnhancedPhotosPressed;
  final VoidCallback? onArchivePressed;
  final VoidCallback? onTrashbinPressed;
  final VoidCallback? onNewCollectionPressed;
}

class _ButtonGridItemView extends StatelessWidget {
  const _ButtonGridItemView({
    required this.icon,
    required this.label,
    this.isShowIndicator = false,
    required this.isEnabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ActionChip(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: const EdgeInsetsDirectional.fromSTEB(8, 0, 0, 0),
        // specify icon size explicitly to workaround size flickering during
        // theme transition
        avatar: Icon(icon, size: 18),
        label: Row(
          children: [
            Expanded(
              child: Text(label),
            ),
            if (isShowIndicator)
              Icon(
                Icons.circle,
                color: Theme.of(context).colorScheme.tertiary,
                size: 8,
              ),
          ],
        ),
        onPressed: isEnabled ? onTap : null,
      ),
    );
  }

  final IconData icon;
  final String label;
  final bool isShowIndicator;
  final bool isEnabled;
  final VoidCallback? onTap;
}

class _ItemView extends StatelessWidget {
  const _ItemView({
    required this.account,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    Widget? icon;
    switch (item.itemType) {
      case _ItemType.ncAlbum:
        icon = const ImageIcon(AssetImage("assets/ic_nextcloud_album.png"));
        break;
      case _ItemType.album:
        icon = null;
        break;
      case _ItemType.tagAlbum:
        icon = const Icon(Icons.local_offer);
        break;
      case _ItemType.dirAlbum:
        icon = const Icon(Icons.folder);
        break;
    }
    return CollectionGridItem(
      cover: _CollectionCover(
        account: account,
        url: item.coverUrl,
      ),
      title: item.name,
      subtitle: item.subtitle,
      icon: icon,
    );
  }

  final Account account;
  final _Item item;
}

class _CollectionCover extends StatelessWidget {
  const _CollectionCover({
    required this.account,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: Theme.of(context).listPlaceholderBackgroundColor,
        constraints: const BoxConstraints.expand(),
        child: url != null
            ? FittedBox(
                clipBehavior: Clip.hardEdge,
                fit: BoxFit.cover,
                child: CachedNetworkImage(
                  cacheManager: CoverCacheManager.inst,
                  imageUrl: url!,
                  httpHeaders: {
                    "Authorization":
                        AuthUtil.fromAccount(account).toHeaderValue(),
                  },
                  fadeInDuration: const Duration(),
                  filterQuality: FilterQuality.high,
                  errorWidget: (context, url, error) {
                    // just leave it empty
                    return Container();
                  },
                  imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
                ),
              )
            : Icon(
                Icons.panorama,
                color: Theme.of(context).listPlaceholderForegroundColor,
                size: 88,
              ),
      ),
    );
  }

  final Account account;
  final String? url;
}
