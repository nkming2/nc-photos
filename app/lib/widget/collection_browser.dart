import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:clock/clock.dart';
import 'package:copy_with/copy_with.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/asset.dart' as asset;
import 'package:nc_photos/bloc_util.dart';
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/controller/account_controller.dart';
import 'package:nc_photos/controller/collection_items_controller.dart';
import 'package:nc_photos/controller/collections_controller.dart';
import 'package:nc_photos/controller/pref_controller.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/download_handler.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection/adapter.dart';
import 'package:nc_photos/entity/collection/content_provider/album.dart';
import 'package:nc_photos/entity/collection_item.dart';
import 'package:nc_photos/entity/collection_item/new_item.dart';
import 'package:nc_photos/entity/collection_item/sorter.dart';
import 'package:nc_photos/entity/collection_item/util.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/flutter_util.dart' as flutter_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/np_api_util.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/use_case/archive_file.dart';
import 'package:nc_photos/use_case/collection/import_pending_shared_collection.dart';
import 'package:nc_photos/use_case/inflate_file_descriptor.dart';
import 'package:nc_photos/use_case/remove.dart';
import 'package:nc_photos/widget/album_share_outlier_browser.dart';
import 'package:nc_photos/widget/asset_icon.dart';
import 'package:nc_photos/widget/collection_picker.dart';
import 'package:nc_photos/widget/draggable_item_list.dart';
import 'package:nc_photos/widget/export_collection_dialog.dart';
import 'package:nc_photos/widget/fancy_option_picker.dart';
import 'package:nc_photos/widget/file_sharer.dart';
import 'package:nc_photos/widget/network_thumbnail.dart';
import 'package:nc_photos/widget/page_visibility_mixin.dart';
import 'package:nc_photos/widget/photo_list_item.dart';
import 'package:nc_photos/widget/photo_list_util.dart' as photo_list_util;
import 'package:nc_photos/widget/selectable_item_list.dart';
import 'package:nc_photos/widget/selection_app_bar.dart';
import 'package:nc_photos/widget/share_collection_dialog.dart';
import 'package:nc_photos/widget/shared_album_info_dialog.dart';
import 'package:nc_photos/widget/simple_input_dialog.dart';
import 'package:nc_photos/widget/viewer.dart';
import 'package:nc_photos/widget/zoom_menu_button.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';

part 'collection_browser.g.dart';
part 'collection_browser/app_bar.dart';
part 'collection_browser/bloc.dart';
part 'collection_browser/state_event.dart';
part 'collection_browser/type.dart';

typedef _BlocBuilder = BlocBuilder<_Bloc, _State>;

class CollectionBrowserArguments {
  const CollectionBrowserArguments(this.collection);

  final Collection collection;
}

/// Browse the content of a collection
class CollectionBrowser extends StatelessWidget {
  static const routeName = "/collection-browser";

  static Route buildRoute(CollectionBrowserArguments args) => MaterialPageRoute(
        builder: (context) => CollectionBrowser.fromArgs(args),
      );

  const CollectionBrowser({
    super.key,
    required this.collection,
  });

  CollectionBrowser.fromArgs(
    CollectionBrowserArguments args, {
    Key? key,
  }) : this(
          key: key,
          collection: args.collection,
        );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _Bloc(
        container: KiwiContainer().resolve(),
        account: context.read<AccountController>().account,
        collectionsController:
            context.read<AccountController>().collectionsController,
        collection: collection,
      ),
      child: const _WrappedCollectionBrowser(),
    );
  }

  final Collection collection;
}

class _WrappedCollectionBrowser extends StatefulWidget {
  const _WrappedCollectionBrowser();

  @override
  State<StatefulWidget> createState() => _WrappedCollectionBrowserState();
}

