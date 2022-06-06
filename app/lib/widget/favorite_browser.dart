import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/list_favorite.dart';
import 'package:nc_photos/compute_queue.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/download_handler.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/language_util.dart' as language_util;
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/share_handler.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/builder/photo_list_item_builder.dart';
import 'package:nc_photos/widget/empty_list_indicator.dart';
import 'package:nc_photos/widget/handler/add_selection_to_album_handler.dart';
import 'package:nc_photos/widget/handler/archive_selection_handler.dart';
import 'package:nc_photos/widget/handler/remove_selection_handler.dart';
import 'package:nc_photos/widget/photo_list_item.dart';
import 'package:nc_photos/widget/photo_list_util.dart' as photo_list_util;
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/selection_app_bar.dart';
import 'package:nc_photos/widget/viewer.dart';
import 'package:nc_photos/widget/zoom_menu_button.dart';

class FavoriteBrowserArguments {
  FavoriteBrowserArguments(this.account);

  final Account account;
}

class FavoriteBrowser extends StatefulWidget {
  static const routeName = "/favorite-browser";

  static Route buildRoute(FavoriteBrowserArguments args) => MaterialPageRoute(
        builder: (context) => FavoriteBrowser.fromArgs(args),
      );

  const FavoriteBrowser({
    Key? key,
    required this.account,
  }) : super(key: key);

  FavoriteBrowser.fromArgs(FavoriteBrowserArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
        );

  @override
  createState() => _FavoriteBrowserState();

  final Account account;
}

