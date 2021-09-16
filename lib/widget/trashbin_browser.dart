import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/ls_trashbin.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/remove.dart';
import 'package:nc_photos/use_case/restore_trashbin.dart';
import 'package:nc_photos/widget/empty_list_indicator.dart';
import 'package:nc_photos/widget/photo_list_item.dart';
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/selection_app_bar.dart';
import 'package:nc_photos/widget/trashbin_viewer.dart';
import 'package:nc_photos/widget/zoom_menu_button.dart';

class TrashbinBrowserArguments {
  TrashbinBrowserArguments(this.account);

  final Account account;
}

class TrashbinBrowser extends StatefulWidget {
  static const routeName = "/trashbin-browser";

  static Route buildRoute(TrashbinBrowserArguments args) => MaterialPageRoute(
        builder: (context) => TrashbinBrowser.fromArgs(args),
      );

  const TrashbinBrowser({
    Key? key,
    required this.account,
  }) : super(key: key);

  TrashbinBrowser.fromArgs(TrashbinBrowserArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
        );

  @override
  createState() => _TrashbinBrowserState();

  final Account account;
}

class _TrashbinBrowserState extends State<TrashbinBrowser>
    with SelectableItemStreamListMixin<TrashbinBrowser> {
  @override
  initState() {
    super.initState();
    _initBloc();
    _thumbZoomLevel = Pref.inst().getAlbumBrowserZoomLevelOr(0);
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: BlocListener<LsTrashbinBloc, LsTrashbinBlocState>(
          bloc: _bloc,
          listener: (context, state) => _onStateChange(context, state),
          child: BlocBuilder<LsTrashbinBloc, LsTrashbinBlocState>(
            bloc: _bloc,
            builder: (context, state) => _buildContent(context, state),
          ),
        ),
      ),
    );
  }

  void _initBloc() {
    _bloc = LsTrashbinBloc.of(widget.account);
    if (_bloc.state is LsTrashbinBlocInit) {
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

  Widget _buildContent(BuildContext context, LsTrashbinBlocState state) {
    if (state is LsTrashbinBlocSuccess && itemStreamListItems.isEmpty) {
      return Column(
        children: [
          AppBar(
            title: Text(L10n.global().albumTrashLabel),
            elevation: 0,
          ),
          Expanded(
            child: EmptyListIndicator(
              icon: Icons.delete_outline,
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
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8),
                    sliver: buildItemStreamList(
                      maxCrossAxisExtent: _thumbSize.toDouble(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state is LsTrashbinBlocLoading)
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
          icon: const Icon(Icons.restore_outlined),
          tooltip: L10n.global().restoreTooltip,
          onPressed: () {
            _onSelectionAppBarRestorePressed();
          },
        ),
        PopupMenuButton<_SelectionAppBarMenuOption>(
          tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _SelectionAppBarMenuOption.delete,
              child: Text(L10n.global().deletePermanentlyTooltip),
            ),
          ],
          onSelected: (option) {
            switch (option) {
              case _SelectionAppBarMenuOption.delete:
                _onSelectionAppBarDeletePressed(context);
                break;

              default:
                _log.shout("[_buildSelectionAppBar] Unknown option: $option");
                break;
            }
          },
        )
      ],
    );
  }

  Widget _buildNormalAppBar(BuildContext context) {
    return SliverAppBar(
      title: Text(L10n.global().albumTrashLabel),
      floating: true,
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
        PopupMenuButton<_AppBarMenuOption>(
          tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _AppBarMenuOption.empty,
              child: Text(L10n.global().emptyTrashbinTooltip),
            ),
          ],
          onSelected: (option) {
            switch (option) {
              case _AppBarMenuOption.empty:
                _onEmptyTrashPressed(context);
                break;

              default:
                _log.shout("[_buildNormalAppBar] Unknown option: $option");
                break;
            }
          },
        ),
      ],
    );
  }

  void _onStateChange(BuildContext context, LsTrashbinBlocState state) {
    if (state is LsTrashbinBlocInit) {
      itemStreamListItems = [];
    } else if (state is LsTrashbinBlocSuccess ||
        state is LsTrashbinBlocLoading) {
      _transformItems(state.items);
    } else if (state is LsTrashbinBlocFailure) {
      _transformItems(state.items);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(state.exception)),
        duration: k.snackBarDurationNormal,
      ));
    } else if (state is LsTrashbinBlocInconsistent) {
      _reqQuery();
    }
  }

  void _onItemTap(int index) {
    Navigator.pushNamed(context, TrashbinViewer.routeName,
        arguments:
            TrashbinViewerArguments(widget.account, _backingFiles, index));
  }

  void _onEmptyTrashPressed(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(L10n.global().emptyTrashbinConfirmationDialogTitle),
        content: Text(L10n.global().emptyTrashbinConfirmationDialogContent),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteFiles(_backingFiles);
            },
            child: Text(L10n.global().confirmButtonLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _onSelectionAppBarRestorePressed() async {
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(L10n.global()
          .restoreSelectedProcessingNotification(selectedListItems.length)),
      duration: k.snackBarDurationShort,
    ));
    final selectedFiles = selectedListItems
        .whereType<_FileListItem>()
        .map((e) => e.file)
        .toList();
    setState(() {
      clearSelectedItems();
    });
    const fileRepo = FileRepo(FileWebdavDataSource());
    final failures = <File>[];
    for (final f in selectedFiles) {
      try {
        await RestoreTrashbin(fileRepo)(widget.account, f);
      } catch (e, stacktrace) {
        _log.shout(
            "[_onSelectionAppBarRestorePressed] Failed while restoring file" +
                (shouldLogFileName ? ": ${f.path}" : ""),
            e,
            stacktrace);
        failures.add(f);
      }
    }
    if (failures.isEmpty) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().restoreSelectedSuccessNotification),
        duration: k.snackBarDurationNormal,
      ));
    } else {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(
            L10n.global().restoreSelectedFailureNotification(failures.length)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  Future<void> _onSelectionAppBarDeletePressed(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(L10n.global().deletePermanentlyConfirmationDialogTitle),
        content: Text(L10n.global().deletePermanentlyConfirmationDialogContent),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteSelected();
            },
            child: Text(L10n.global().confirmButtonLabel),
          ),
        ],
      ),
    );
  }

  void _transformItems(List<File> files) {
    _backingFiles = files
        .where((element) => file_util.isSupportedFormat(element))
        .sorted((a, b) {
      if (a.trashbinDeletionTime == null && b.trashbinDeletionTime == null) {
        // ?
        return 0;
      } else if (a.trashbinDeletionTime == null) {
        return -1;
      } else if (b.trashbinDeletionTime == null) {
        return 1;
      } else {
        return b.trashbinDeletionTime!.compareTo(a.trashbinDeletionTime!);
      }
    });

    itemStreamListItems = () sync* {
      for (int i = 0; i < _backingFiles.length; ++i) {
        final f = _backingFiles[i];

        final previewUrl = api_util.getFilePreviewUrl(widget.account, f,
            width: k.photoThumbSize, height: k.photoThumbSize);
        if (file_util.isSupportedImageFormat(f)) {
          yield _ImageListItem(
            file: f,
            account: widget.account,
            previewUrl: previewUrl,
            onTap: () => _onItemTap(i),
          );
        } else if (file_util.isSupportedVideoFormat(f)) {
          yield _VideoListItem(
            file: f,
            account: widget.account,
            previewUrl: previewUrl,
            onTap: () => _onItemTap(i),
          );
        } else {
          _log.shout(
              "[_transformItems] Unsupported file format: ${f.contentType}");
        }
      }
    }()
        .toList();
  }

  Future<void> _deleteSelected() async {
    final selectedFiles = selectedListItems
        .whereType<_FileListItem>()
        .map((e) => e.file)
        .toList();
    setState(() {
      clearSelectedItems();
    });
    return _deleteFiles(selectedFiles);
  }

  Future<void> _deleteFiles(List<File> files) async {
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(
          L10n.global().deleteSelectedProcessingNotification(files.length)),
      duration: k.snackBarDurationShort,
    ));
    final fileRepo = FileRepo(FileCachedDataSource());
    final failures = <File>[];
    for (final f in files) {
      try {
        await Remove(fileRepo, null)(widget.account, f);
      } catch (e, stacktrace) {
        _log.shout(
            "[_deleteFiles] Failed while removing file" +
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

  void _reqQuery() {
    _bloc.add(LsTrashbinBlocQuery(widget.account));
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

  late LsTrashbinBloc _bloc;

  var _backingFiles = <File>[];

  var _thumbZoomLevel = 0;

  static final _log = Logger("widget.trashbin_browser._TrashbinBrowserState");
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

  @override
  operator ==(Object other) {
    return other is _FileListItem && file.path == other.file.path;
  }

  @override
  get hashCode => file.path.hashCode;

  final File file;
}

class _ImageListItem extends _FileListItem {
  _ImageListItem({
    required File file,
    required this.account,
    required this.previewUrl,
    VoidCallback? onTap,
  }) : super(file: file, onTap: onTap);

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
    required File file,
    required this.account,
    required this.previewUrl,
    VoidCallback? onTap,
  }) : super(file: file, onTap: onTap);

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

enum _AppBarMenuOption {
  empty,
}

enum _SelectionAppBarMenuOption {
  delete,
}
