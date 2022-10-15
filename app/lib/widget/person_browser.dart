import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/list_face_file.dart';
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/compute_queue.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/download_handler.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/language_util.dart' as language_util;
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/share_handler.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/throttler.dart';
import 'package:nc_photos/widget/builder/photo_list_item_builder.dart';
import 'package:nc_photos/widget/handler/add_selection_to_album_handler.dart';
import 'package:nc_photos/widget/handler/archive_selection_handler.dart';
import 'package:nc_photos/widget/handler/remove_selection_handler.dart';
import 'package:nc_photos/widget/photo_list_item.dart';
import 'package:nc_photos/widget/photo_list_util.dart' as photo_list_util;
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/selection_app_bar.dart';
import 'package:nc_photos/widget/viewer.dart';
import 'package:nc_photos/widget/zoom_menu_button.dart';

class PersonBrowserArguments {
  PersonBrowserArguments(this.account, this.person);

  final Account account;
  final Person person;
}

/// Show a list of all faces associated with this person
class PersonBrowser extends StatefulWidget {
  static const routeName = "/person-browser";

  static Route buildRoute(PersonBrowserArguments args) => MaterialPageRoute(
        builder: (context) => PersonBrowser.fromArgs(args),
      );

  const PersonBrowser({
    Key? key,
    required this.account,
    required this.person,
  }) : super(key: key);

  PersonBrowser.fromArgs(PersonBrowserArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
          person: args.person,
        );

  @override
  createState() => _PersonBrowserState();

  final Account account;
  final Person person;
}

