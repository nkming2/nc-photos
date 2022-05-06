import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/scan_local_dir.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/local_file.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/android/content_uri_image_provider.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/empty_list_indicator.dart';
import 'package:nc_photos/widget/handler/delete_local_selection_handler.dart';
import 'package:nc_photos/widget/local_file_viewer.dart';
import 'package:nc_photos/widget/photo_list_util.dart' as photo_list_util;
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/selection_app_bar.dart';
import 'package:nc_photos_plugin/nc_photos_plugin.dart';

class EnhancedPhotoBrowserArguments {
  const EnhancedPhotoBrowserArguments(this.filename);

  final String? filename;
}

class EnhancedPhotoBrowser extends StatefulWidget {
  static const routeName = "/enhanced-photo-browser";

  static Route buildRoute(EnhancedPhotoBrowserArguments args) =>
      MaterialPageRoute(
        builder: (context) => EnhancedPhotoBrowser.fromArgs(args),
      );

  const EnhancedPhotoBrowser({
    Key? key,
    required this.filename,
  }) : super(key: key);

  EnhancedPhotoBrowser.fromArgs(EnhancedPhotoBrowserArguments args, {Key? key})
      : this(
          key: key,
          filename: args.filename,
        );

  @override
  createState() => _EnhancedPhotoBrowserState();

  final String? filename;
}

