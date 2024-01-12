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
import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/np_api_util.dart';
import 'package:nc_photos/platform/features.dart' as features;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/theme/dimension.dart';
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
part 'home_collections/app_bar.dart';
part 'home_collections/bloc.dart';
part 'home_collections/state_event.dart';
part 'home_collections/type.dart';
part 'home_collections/view.dart';

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
        _BlocListener(
          listenWhen: (previous, current) =>
              previous.collections != current.collections,
          listener: (context, state) {
            _bloc.add(_TransformItems(state.collections));
          },
        ),
        _BlocListener(
          listenWhen: (previous, current) => previous.error != current.error,
          listener: (context, state) {
            if (state.error != null && isPageVisible()) {
              SnackBarManager().showSnackBar(SnackBar(
                content: Text(exception_util.toUserString(state.error!.error)),
                duration: k.snackBarDurationNormal,
              ));
            }
          },
        ),
        _BlocListener(
          listenWhen: (previous, current) =>
              previous.removeError != current.removeError,
          listener: (context, state) {
            if (state.removeError != null && isPageVisible()) {
              SnackBarManager().showSnackBar(SnackBar(
                content:
                    Text(L10n.global().removeCollectionsFailedNotification),
                duration: k.snackBarDurationNormal,
              ));
            }
          },
        ),
      ],
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              _bloc.add(const _ReloadCollections());
              await _bloc.stream.first;
            },
            child: CustomScrollView(
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
                        Navigator.of(context).pushNamed(
                            SharingBrowser.routeName,
                            arguments: SharingBrowserArguments(_bloc.account));
                      },
                      onEnhancedPhotosPressed: () {
                        Navigator.of(context).pushNamed(
                            EnhancedPhotoBrowser.routeName,
                            arguments:
                                const EnhancedPhotoBrowserArguments(null));
                      },
                      onArchivePressed: () {
                        Navigator.of(context)
                            .pushNamed(ArchiveBrowser.routeName);
                      },
                      onTrashbinPressed: () {
                        Navigator.of(context).pushNamed(
                            TrashbinBrowser.routeName,
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
                          arguments:
                              CollectionBrowserArguments(item.collection),
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: AppDimension.of(context).homeBottomAppBarHeight,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: NavigationBarBlurFilter(
              height: AppDimension.of(context).homeBottomAppBarHeight,
            ),
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
      // Right now we don't have a way to add photos inside the
      // CollectionBrowser, eventually we should add that and remove this
      // branching
      if (collection.isDynamicCollection) {
        // open the newly created collection
        unawaited(Navigator.of(context).pushNamed(
          CollectionBrowser.routeName,
          arguments: CollectionBrowserArguments(collection),
        ));
      }
    } catch (e, stacktrace) {
      _log.shout("[_onNewCollectionPressed] Failed", e, stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().createCollectionFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  late final _Bloc _bloc = context.read();
}

typedef _BlocBuilder = BlocBuilder<_Bloc, _State>;
typedef _BlocListener = BlocListener<_Bloc, _State>;
// typedef _BlocSelector<T> = BlocSelector<_Bloc, _State, T>;

extension on BuildContext {
  _Bloc get bloc => read<_Bloc>();
  _State get state => bloc.state;
  void addEvent(_Event event) => bloc.add(event);
}