class _PersonBrowserState extends State<PersonBrowser>
    with SelectableItemStreamListMixin<PersonBrowser> {
  _PersonBrowserState() {
    final c = KiwiContainer().resolve<DiContainer>();
    assert(require(c));
    assert(ListFaceFileBloc.require(c));
    _c = c;
  }

  static bool require(DiContainer c) => true;

  @override
  initState() {
    super.initState();
    _initBloc();
    _thumbZoomLevel = Pref().getAlbumBrowserZoomLevelOr(0);

    _filePropertyUpdatedListener.begin();
  }

  @override
  dispose() {
    _filePropertyUpdatedListener.end();
    super.dispose();
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: BlocListener<ListFaceFileBloc, ListFaceFileBlocState>(
          bloc: _bloc,
          listener: (context, state) => _onStateChange(context, state),
          child: BlocBuilder<ListFaceFileBloc, ListFaceFileBlocState>(
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
    _log.info("[_initBloc] Initialize bloc");
    _reqQuery();
  }

  Widget _buildContent(BuildContext context, ListFaceFileBlocState state) {
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
            _buildAppBar(context, state),
            if (state is ListFaceFileBlocLoading ||
                _buildItemQueue.isProcessing)
              const SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.center,
                  child: LinearProgressIndicator(),
                ),
              ),
            buildItemStreamList(
              maxCrossAxisExtent: _thumbSize.toDouble(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ListFaceFileBlocState state) {
    if (isSelectionMode) {
      return _buildSelectionAppBar(context);
    } else {
      return _buildNormalAppBar(context, state);
    }
  }

  Widget _buildNormalAppBar(BuildContext context, ListFaceFileBlocState state) {
    return SliverAppBar(
      floating: true,
      titleSpacing: 0,
      title: Row(
        children: [
          SizedBox(
            height: 40,
            width: 40,
            child: _buildFaceImage(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.person.name,
                  style: TextStyle(
                    color: AppTheme.getPrimaryTextColor(context),
                  ),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                ),
                if (state is! ListFaceFileBlocLoading &&
                    !_buildItemQueue.isProcessing)
                  Text(
                    L10n.global().personPhotoCountText(_backingFiles.length),
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      // ),
      actions: [
        ZoomMenuButton(
          initialZoom: _thumbZoomLevel,
          minZoom: 0,
          maxZoom: 2,
          onZoomChanged: (value) {
            setState(() {
              _thumbZoomLevel = value.round();
            });
            Pref().setAlbumBrowserZoomLevel(_thumbZoomLevel);
          },
        ),
      ],
    );
  }

  Widget _buildFaceImage(BuildContext context) {
    Widget cover;
    try {
      cover = FittedBox(
        clipBehavior: Clip.hardEdge,
        fit: BoxFit.cover,
        child: CachedNetworkImage(
          cacheManager: ThumbnailCacheManager.inst,
          imageUrl: api_util.getFacePreviewUrl(
              widget.account, widget.person.thumbFaceId,
              size: k.faceThumbSize),
          httpHeaders: {
            "Authorization": Api.getAuthorizationHeaderValue(widget.account),
          },
          fadeInDuration: const Duration(),
          filterQuality: FilterQuality.high,
          errorWidget: (context, url, error) {
            // just leave it empty
            return Container();
          },
          imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
        ),
      );
    } catch (_) {
      cover = Icon(
        Icons.person,
        color: Colors.white.withOpacity(.8),
        size: 24,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(64),
      child: Container(
        color: AppTheme.getListItemBackgroundColor(context),
        constraints: const BoxConstraints.expand(),
        child: cover,
      ),
    );
  }

  Widget _buildSelectionAppBar(BuildContext context) {
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
          onPressed: () {
            _onSelectionSharePressed(context);
          },
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: L10n.global().addToAlbumTooltip,
          onPressed: () {
            _onSelectionAddToAlbumPressed(context);
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
              value: _SelectionMenuOption.archive,
              child: Text(L10n.global().archiveTooltip),
            ),
            PopupMenuItem(
              value: _SelectionMenuOption.delete,
              child: Text(L10n.global().deleteTooltip),
            ),
          ],
          onSelected: (option) {
            _onSelectionMenuSelected(context, option);
          },
        ),
      ],
    );
  }

  void _onStateChange(BuildContext context, ListFaceFileBlocState state) {
    if (state is ListFaceFileBlocInit) {
      itemStreamListItems = [];
    } else if (state is ListFaceFileBlocSuccess ||
        state is ListFaceFileBlocLoading) {
      _transformItems(state.items);
    } else if (state is ListFaceFileBlocFailure) {
      _transformItems(state.items);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(state.exception)),
        duration: k.snackBarDurationNormal,
      ));
    } else if (state is ListFaceFileBlocInconsistent) {
      _reqQuery();
    }
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
    final c = KiwiContainer().resolve<DiContainer>();
    final selected = selectedListItems
        .whereType<PhotoListFileItem>()
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

  Future<void> _onSelectionAddToAlbumPressed(BuildContext context) {
    final c = KiwiContainer().resolve<DiContainer>();
    return AddSelectionToAlbumHandler(c)(
      context: context,
      account: widget.account,
      selection: selectedListItems
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
    final c = KiwiContainer().resolve<DiContainer>();
    final selected = selectedListItems
        .whereType<PhotoListFileItem>()
        .map((e) => e.file)
        .toList();
    DownloadHandler(c).downloadFiles(widget.account, selected);
    setState(() {
      clearSelectedItems();
    });
  }

  Future<void> _onSelectionArchivePressed(BuildContext context) async {
    final c = KiwiContainer().resolve<DiContainer>();
    final selectedFiles = selectedListItems
        .whereType<PhotoListFileItem>()
        .map((e) => e.file)
        .toList();
    setState(() {
      clearSelectedItems();
    });
    await ArchiveSelectionHandler(c)(
      account: widget.account,
      selection: selectedFiles,
    );
  }

  Future<void> _onSelectionDeletePressed(BuildContext context) async {
    final c = KiwiContainer().resolve<DiContainer>();
    final selectedFiles = selectedListItems
        .whereType<PhotoListFileItem>()
        .map((e) => e.file)
        .toList();
    setState(() {
      clearSelectedItems();
    });
    await RemoveSelectionHandler(c)(
      account: widget.account,
      selection: selectedFiles,
      isMoveToTrash: true,
    );
  }

  void _onFilePropertyUpdated(FilePropertyUpdatedEvent ev) {
    if (_backingFiles.containsIf(ev.file, (a, b) => a.fdId == b.fdId) != true) {
      return;
    }
    _refreshThrottler.trigger(
      maxResponceTime: const Duration(seconds: 3),
      maxPendingCount: 10,
    );
  }

  Future<void> _transformItems(List<File> files) async {
    final PhotoListItemSorter? sorter;
    final PhotoListItemGrouper? grouper;
    if (Pref().isPhotosTabSortByNameOr()) {
      sorter = photoListFilenameSorter;
      grouper = null;
    } else {
      sorter = photoListFileDateTimeSorter;
      grouper = PhotoListFileDateGrouper(isMonthOnly: _thumbZoomLevel < 0);
    }

    _buildItemQueue.addJob(
      PhotoListItemBuilderArguments(
        widget.account,
        files,
        sorter: sorter,
        grouper: grouper,
        shouldShowFavoriteBadge: true,
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
    _bloc.add(ListFaceFileBlocQuery(widget.account, widget.person));
  }

  late final DiContainer _c;

  late final ListFaceFileBloc _bloc = ListFaceFileBloc(_c);
  var _backingFiles = <FileDescriptor>[];

  final _buildItemQueue =
      ComputeQueue<PhotoListItemBuilderArguments, PhotoListItemBuilderResult>();

  var _thumbZoomLevel = 0;
  int get _thumbSize => photo_list_util.getThumbSize(_thumbZoomLevel);

  late final Throttler _refreshThrottler = Throttler(
    onTriggered: (_) {
      if (mounted) {
        _transformItems(_bloc.state.items);
      }
    },
    logTag: "_PersonBrowserState.refresh",
  );

  late final _filePropertyUpdatedListener =
      AppEventListener<FilePropertyUpdatedEvent>(_onFilePropertyUpdated);

  static final _log = Logger("widget.person_browser._PersonBrowserState");
}

enum _SelectionMenuOption {
  archive,
  delete,
  download,
}