class _EnhancedPhotoBrowserState extends State<EnhancedPhotoBrowser>
    with SelectableItemStreamListMixin<EnhancedPhotoBrowser> {
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
        body: BlocListener<ScanLocalDirBloc, ScanLocalDirBlocState>(
          bloc: _bloc,
          listener: (context, state) => _onStateChange(context, state),
          child: BlocBuilder<ScanLocalDirBloc, ScanLocalDirBlocState>(
            bloc: _bloc,
            builder: (context, state) => _buildContent(context, state),
          ),
        ),
      ),
    );
  }

  void _initBloc() {
    if (_bloc.state is ScanLocalDirBlocInit) {
      _log.info("[_initBloc] Initialize bloc");
      _reqQuery();
    } else {
      // process the current state
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        setState(() {
          _onStateChange(context, _bloc.state);
        });
        _reqQuery();
      });
    }
  }

  Widget _buildContent(BuildContext context, ScanLocalDirBlocState state) {
    if (state is ScanLocalDirBlocSuccess && itemStreamListItems.isEmpty) {
      return Column(
        children: [
          AppBar(
            title: Text(L10n.global().collectionEnhancedPhotosLabel),
            elevation: 0,
          ),
          Expanded(
            child: EmptyListIndicator(
              icon: Icons.folder_outlined,
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
          if (state is ScanLocalDirBlocLoading)
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

  Widget _buildNormalAppBar(BuildContext context) => SliverAppBar(
        title: Text(L10n.global().collectionEnhancedPhotosLabel),
      );

  Widget _buildSelectionAppBar(BuildContext context) {
    return SelectionAppBar(
      count: selectedListItems.length,
      onClosePressed: () {
        setState(() {
          clearSelectedItems();
        });
      },
      actions: [
        PopupMenuButton<_SelectionMenuOption>(
          tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _SelectionMenuOption.delete,
              child: Text(L10n.global().deletePermanentlyTooltip),
            ),
          ],
          onSelected: (option) => _onSelectionMenuSelected(context, option),
        ),
      ],
    );
  }

  void _onStateChange(BuildContext context, ScanLocalDirBlocState state) {
    if (state is ScanLocalDirBlocInit) {
      itemStreamListItems = [];
    } else if (state is ScanLocalDirBlocLoading) {
      _transformItems(state.files);
    } else if (state is ScanLocalDirBlocSuccess) {
      _transformItems(state.files);
      if (_isFirstRun) {
        _isFirstRun = false;
        if (widget.filename != null) {
          _openInitialImage(widget.filename!);
        }
      }
    } else if (state is ScanLocalDirBlocFailure) {
      _transformItems(state.files);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(state.exception is PermissionException
            ? L10n.global().errorNoStoragePermission
            : exception_util.toUserString(state.exception)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  void _onSelectionMenuSelected(
      BuildContext context, _SelectionMenuOption option) {
    switch (option) {
      case _SelectionMenuOption.delete:
        _onSelectionDeletePressed(context);
        break;
      default:
        _log.shout("[_onSelectionMenuSelected] Unknown option: $option");
        break;
    }
  }

  Future<void> _onSelectionDeletePressed(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.global().deletePermanentlyConfirmationDialogTitle),
        content: Text(
          L10n.global().deletePermanentlyLocalConfirmationDialogContent,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text(L10n.global().confirmButtonLabel),
          ),
        ],
      ),
    );
    if (result != true) {
      return;
    }

    final selectedFiles = selectedListItems
        .whereType<_FileListItem>()
        .map((e) => e.file)
        .toList();
    setState(() {
      clearSelectedItems();
    });
    await const DeleteLocalSelectionHandler()(selectedFiles: selectedFiles);
  }

  void _onItemTap(int index) {
    Navigator.pushNamed(context, LocalFileViewer.routeName,
        arguments: LocalFileViewerArguments(_backingFiles, index));
  }

  void _transformItems(List<LocalFile> files) {
    // we use last modified here to keep newly enhanced photo at the top
    _backingFiles =
        files.stableSorted((a, b) => b.lastModified.compareTo(a.lastModified));

    itemStreamListItems = () sync* {
      for (int i = 0; i < _backingFiles.length; ++i) {
        final f = _backingFiles[i];
        if (file_util.isSupportedImageMime(f.mime ?? "")) {
          yield _ImageListItem(
            file: f,
            onTap: () => _onItemTap(i),
          );
        }
      }
    }()
        .toList();
    _log.info("[_transformItems] Length: ${itemStreamListItems.length}");
  }

  void _openInitialImage(String filename) {
    final index = _backingFiles.indexWhere((f) => f.filename == filename);
    if (index == -1) {
      _log.severe("[openInitialImage] Filename not found: $filename");
      return;
    }
    Navigator.pushNamed(context, LocalFileViewer.routeName,
        arguments: LocalFileViewerArguments(_backingFiles, index));
  }

  void _reqQuery() {
    _bloc.add(const ScanLocalDirBlocQuery(
        ["Download/Photos (for Nextcloud)/Enhanced Photos"]));
  }

  final _bloc = ScanLocalDirBloc();

  var _backingFiles = <LocalFile>[];

  var _isFirstRun = true;
  var _thumbZoomLevel = 0;
  int get _thumbSize => photo_list_util.getThumbSize(_thumbZoomLevel);

  static final _log =
      Logger("widget.enhanced_photo_browser._EnhancedPhotoBrowserState");
}

abstract class _ListItem implements SelectableItem {
  _ListItem({
    VoidCallback? onTap,
  }) : _onTap = onTap;

  @override
  get onTap => _onTap;

  @override
  get isSelectable => true;

  @override
  get staggeredTile => const StaggeredTile.count(1, 1);

  final VoidCallback? _onTap;
}

abstract class _FileListItem extends _ListItem {
  _FileListItem({
    required this.file,
    VoidCallback? onTap,
  }) : super(onTap: onTap);

  final LocalFile file;
}

class _ImageListItem extends _FileListItem {
  _ImageListItem({
    required LocalFile file,
    VoidCallback? onTap,
  }) : super(file: file, onTap: onTap);

  @override
  buildWidget(BuildContext context) {
    final ImageProvider provider;
    if (file is LocalUriFile) {
      provider = ContentUriImage((file as LocalUriFile).uri);
    } else {
      throw ArgumentError("Invalid file");
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: FittedBox(
        clipBehavior: Clip.hardEdge,
        fit: BoxFit.cover,
        child: Container(
          // arbitrary size here
          constraints: BoxConstraints.tight(const Size(128, 128)),
          color: AppTheme.getListItemBackgroundColor(context),
          child: Image(
            image: ResizeImage.resizeIfNeeded(k.photoThumbSize, null, provider),
            filterQuality: FilterQuality.high,
            fit: BoxFit.cover,
            errorBuilder: (context, e, stackTrace) {
              return Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: Colors.white.withOpacity(.8),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _SelectionMenuOption {
  delete,
}
