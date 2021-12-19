import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/scan_account_dir.dart';
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
import 'package:nc_photos/use_case/update_property.dart';
import 'package:nc_photos/widget/empty_list_indicator.dart';
import 'package:nc_photos/widget/photo_list_item.dart';
import 'package:nc_photos/widget/photo_list_util.dart' as photo_list_util;
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/selection_app_bar.dart';
import 'package:nc_photos/widget/viewer.dart';
import 'package:nc_photos/widget/zoom_menu_button.dart';

class ArchiveBrowserArguments {
  ArchiveBrowserArguments(this.account);

  final Account account;
}

class ArchiveBrowser extends StatefulWidget {
  static const routeName = "/archive-browser";

  static Route buildRoute(ArchiveBrowserArguments args) => MaterialPageRoute(
        builder: (context) => ArchiveBrowser.fromArgs(args),
      );

  const ArchiveBrowser({
    Key? key,
    required this.account,
  }) : super(key: key);

  ArchiveBrowser.fromArgs(ArchiveBrowserArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
        );

  @override
  createState() => _ArchiveBrowserState();

  final Account account;
}

class _ArchiveBrowserState extends State<ArchiveBrowser>
    with SelectableItemStreamListMixin<ArchiveBrowser> {
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
        body: BlocListener<ScanAccountDirBloc, ScanAccountDirBlocState>(
          bloc: _bloc,
          listener: (context, state) => _onStateChange(context, state),
          child: BlocBuilder<ScanAccountDirBloc, ScanAccountDirBlocState>(
            bloc: _bloc,
            builder: (context, state) => _buildContent(context, state),
          ),
        ),
      ),
    );
  }

  void _initBloc() {
    if (_bloc.state is ScanAccountDirBlocInit) {
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

  Widget _buildContent(BuildContext context, ScanAccountDirBlocState state) {
    if (state is ScanAccountDirBlocSuccess && itemStreamListItems.isEmpty) {
      return Column(
        children: [
          AppBar(
            title: Text(L10n.global().albumArchiveLabel),
            elevation: 0,
          ),
          Expanded(
            child: EmptyListIndicator(
              icon: Icons.archive_outlined,
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
          if (state is ScanAccountDirBlocLoading)
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
          icon: const Icon(Icons.unarchive),
          tooltip: L10n.global().unarchiveTooltip,
          onPressed: () {
            _onSelectionAppBarUnarchivePressed();
          },
        ),
      ],
    );
  }

  Widget _buildNormalAppBar(BuildContext context) {
    return SliverAppBar(
      title: Text(L10n.global().albumArchiveLabel),
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
            Pref().setAlbumBrowserZoomLevel(_thumbZoomLevel);
          },
        ),
      ],
    );
  }

  void _onStateChange(BuildContext context, ScanAccountDirBlocState state) {
    if (state is ScanAccountDirBlocInit) {
      itemStreamListItems = [];
    } else if (state is ScanAccountDirBlocSuccess ||
        state is ScanAccountDirBlocLoading) {
      _transformItems(state.files);
    } else if (state is ScanAccountDirBlocFailure) {
      _transformItems(state.files);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(state.exception)),
        duration: k.snackBarDurationNormal,
      ));
    } else if (state is ScanAccountDirBlocInconsistent) {
      _reqQuery();
    }
  }

  void _onItemTap(int index) {
    Navigator.pushNamed(context, Viewer.routeName,
        arguments: ViewerArguments(widget.account, _backingFiles, index));
  }

  Future<void> _onSelectionAppBarUnarchivePressed() async {
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(L10n.global()
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
    final fileRepo = FileRepo(FileCachedDataSource(AppDb()));
    final failures = <File>[];
    for (final f in selectedFiles) {
      try {
        await UpdateProperty(fileRepo)
            .updateIsArchived(widget.account, f, false);
      } catch (e, stacktrace) {
        _log.shout(
            "[_onSelectionAppBarUnarchivePressed] Failed while unarchiving file: ${logFilename(f.path)}",
            e,
            stacktrace);
        failures.add(f);
      }
    }
    if (failures.isEmpty) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().unarchiveSelectedSuccessNotification),
        duration: k.snackBarDurationNormal,
      ));
    } else {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global()
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

  void _reqQuery() {
    _bloc.add(const ScanAccountDirBlocQuery());
  }

  late final _bloc = ScanAccountDirBloc.of(widget.account);

  var _backingFiles = <File>[];

  var _thumbZoomLevel = 0;
  int get _thumbSize => photo_list_util.getThumbSize(_thumbZoomLevel);

  static final _log = Logger("widget.archive_browser._ArchiveBrowserState");
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
