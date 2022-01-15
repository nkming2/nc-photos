import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/download_handler.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/share_handler.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/preprocess_album.dart';
import 'package:nc_photos/widget/album_browser_mixin.dart';
import 'package:nc_photos/widget/handler/add_selection_to_album_handler.dart';
import 'package:nc_photos/widget/photo_list_item.dart';
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/viewer.dart';

class SmartAlbumBrowserArguments {
  const SmartAlbumBrowserArguments(this.account, this.album);

  final Account account;
  final Album album;
}

class SmartAlbumBrowser extends StatefulWidget {
  static const routeName = "/smart-album-browser";

  static Route buildRoute(SmartAlbumBrowserArguments args) => MaterialPageRoute(
        builder: (context) => SmartAlbumBrowser.fromArgs(args),
      );

  const SmartAlbumBrowser({
    Key? key,
    required this.account,
    required this.album,
  }) : super(key: key);

  SmartAlbumBrowser.fromArgs(SmartAlbumBrowserArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
          album: args.album,
        );

  @override
  createState() => _SmartAlbumBrowserState();

  final Account account;
  final Album album;
}

class _SmartAlbumBrowserState extends State<SmartAlbumBrowser>
    with
        SelectableItemStreamListMixin<SmartAlbumBrowser>,
        AlbumBrowserMixin<SmartAlbumBrowser> {
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
          builder: (context) => _buildContent(context),
        ),
      ),
    );
  }

  @override
  @protected
  get canEdit => false;

  Future<void> _initAlbum() async {
    assert(widget.album.provider is AlbumSmartProvider);
    _log.info("[_initAlbum] ${widget.album}");
    final items = await PreProcessAlbum(AppDb())(widget.account, widget.album);
    if (mounted) {
      setState(() {
        _album = widget.album;
        _transformItems(items);
        initCover(widget.account, widget.album);
      });
    }
  }

  Widget _buildContent(BuildContext context) {
    if (_album == null) {
      return CustomScrollView(
        slivers: [
          buildNormalAppBar(context, widget.account, widget.album),
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
                maxCrossAxisExtent: thumbSize.toDouble(),
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
    final menuItems = <PopupMenuEntry<int>>[
      PopupMenuItem(
        value: _menuValueDownload,
        child: Text(L10n.global().downloadTooltip),
      ),
    ];

    return buildNormalAppBar(
      context,
      widget.account,
      _album!,
      menuItemBuilder: (_) => menuItems,
      onSelectedMenuItem: (option) {
        switch (option) {
          case _menuValueDownload:
            _onDownloadPressed();
            break;
          default:
            _log.shout("[_buildNormalAppBar] Unknown value: $option");
            break;
        }
      },
    );
  }

  Widget _buildSelectionAppBar(BuildContext context) {
    return buildSelectionAppBar(context, [
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
        onPressed: () => _onSelectionAddPressed(context),
      ),
      PopupMenuButton<_SelectionMenuOption>(
        tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _SelectionMenuOption.download,
            child: Text(L10n.global().downloadTooltip),
          ),
        ],
        onSelected: (option) => _onSelectionMenuSelected(context, option),
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
        arguments: ViewerArguments(widget.account, _backingFiles, fileIndex,
            album: widget.album));
  }

  void _onDownloadPressed() {
    DownloadHandler().downloadFiles(
      widget.account,
      _sortedItems.whereType<AlbumFileItem>().map((e) => e.file).toList(),
      parentDir: _album!.name,
    );
  }

  void _onSelectionMenuSelected(
      BuildContext context, _SelectionMenuOption option) {
    switch (option) {
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
        .whereType<_FileListItem>()
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

  Future<void> _onSelectionAddPressed(BuildContext context) async {
    return AddSelectionToAlbumHandler()(
      context: context,
      account: widget.account,
      selectedFiles: selectedListItems
          .whereType<_FileListItem>()
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
        .whereType<_FileListItem>()
        .map((e) => e.file)
        .toList();
    DownloadHandler().downloadFiles(widget.account, selected);
    setState(() {
      clearSelectedItems();
    });
  }

  void _transformItems(List<AlbumItem> items) {
    // items come sorted for smart album
    _sortedItems = _album!.sortProvider.sort(items);
    _backingFiles = _sortedItems
        .whereType<AlbumFileItem>()
        .map((i) => i.file)
        .where((f) => file_util.isSupportedFormat(f))
        .toList();

    itemStreamListItems = () sync* {
      for (int i = 0; i < _sortedItems.length; ++i) {
        final item = _sortedItems[i];
        if (item is AlbumFileItem) {
          final previewUrl = api_util.getFilePreviewUrl(
            widget.account,
            item.file,
            width: k.photoThumbSize,
            height: k.photoThumbSize,
          );

          if (file_util.isSupportedImageFormat(item.file)) {
            yield _ImageListItem(
              index: i,
              file: item.file,
              account: widget.account,
              previewUrl: previewUrl,
              onTap: () => _onItemTap(i),
            );
          } else if (file_util.isSupportedVideoFormat(item.file)) {
            yield _VideoListItem(
              index: i,
              file: item.file,
              account: widget.account,
              previewUrl: previewUrl,
              onTap: () => _onItemTap(i),
            );
          }
        }
      }
    }()
        .toList();
  }

  Album? _album;
  var _sortedItems = <AlbumItem>[];
  var _backingFiles = <File>[];

  static final _log =
      Logger("widget.smart_album_browser._SmartAlbumBrowserState");
  static const _menuValueDownload = 1;
}

enum _SelectionMenuOption {
  download,
}

abstract class _ListItem implements SelectableItem {
  const _ListItem({
    required this.index,
    VoidCallback? onTap,
  }) : _onTap = onTap;

  @override
  get onTap => _onTap;

  @override
  get isSelectable => true;

  @override
  get staggeredTile => const StaggeredTile.count(1, 1);

  @override
  toString() {
    return "$runtimeType {"
        "index: $index, "
        "}";
  }

  final int index;

  final VoidCallback? _onTap;
}

abstract class _FileListItem extends _ListItem {
  _FileListItem({
    required int index,
    required this.file,
    VoidCallback? onTap,
  }) : super(
          index: index,
          onTap: onTap,
        );

  final File file;
}

class _ImageListItem extends _FileListItem {
  _ImageListItem({
    required int index,
    required File file,
    required this.account,
    required this.previewUrl,
    VoidCallback? onTap,
  }) : super(
          index: index,
          file: file,
          onTap: onTap,
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
    required int index,
    required File file,
    required this.account,
    required this.previewUrl,
    VoidCallback? onTap,
  }) : super(
          index: index,
          file: file,
          onTap: onTap,
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
