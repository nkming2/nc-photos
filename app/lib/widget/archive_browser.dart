import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/scan_account_dir.dart';
import 'package:nc_photos/compute_queue.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/language_util.dart' as language_util;
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/inflate_file_descriptor.dart';
import 'package:nc_photos/use_case/update_property.dart';
import 'package:nc_photos/widget/builder/photo_list_item_builder.dart';
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
    if (_bloc.state is ScanAccountDirBlocInit) {
      _log.info("[_initBloc] Initialize bloc");
      _reqQuery();
    } else {
      // process the current state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _onStateChange(context, _bloc.state);
        });
      });
    }
  }

  Widget _buildContent(BuildContext context, ScanAccountDirBlocState state) {
    if (state is ScanAccountDirBlocSuccess &&
        !_buildItemQueue.isProcessing &&
        itemStreamListItems.isEmpty) {
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
                  buildItemStreamList(
                    maxCrossAxisExtent: _thumbSize.toDouble(),
                  ),
                ],
              ),
            ),
          ),
          if (state is ScanAccountDirBlocLoading ||
              _buildItemQueue.isProcessing)
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

  Future<void> _onSelectionAppBarUnarchivePressed() async {
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(L10n.global()
          .unarchiveSelectedProcessingNotification(selectedListItems.length)),
      duration: k.snackBarDurationShort,
    ));
    final selection = selectedListItems
        .whereType<PhotoListFileItem>()
        .map((e) => e.file)
        .toList();
    setState(() {
      clearSelectedItems();
    });
    final c = KiwiContainer().resolve<DiContainer>();
    final selectedFiles =
        await InflateFileDescriptor(c)(widget.account, selection);
    final failures = <File>[];
    for (final f in selectedFiles) {
      try {
        await UpdateProperty(c.fileRepo)
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

  void _transformItems(List<FileDescriptor> files) {
    _buildItemQueue.addJob(
      PhotoListItemBuilderArguments(
        widget.account,
        files,
        isArchived: true,
        sorter: photoListFileDateTimeSorter,
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
    _bloc.add(const ScanAccountDirBlocQuery());
  }

  late final _bloc = ScanAccountDirBloc.of(widget.account);

  var _backingFiles = <FileDescriptor>[];

  final _buildItemQueue =
      ComputeQueue<PhotoListItemBuilderArguments, PhotoListItemBuilderResult>();

  var _thumbZoomLevel = 0;
  int get _thumbSize => photo_list_util.getThumbSize(_thumbZoomLevel);

  static final _log = Logger("widget.archive_browser._ArchiveBrowserState");
}