@npLog
class _WrappedCollectionBrowserState extends State<_WrappedCollectionBrowser>
    with RouteAware, PageVisibilityMixin {
  @override
  void initState() {
    super.initState();
    _bloc.add(const _LoadItems());

    if (_bloc.state.collection.shares.isNotEmpty &&
        _bloc.state.collection.contentProvider is CollectionAlbumProvider) {
      _showSharedAlbumInfoDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_bloc.state.isEditMode) {
          _bloc.add(const _CancelEdit());
          return false;
        } else if (_bloc.state.selectedItems.isNotEmpty) {
          _bloc.add(const _SetSelectedItems(items: {}));
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        body: MultiBlocListener(
          listeners: [
            BlocListener<_Bloc, _State>(
              listenWhen: (previous, current) =>
                  previous.items != current.items,
              listener: (context, state) {
                _bloc.add(_TransformItems(
                  items: state.items,
                ));
              },
            ),
            BlocListener<_Bloc, _State>(
              listenWhen: (previous, current) =>
                  previous.editItems != current.editItems,
              listener: (context, state) {
                if (state.editItems != null) {
                  _bloc.add(_TransformEditItems(
                    items: state.editItems!,
                  ));
                }
              },
            ),
            BlocListener<_Bloc, _State>(
              listenWhen: (previous, current) =>
                  previous.importResult != current.importResult,
              listener: (context, state) {
                if (state.importResult != null) {
                  Navigator.of(context).pushReplacementNamed(
                    CollectionBrowser.routeName,
                    arguments: CollectionBrowserArguments(state.importResult!),
                  );
                }
              },
            ),
            BlocListener<_Bloc, _State>(
              listenWhen: (previous, current) =>
                  previous.error != current.error,
              listener: (context, state) {
                if (state.error != null && isPageVisible()) {
                  SnackBarManager().showSnackBar(SnackBar(
                    content:
                        Text(exception_util.toUserString(state.error!.error)),
                    duration: k.snackBarDurationNormal,
                  ));
                }
              },
            ),
            BlocListener<_Bloc, _State>(
              listenWhen: (previous, current) =>
                  previous.message != current.message,
              listener: (context, state) {
                if (state.message != null && isPageVisible()) {
                  SnackBarManager().showSnackBar(SnackBar(
                    content: Text(state.message!),
                    duration: k.snackBarDurationNormal,
                  ));
                }
              },
            ),
          ],
          child: Stack(
            fit: StackFit.expand,
            children: [
              Listener(
                onPointerMove: (event) => _onPointerMove(context, event),
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    _BlocBuilder(
                      buildWhen: (previous, current) =>
                          previous.selectedItems.isEmpty !=
                              current.selectedItems.isEmpty ||
                          previous.isEditMode != current.isEditMode,
                      builder: (context, state) {
                        if (state.isEditMode) {
                          return const _EditAppBar();
                        } else if (state.selectedItems.isNotEmpty) {
                          return const _SelectionAppBar();
                        } else {
                          return const _AppBar();
                        }
                      },
                    ),
                    SliverToBoxAdapter(
                      child: _BlocBuilder(
                        buildWhen: (previous, current) =>
                            previous.isLoading != current.isLoading,
                        builder: (context, state) => state.isLoading
                            ? const LinearProgressIndicator()
                            : const SizedBox(height: 4),
                      ),
                    ),
                    _BlocBuilder(
                      buildWhen: (previous, current) =>
                          previous.isEditMode != current.isEditMode,
                      builder: (context, state) {
                        if (!state.isEditMode) {
                          return const _ContentList();
                        } else {
                          if (context
                              .read<_Bloc>()
                              .isCollectionCapabilityPermitted(
                                  CollectionCapability.manualSort)) {
                            return const _EditContentList();
                          } else {
                            return const _UnmodifiableEditContentList();
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              _BlocBuilder(
                buildWhen: (previous, current) =>
                    previous.isEditBusy != current.isEditBusy,
                builder: (context, state) {
                  if (state.isEditBusy) {
                    return Container(
                      color: Colors.black.withOpacity(.5),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPointerMove(BuildContext context, PointerMoveEvent event) {
    final bloc = context.read<_Bloc>();
    if (!bloc.state.isDragging) {
      return;
    }
    if (event.position.dy >= MediaQuery.of(context).size.height - 100) {
      // near bottom of screen
      if (_isDragScrollingDown == true) {
        return;
      }
      // using an arbitrary big number to save time needed to calculate the
      // actual extent
      const maxExtent = 1000000000.0;
      _log.fine("[_onPointerMove] Begin scrolling down");
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
      _log.fine("[_onPointerMove] Begin scrolling up");
      if (_scrollController.offset > 0) {
        _scrollController.animateTo(0,
            duration: Duration(
                milliseconds: (_scrollController.offset * 1.6).round()),
            curve: Curves.linear);
        _isDragScrollingDown = false;
      }
    } else if (_isDragScrollingDown != null) {
      _log.fine("[_onPointerMove] Stop scrolling");
      _scrollController.jumpTo(_scrollController.offset);
      _isDragScrollingDown = null;
    }
  }

  Future<void> _showSharedAlbumInfoDialog() async {
    final pref = KiwiContainer().resolve<DiContainer>().pref;
    if (!pref.hasShownSharedAlbumInfoOr(false)) {
      return showDialog(
        context: context,
        builder: (_) => const SharedAlbumInfoDialog(),
        barrierDismissible: false,
      );
    }
  }

  late final _bloc = context.read<_Bloc>();
  final _scrollController = ScrollController();
  bool? _isDragScrollingDown;
}

class _ContentList extends StatelessWidget {
  const _ContentList();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<_Bloc>();
    return StreamBuilder<int>(
      stream: context.read<PrefController>().albumBrowserZoomLevel,
      initialData: context.read<PrefController>().albumBrowserZoomLevel.value,
      builder: (_, zoomLevel) {
        if (zoomLevel.hasError) {
          bloc.add(
              _SetMessage(L10n.global().writePreferenceFailureNotification));
        }
        return _BlocBuilder(
          buildWhen: (previous, current) =>
              previous.collection != current.collection ||
              previous.transformedItems != current.transformedItems ||
              previous.selectedItems != current.selectedItems,
          builder: (context, state) {
            return SelectableItemList<_Item>(
              maxCrossAxisExtent: photo_list_util
                  .getThumbSize(zoomLevel.requireData)
                  .toDouble(),
              items: state.transformedItems,
              itemBuilder: (context, _, item) => item.buildWidget(context),
              staggeredTileBuilder: (_, item) => item.staggeredTile,
              selectedItems: state.selectedItems,
              onSelectionChange: (_, selected) {
                bloc.add(_SetSelectedItems(items: selected.cast()));
              },
              onItemTap: (context, index, _) {
                final actualIndex = index -
                    state.transformedItems
                        .sublist(0, index)
                        .where((e) => e is! _ActualItem)
                        .length;
                Navigator.of(context).pushNamed(
                  Viewer.routeName,
                  arguments: ViewerArguments(
                    bloc.account,
                    state.transformedItems
                        .whereType<_FileItem>()
                        .map((e) => e.file)
                        .toList(),
                    actualIndex,
                    fromCollection: ViewerCollectionData(
                      state.collection,
                      state.transformedItems
                          .whereType<_ActualItem>()
                          .map((e) => e.original)
                          .toList(),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _EditContentList extends StatelessWidget {
  const _EditContentList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: context.read<PrefController>().albumBrowserZoomLevel,
      initialData: context.read<PrefController>().albumBrowserZoomLevel.value,
      builder: (_, zoomLevel) {
        if (zoomLevel.hasError) {
          context.read<_Bloc>().add(
              _SetMessage(L10n.global().writePreferenceFailureNotification));
        }
        return _BlocBuilder(
          buildWhen: (previous, current) =>
              previous.editTransformedItems != current.editTransformedItems,
          builder: (context, state) {
            if (context.read<_Bloc>().isCollectionCapabilityPermitted(
                CollectionCapability.manualSort)) {
              return DraggableItemList<_Item>(
                maxCrossAxisExtent: photo_list_util
                    .getThumbSize(zoomLevel.requireData)
                    .toDouble(),
                items: state.editTransformedItems ?? state.transformedItems,
                itemBuilder: (context, _, item) => item.buildWidget(context),
                itemDragFeedbackBuilder: (context, _, item) =>
                    item.buildDragFeedbackWidget(context),
                staggeredTileBuilder: (_, item) => item.staggeredTile,
                onDragResult: (results) {
                  context.read<_Bloc>().add(_EditManualSort(results));
                },
                onDraggingChanged: (value) {
                  context.read<_Bloc>().add(_SetDragging(value));
                },
              );
            } else {
              return SelectableItemList<_Item>(
                maxCrossAxisExtent: photo_list_util
                    .getThumbSize(zoomLevel.requireData)
                    .toDouble(),
                items: state.editTransformedItems ?? state.transformedItems,
                itemBuilder: (context, _, item) => item.buildWidget(context),
                staggeredTileBuilder: (_, item) => item.staggeredTile,
              );
            }
          },
        );
      },
    );
  }
}

/// Unmodifiable content list under edit mode
class _UnmodifiableEditContentList extends StatelessWidget {
  const _UnmodifiableEditContentList();

  @override
  Widget build(BuildContext context) {
    return SliverIgnorePointer(
      ignoring: true,
      sliver: SliverOpacity(
        opacity: .25,
        sliver: StreamBuilder<int>(
          stream: context.read<PrefController>().albumBrowserZoomLevel,
          initialData:
              context.read<PrefController>().albumBrowserZoomLevel.value,
          builder: (_, zoomLevel) {
            if (zoomLevel.hasError) {
              context.read<_Bloc>().add(_SetMessage(
                  L10n.global().writePreferenceFailureNotification));
            }
            return _BlocBuilder(
              buildWhen: (previous, current) =>
                  previous.editTransformedItems != current.editTransformedItems,
              builder: (context, state) {
                return SelectableItemList<_Item>(
                  maxCrossAxisExtent: photo_list_util
                      .getThumbSize(zoomLevel.requireData)
                      .toDouble(),
                  items: state.editTransformedItems ?? state.transformedItems,
                  itemBuilder: (context, _, item) => item.buildWidget(context),
                  staggeredTileBuilder: (_, item) => item.staggeredTile,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