class _FavoriteBrowserState extends State<FavoriteBrowser>
    with SelectableItemStreamListMixin<FavoriteBrowser> {
  @override
  initState() {
    super.initState();
    _initBloc();
    _thumbZoomLevel = Pref().getAlbumBrowserZoomLevelOr(0);
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: BlocListener<ListFavoriteBloc, ListFavoriteBlocState>(
          bloc: _bloc,
          listener: (context, state) => _onStateChange(context, state),
          child: BlocBuilder<ListFavoriteBloc, ListFavoriteBlocState>(
            bloc: _bloc,
            builder: (context, state) => _buildContent(context, state),
          ),
        ),
      ),
    );
  }

  @override
  onItemTap(SelectableItem item, int index) {
    item.as<PhotoListFileItem>()?.run((fileItem) {
      Navigator.pushNamed(
        context,
        Viewer.routeName,
        arguments:
            ViewerArguments(widget.account, _backingFiles, fileItem.fileIndex),
      );
    });
  }

  void _initBloc() {
    if (_bloc.state is ListFavoriteBlocInit) {
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

  Widget _buildContent(BuildContext context, ListFavoriteBlocState state) {
    if (state is ListFavoriteBlocSuccess &&
        !_buildItemQueue.isProcessing &&
        itemStreamListItems.isEmpty) {
      return Column(
        children: [
          AppBar(
            title: Text(L10n.global().collectionFavoritesLabel),
            elevation: 0,
          ),
          Expanded(
            child: EmptyListIndicator(
              icon: Icons.star_border,
              text: L10n.global().listEmptyText,
            ),
          ),
        ],
      );
    } else {
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
              child: RefreshIndicator(
                backgroundColor: Colors.grey[100],
                onRefresh: () async {
                  _onRefreshSelected();
                  await _waitRefresh();
                },
                child: CustomScrollView(
                  slivers: [
                    _buildAppBar(context),
                    buildItemStreamList(
                      maxCrossAxisExtent: _thumbSize.toDouble(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (state is ListFavoriteBlocLoading || _buildItemQueue.isProcessing)
            const Align(
              alignment: Alignment.bottomCenter,
              child: LinearProgressIndicator(),
            ),
        ],
      );
    }
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
          icon: const Icon(Icons.share),
          tooltip: L10n.global().shareTooltip,
          onPressed: () => _onSelectionSharePressed(context),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: L10n.global().addToAlbumTooltip,
          onPressed: () => _onSelectionAddToAlbumPressed(context),
        ),
        PopupMenuButton<_SelectionMenuOption>(
          tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _SelectionMenuOption.download,
              child: Text(L10n.global().downloadTooltip),
            ),
            PopupMenuItem(
              value: _SelectionMenuOption.archive,
              child: Text(L10n.global().archiveTooltip),
            ),
            PopupMenuItem(
              value: _SelectionMenuOption.delete,
              child: Text(L10n.global().deleteTooltip),
            ),
          ],
          onSelected: (option) => _onSelectionMenuSelected(context, option),
        ),
      ],
    );
  }

  Widget _buildNormalAppBar(BuildContext context) {
    return SliverAppBar(
      title: Text(L10n.global().collectionFavoritesLabel),
      floating: true,
      actions: [
        ZoomMenuButton(
          initialZoom: _thumbZoomLevel,
          minZoom: -1,
          maxZoom: 2,
          onZoomChanged: (value) {
            _setThumbZoomLevel(value.round());
            Pref().setHomePhotosZoomLevel(_thumbZoomLevel);
          },
        ),
      ],
    );
  }

  void _onStateChange(BuildContext context, ListFavoriteBlocState state) {
    if (state is ListFavoriteBlocInit) {
      itemStreamListItems = [];
    } else if (state is ListFavoriteBlocSuccess ||
        state is ListFavoriteBlocLoading) {
      _transformItems(state.items);
    } else if (state is ListFavoriteBlocFailure) {
      _transformItems(state.items);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(state.exception)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  void _onRefreshSelected() {
    _reqRefresh();
  }

  void _onSelectionMenuSelected(
      BuildContext context, _SelectionMenuOption option) {
    switch (option) {
      case _SelectionMenuOption.archive:
        _onSelectionArchivePressed(context);
        break;
      case _SelectionMenuOption.delete:
        _onSelectionDeletePressed(context);
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
        .whereType<PhotoListFileItem>()
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

  Future<void> _onSelectionAddToAlbumPressed(BuildContext context) {
    return AddSelectionToAlbumHandler()(
      context: context,
      account: widget.account,
      selectedFiles: selectedListItems
          .whereType<PhotoListFileItem>()
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

  void _onSelectionDownloadPressed() {
    final selected = selectedListItems
        .whereType<PhotoListFileItem>()
        .map((e) => e.file)
        .toList();
    DownloadHandler().downloadFiles(widget.account, selected);
    setState(() {
      clearSelectedItems();
    });
  }

  Future<void> _onSelectionArchivePressed(BuildContext context) async {
    final selectedFiles = selectedListItems
        .whereType<PhotoListFileItem>()
        .map((e) => e.file)
        .toList();
    setState(() {
      clearSelectedItems();
    });
    await ArchiveSelectionHandler(KiwiContainer().resolve<DiContainer>())(
      account: widget.account,
      selectedFiles: selectedFiles,
    );
  }

  Future<void> _onSelectionDeletePressed(BuildContext context) async {
    final selectedFiles = selectedListItems
        .whereType<PhotoListFileItem>()
        .map((e) => e.file)
        .toList();
    setState(() {
      clearSelectedItems();
    });
    await RemoveSelectionHandler()(
      account: widget.account,
      selectedFiles: selectedFiles,
      isMoveToTrash: true,
    );
  }

  void _transformItems(List<File> files, {bool isSorted = false}) {
    _buildItemQueue.addJob(
      PhotoListItemBuilderArguments(
        widget.account,
        files,
        sorter: isSorted ? null : photoListFileDateTimeSorter,
        grouper: PhotoListFileDateGrouper(isMonthOnly: _thumbZoomLevel < 0),
        locale: language_util.getSelectedLocale() ??
            PlatformDispatcher.instance.locale,
      ),
      buildPhotoListItem,
      (result) {
        if (mounted) {
          setState(() {
            _backingFiles = result.backingFiles;
            itemStreamListItems = result.listItems;
          });
        }
      },
    );
  }

  void _reqQuery() {
    _bloc.add(ListFavoriteBlocQuery(widget.account));
  }

  void _reqRefresh() {
    _bloc.add(ListFavoriteBlocQuery(widget.account));
  }

  Future<void> _waitRefresh() async {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      if (_bloc.state is! ListFavoriteBlocLoading) {
        return;
      }
    }
  }

  void _setThumbZoomLevel(int level) {
    final prevLevel = _thumbZoomLevel;
    if ((prevLevel >= 0) != (level >= 0)) {
      _thumbZoomLevel = level;
      _transformItems(_backingFiles, isSorted: true);
    } else {
      setState(() {
        _thumbZoomLevel = level;
      });
    }
  }

  late final _bloc = ListFavoriteBloc.of(widget.account);

  var _backingFiles = <File>[];

  final _buildItemQueue =
      ComputeQueue<PhotoListItemBuilderArguments, PhotoListItemBuilderResult>();

  var _thumbZoomLevel = 0;
  int get _thumbSize => photo_list_util.getThumbSize(_thumbZoomLevel);

  static final _log = Logger("widget.archive_browser._FavoriteBrowserState");
}

enum _SelectionMenuOption {
  archive,
  delete,
  download,
}
