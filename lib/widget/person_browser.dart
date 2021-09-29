import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/list_face.dart';
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/download_handler.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/face.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/notified_action.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/share_handler.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/throttler.dart';
import 'package:nc_photos/use_case/add_to_album.dart';
import 'package:nc_photos/use_case/populate_person.dart';
import 'package:nc_photos/use_case/remove.dart';
import 'package:nc_photos/use_case/update_property.dart';
import 'package:nc_photos/widget/album_picker_dialog.dart';
import 'package:nc_photos/widget/photo_list_item.dart';
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
  @override
  initState() {
    super.initState();
    _initBloc();
    _thumbZoomLevel = Pref.inst().getAlbumBrowserZoomLevelOr(0);

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
        body: BlocListener<ListFaceBloc, ListFaceBlocState>(
          bloc: _bloc,
          listener: (context, state) => _onStateChange(context, state),
          child: BlocBuilder<ListFaceBloc, ListFaceBlocState>(
            bloc: _bloc,
            builder: (context, state) => _buildContent(context),
          ),
        ),
      ),
    );
  }

  void _initBloc() {
    _log.info("[_initBloc] Initialize bloc");
    _reqQuery();
  }

  Widget _buildContent(BuildContext context) {
    if (_backingFiles == null) {
      return CustomScrollView(
        slivers: [
          _buildNormalAppBar(context),
          const SliverToBoxAdapter(
            child: LinearProgressIndicator(),
          ),
        ],
      );
    } else {
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
              _buildAppBar(context),
              buildItemStreamList(
                maxCrossAxisExtent: _thumbSize.toDouble(),
              ),
            ],
          ),
        ),
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

  Widget _buildNormalAppBar(BuildContext context) {
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
                if (_backingFiles != null)
                  Text(
                    L10n.global()
                        .personPhotoCountText(itemStreamListItems.length),
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
            Pref.inst().setAlbumBrowserZoomLevel(_thumbZoomLevel);
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
        if (platform_k.isAndroid)
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: L10n.global().shareTooltip,
            onPressed: () {
              _onSelectionSharePressed(context);
            },
          ),
        IconButton(
          icon: const Icon(Icons.playlist_add),
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

  void _onStateChange(BuildContext context, ListFaceBlocState state) {
    if (state is ListFaceBlocInit) {
      _backingFiles = null;
    } else if (state is ListFaceBlocSuccess || state is ListFaceBlocLoading) {
      _transformItems(state.items);
    } else if (state is ListFaceBlocFailure) {
      _transformItems(state.items);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(state.exception)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  void _onItemTap(int index) {
    Navigator.pushNamed(context, Viewer.routeName,
        arguments: ViewerArguments(widget.account, _backingFiles!, index));
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
    assert(platform_k.isAndroid);
    final selected =
        selectedListItems.whereType<_ListItem>().map((e) => e.file).toList();
    ShareHandler().shareFiles(context, widget.account, selected).then((_) {
      setState(() {
        clearSelectedItems();
      });
    });
  }

  Future<void> _onSelectionAddToAlbumPressed(BuildContext context) async {
    try {
      final value = await showDialog<Album>(
        context: context,
        builder: (_) => AlbumPickerDialog(
          account: widget.account,
        ),
      );
      if (value == null) {
        // user cancelled the dialog
        return;
      }

      _log.info("[_onSelectionAddToAlbumPressed] Album picked: ${value.name}");
      await NotifiedAction(
        () async {
          assert(value.provider is AlbumStaticProvider);
          final selected = selectedListItems
              .whereType<_ListItem>()
              .map((e) => AlbumFileItem(file: e.file))
              .toList();
          final albumRepo = AlbumRepo(AlbumCachedDataSource());
          await AddToAlbum(albumRepo)(widget.account, value, selected);
          setState(() {
            clearSelectedItems();
          });
        },
        null,
        L10n.global().addSelectedToAlbumSuccessNotification(value.name),
        failureText: L10n.global().addSelectedToAlbumFailureNotification,
      )();
    } catch (e, stackTrace) {
      _log.shout("[_onSelectionAddToAlbumPressed] Exception", e, stackTrace);
    }
  }

  void _onSelectionDownloadPressed() {
    final selected =
        selectedListItems.whereType<_ListItem>().map((e) => e.file).toList();
    DownloadHandler().downloadFiles(widget.account, selected);
    setState(() {
      clearSelectedItems();
    });
  }

  Future<void> _onSelectionArchivePressed(BuildContext context) async {
    final selectedFiles =
        selectedListItems.whereType<_ListItem>().map((e) => e.file).toList();
    setState(() {
      clearSelectedItems();
    });
    final fileRepo = FileRepo(FileCachedDataSource());
    await NotifiedListAction<File>(
      list: selectedFiles,
      action: (file) async {
        await UpdateProperty(fileRepo)
            .updateIsArchived(widget.account, file, true);
      },
      processingText: L10n.global()
          .archiveSelectedProcessingNotification(selectedFiles.length),
      successText: L10n.global().archiveSelectedSuccessNotification,
      getFailureText: (failures) =>
          L10n.global().archiveSelectedFailureNotification(failures.length),
      onActionError: (file, e, stackTrace) {
        _log.shout(
            "[_onSelectionArchivePressed] Failed while archiving file" +
                (shouldLogFileName ? ": ${file.path}" : ""),
            e,
            stackTrace);
      },
    )();
  }

  Future<void> _onSelectionDeletePressed(BuildContext context) async {
    final selectedFiles =
        selectedListItems.whereType<_ListItem>().map((e) => e.file).toList();
    setState(() {
      clearSelectedItems();
    });
    final fileRepo = FileRepo(FileCachedDataSource());
    final albumRepo = AlbumRepo(AlbumCachedDataSource());
    await NotifiedListAction<File>(
      list: selectedFiles,
      action: (file) async {
        await Remove(fileRepo, albumRepo)(widget.account, file);
      },
      processingText: L10n.global()
          .deleteSelectedProcessingNotification(selectedFiles.length),
      successText: L10n.global().deleteSelectedSuccessNotification,
      getFailureText: (failures) =>
          L10n.global().deleteSelectedFailureNotification(failures.length),
      onActionError: (file, e, stackTrace) {
        _log.shout(
            "[_onSelectionDeletePressed] Failed while removing file" +
                (shouldLogFileName ? ": ${file.path}" : ""),
            e,
            stackTrace);
      },
    )();
  }

  void _onFilePropertyUpdated(FilePropertyUpdatedEvent ev) {
    if (_backingFiles?.containsIf(ev.file, (a, b) => a.fileId == b.fileId) !=
        true) {
      return;
    }
    _refreshThrottler.trigger(
      maxResponceTime: const Duration(seconds: 3),
      maxPendingCount: 10,
    );
  }

  void _transformItems(List<Face> items) async {
    final files = await PopulatePerson()(widget.account, items);
    _backingFiles = files
        .sorted(compareFileDateTimeDescending)
        .where((element) =>
            file_util.isSupportedFormat(element) && element.isArchived != true)
        .toList();
    setState(() {
      itemStreamListItems = _backingFiles!
          .mapWithIndex((i, f) => _ListItem(
                index: i,
                file: f,
                account: widget.account,
                previewUrl: api_util.getFilePreviewUrl(
                  widget.account,
                  f,
                  width: k.photoThumbSize,
                  height: k.photoThumbSize,
                ),
                onTap: () => _onItemTap(i),
              ))
          .toList();
    });
  }

  void _reqQuery() {
    _bloc.add(ListFaceBlocQuery(widget.account, widget.person));
  }

  int get _thumbSize {
    switch (_thumbZoomLevel) {
      case 1:
        return 176;

      case 2:
        return 256;

      case 0:
      default:
        return 112;
    }
  }

  final ListFaceBloc _bloc = ListFaceBloc();
  List<File>? _backingFiles;

  var _thumbZoomLevel = 0;

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

class _ListItem implements SelectableItem {
  _ListItem({
    required this.index,
    required this.file,
    required this.account,
    required this.previewUrl,
    VoidCallback? onTap,
  }) : _onTap = onTap;

  @override
  get onTap => _onTap;

  @override
  get isSelectable => true;

  @override
  get staggeredTile => const StaggeredTile.count(1, 1);

  @override
  operator ==(Object other) {
    return other is _ListItem && file.path == other.file.path;
  }

  @override
  get hashCode => file.path.hashCode;

  @override
  toString() {
    return "$runtimeType {"
        "index: $index, "
        "}";
  }

  @override
  buildWidget(BuildContext context) {
    return PhotoListImage(
      account: account,
      previewUrl: previewUrl,
      isGif: file.contentType == "image/gif",
    );
  }

  final int index;
  final File file;
  final Account account;
  final String previewUrl;
  final VoidCallback? _onTap;
}

enum _SelectionMenuOption {
  archive,
  delete,
  download,
}
