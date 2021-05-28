import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/bloc/scan_dir.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/update_property.dart';
import 'package:nc_photos/widget/photo_list_item.dart';
import 'package:nc_photos/widget/popup_menu_zoom.dart';
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/viewer.dart';

class ArchiveViewerArguments {
  ArchiveViewerArguments(this.account);

  final Account account;
}

class ArchiveViewer extends StatefulWidget {
  static const routeName = "/archive-viewer";

  ArchiveViewer({
    Key key,
    @required this.account,
  }) : super(key: key);

  ArchiveViewer.fromArgs(ArchiveViewerArguments args, {Key key})
      : this(
          key: key,
          account: args.account,
        );

  @override
  createState() => _ArchiveViewerState();

  final Account account;
}

class _ArchiveViewerState extends State<ArchiveViewer>
    with WidgetsBindingObserver, SelectableItemStreamListMixin<ArchiveViewer> {
  @override
  initState() {
    super.initState();
    _initBloc();
    _thumbZoomLevel = Pref.inst().getAlbumViewerZoomLevel(0);
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: BlocListener<ScanDirBloc, ScanDirBlocState>(
          bloc: _bloc,
          listener: (context, state) => _onStateChange(context, state),
          child: BlocBuilder<ScanDirBloc, ScanDirBlocState>(
            bloc: _bloc,
            builder: (context, state) => _buildContent(context, state),
          ),
        ),
      ),
    );
  }

  @override
  get itemStreamListCellSize => _thumbSize;

  void _initBloc() {
    _bloc = ScanDirBloc.of(widget.account);
    if (_bloc.state is ScanDirBlocInit) {
      _log.info("[_initBloc] Initialize bloc");
      _reqQuery();
    } else {
      // process the current state
      _onStateChange(context, _bloc.state);
    }
  }

  Widget _buildContent(BuildContext context, ScanDirBlocState state) {
    return Stack(
      children: [
        buildItemStreamListOuter(
          context,
          child: Theme(
            data: Theme.of(context).copyWith(
              accentColor: AppTheme.getOverscrollIndicatorColor(context),
            ),
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: buildItemStreamList(context),
                ),
              ],
            ),
          ),
        ),
        if (state is ScanDirBlocLoading)
          Align(
            alignment: Alignment.bottomCenter,
            child: const LinearProgressIndicator(),
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

  Widget _buildSelectionAppBar(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: AppTheme.getContextualAppBarTheme(context),
      ),
      child: SliverAppBar(
        pinned: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () {
            setState(() {
              clearSelectedItems();
            });
          },
        ),
        title: Text(AppLocalizations.of(context)
            .selectionAppBarTitle(selectedListItems.length)),
        actions: [
          IconButton(
            icon: const Icon(Icons.unarchive),
            tooltip: AppLocalizations.of(context).unarchiveSelectedTooltip,
            onPressed: () {
              _onSelectionAppBarUnarchivePressed();
            },
          )
        ],
      ),
    );
  }

  Widget _buildNormalAppBar(BuildContext context) {
    return SliverAppBar(
      title: Text(AppLocalizations.of(context).albumArchiveLabel),
      floating: true,
      actions: [
        PopupMenuButton(
          icon: const Icon(Icons.zoom_in),
          tooltip: AppLocalizations.of(context).zoomTooltip,
          itemBuilder: (context) => [
            PopupMenuZoom(
              initialValue: _thumbZoomLevel,
              minValue: 0,
              maxValue: 2,
              onChanged: (value) {
                setState(() {
                  _thumbZoomLevel = value.round();
                });
                Pref.inst().setAlbumViewerZoomLevel(_thumbZoomLevel);
              },
            ),
          ],
        ),
      ],
    );
  }

  void _onStateChange(BuildContext context, ScanDirBlocState state) {
    if (state is ScanDirBlocInit) {
      itemStreamListItems = [];
    } else if (state is ScanDirBlocSuccess || state is ScanDirBlocLoading) {
      _transformItems(state.files);
    } else if (state is ScanDirBlocFailure) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(state.exception, context)),
        duration: k.snackBarDurationNormal,
      ));
    } else if (state is ScanDirBlocInconsistent) {
      _reqQuery();
    }
  }

  void _onItemTap(int index) {
    Navigator.pushNamed(context, Viewer.routeName,
        arguments: ViewerArguments(widget.account, _backingFiles, index));
  }

  Future<void> _onSelectionAppBarUnarchivePressed() async {
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)
          .unarchiveSelectedProcessingNotification(selectedListItems.length)),
      duration: k.snackBarDurationShort,
    ));
    final selectedFiles = selectedListItems
        .whereType<_FileListItem>()
        .map((e) => e.file)
        .toList();
    setState(() {
      clearSelectedItems();
    });
    final fileRepo = FileRepo(FileCachedDataSource());
    final albumRepo = AlbumRepo(AlbumCachedDataSource());
    final failures = <File>[];
    for (final f in selectedFiles) {
      try {
        await UpdateProperty(fileRepo, albumRepo)
            .updateIsArchived(widget.account, f, false);
      } catch (e, stacktrace) {
        _log.shout(
            "[_onSelectionAppBarUnarchivePressed] Failed while unarchiving file" +
                (kDebugMode ? ": ${f.path}" : ""),
            e,
            stacktrace);
        failures.add(f);
      }
    }
    if (failures.isEmpty) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(
            AppLocalizations.of(context).unarchiveSelectedSuccessNotification),
        duration: k.snackBarDurationNormal,
      ));
    } else {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)
            .unarchiveSelectedFailureNotification(failures.length)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  void _transformItems(List<File> files) {
    _backingFiles = files
        .where((element) =>
            file_util.isSupportedFormat(element) && element.isArchived == true)
        .sorted(compareFileDateTimeDescending);

    itemStreamListItems = () sync* {
      for (int i = 0; i < _backingFiles.length; ++i) {
        final f = _backingFiles[i];

        final previewUrl = api_util.getFilePreviewUrl(widget.account, f,
            width: _thumbSize, height: _thumbSize);
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
    }();
  }

  void _reqQuery() {
    _bloc.add(ScanDirBlocQuery(
        widget.account,
        widget.account.roots
            .map((e) => File(
                path:
                    "${api_util.getWebdavRootUrlRelative(widget.account)}/$e"))
            .toList()));
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

  ScanDirBloc _bloc;

  var _backingFiles = <File>[];

  var _thumbZoomLevel = 0;

  static final _log = Logger("widget.archive_viewer._ArchiveViewerState");
}

abstract class _FileListItem extends SelectableItemStreamListItem {
  _FileListItem({
    @required this.file,
    VoidCallback onTap,
  }) : super(onTap: onTap, isSelectable: true);

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
    @required File file,
    @required this.account,
    @required this.previewUrl,
    VoidCallback onTap,
  }) : super(file: file, onTap: onTap);

  @override
  buildWidget(BuildContext context) {
    return PhotoListImage(
      account: account,
      previewUrl: previewUrl,
    );
  }

  final Account account;
  final String previewUrl;
}

class _VideoListItem extends _FileListItem {
  _VideoListItem({
    @required File file,
    @required this.account,
    @required this.previewUrl,
    VoidCallback onTap,
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
