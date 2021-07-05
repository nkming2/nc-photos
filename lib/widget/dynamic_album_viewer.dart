import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/list_extension.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/populate_album.dart';
import 'package:nc_photos/use_case/remove.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:nc_photos/use_case/update_dynamic_album_cover.dart';
import 'package:nc_photos/use_case/update_dynamic_album_time.dart';
import 'package:nc_photos/widget/album_viewer_mixin.dart';
import 'package:nc_photos/widget/photo_list_item.dart';
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/viewer.dart';

class DynamicAlbumViewerArguments {
  DynamicAlbumViewerArguments(this.account, this.album);

  final Account account;
  final Album album;
}

class DynamicAlbumViewer extends StatefulWidget {
  static const routeName = "/dynamic-album-viewer";

  DynamicAlbumViewer({
    Key key,
    @required this.account,
    @required this.album,
  }) : super(key: key);

  DynamicAlbumViewer.fromArgs(DynamicAlbumViewerArguments args, {Key key})
      : this(
          key: key,
          account: args.account,
          album: args.album,
        );

  @override
  createState() => _DynamicAlbumViewerState();

  final Account account;
  final Album album;
}

class _DynamicAlbumViewerState extends State<DynamicAlbumViewer>
    with
        WidgetsBindingObserver,
        SelectableItemStreamListMixin<DynamicAlbumViewer>,
        AlbumViewerMixin<DynamicAlbumViewer> {
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
          builder: (context) {
            if (isEditMode) {
              return Form(
                key: _editFormKey,
                child: _buildContent(context),
              );
            } else {
              return _buildContent(context);
            }
          },
        ),
      ),
    );
  }

  @override
  doneEditMode() {
    if (_editFormKey?.currentState?.validate() == true) {
      _editFormKey.currentState.save();
      final newAlbum = makeEdited(_album);
      if (newAlbum.copyWith(lastUpdated: _album.lastUpdated) != _album) {
        _log.info("[doneEditMode] Album modified: $newAlbum");
        final albumRepo = AlbumRepo(AlbumCachedDataSource());
        setState(() {
          _album = newAlbum;
        });
        UpdateAlbum(albumRepo)(widget.account, newAlbum)
            .catchError((e, stacktrace) {
          SnackBarManager().showSnackBar(SnackBar(
            content: Text(exception_util.toUserString(e, context)),
            duration: k.snackBarDurationNormal,
          ));
        });
      } else {
        _log.fine("[doneEditMode] Album not modified");
      }
      return true;
    }
    return false;
  }

  void _initAlbum() {
    assert(widget.album.provider is AlbumDynamicProvider);
    PopulateAlbum()(widget.account, widget.album).then((items) {
      if (mounted) {
        setState(() {
          _album = widget.album;
          _items = items;
          _transformItems(items);
          final coverFile = initCover(widget.account, _backingFiles);
          _updateAlbumPostPopulate(coverFile, items);
        });
      }
    });
  }

  void _updateAlbumPostPopulate(File coverFile, List<AlbumItem> items) {
    bool shouldUpdate = false;
    final albumUpdatedCover =
        UpdateDynamicAlbumCover().updateWithSortedFiles(_album, _backingFiles);
    if (!identical(albumUpdatedCover, _album)) {
      _log.info("[_updateAlbumPostPopulate] Update album cover");
      shouldUpdate = true;
    }
    _album = albumUpdatedCover;

    final albumUpdatedTime =
        UpdateDynamicAlbumTime().updateWithSortedFiles(_album, _backingFiles);
    if (!identical(albumUpdatedTime, _album)) {
      _log.info(
          "[_updateAlbumPostPopulate] Update album time: ${albumUpdatedTime.provider.latestItemTime}");
      shouldUpdate = true;
    }
    _album = albumUpdatedTime;

    if (shouldUpdate) {
      UpdateAlbum(AlbumRepo(AlbumCachedDataSource()))(widget.account, _album);
    }
  }

  Widget _buildContent(BuildContext context) {
    if (_album == null) {
      return CustomScrollView(
        slivers: [
          buildNormalAppBar(context, widget.account, widget.album),
          const SliverToBoxAdapter(
            child: const LinearProgressIndicator(),
          ),
        ],
      );
    }
    return buildItemStreamListOuter(
      context,
      child: Theme(
        data: Theme.of(context).copyWith(
          accentColor: AppTheme.getOverscrollIndicatorColor(context),
        ),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              sliver: SliverIgnorePointer(
                ignoring: isEditMode,
                sliver: SliverOpacity(
                  opacity: isEditMode ? .25 : 1,
                  sliver: buildItemStreamList(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    if (isEditMode) {
      return _buildEditAppBar(context);
    } else if (isSelectionMode) {
      return _buildSelectionAppBar(context);
    } else {
      return _buildNormalAppBar(context);
    }
  }

  Widget _buildNormalAppBar(BuildContext context) {
    return buildNormalAppBar(
      context,
      widget.account,
      _album,
      menuItemBuilder: (context) => [
        PopupMenuItem(
          value: _menuValueConvertBasic,
          child: Text(AppLocalizations.of(context).convertBasicAlbumMenuLabel),
        ),
      ],
      onSelectedMenuItem: (option) {
        switch (option) {
          case _menuValueConvertBasic:
            _onAppBarConvertBasicPressed(context);
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
      PopupMenuButton(
        tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _SelectionAppBarOption.delete,
            child: Text(AppLocalizations.of(context).deleteSelectedTooltip),
          ),
        ],
        onSelected: (option) {
          if (option == _SelectionAppBarOption.delete) {
            _onSelectionAppBarDeletePressed();
          }
        },
      ),
    ]);
  }

  Widget _buildEditAppBar(BuildContext context) {
    return buildEditAppBar(context, widget.account, widget.album);
  }

  void _onItemTap(int index) {
    Navigator.pushNamed(context, Viewer.routeName,
        arguments: ViewerArguments(widget.account, _backingFiles, index));
  }

  void _onAppBarConvertBasicPressed(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)
            .convertBasicAlbumConfirmationDialogTitle),
        content: Text(AppLocalizations.of(context)
            .convertBasicAlbumConfirmationDialogContent),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    ).then((value) {
      if (value != true) {
        return;
      }
      _log.info(
          "[_onAppBarConvertBasicPressed] Converting album '${_album.name}' to static");
      final albumRepo = AlbumRepo(AlbumCachedDataSource());
      UpdateAlbum(albumRepo)(
        widget.account,
        _album.copyWith(
          provider: AlbumStaticProvider(items: _items),
          coverProvider: AlbumAutoCoverProvider(),
        ),
      ).then((value) {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)
              .convertBasicAlbumSuccessNotification),
          duration: k.snackBarDurationNormal,
        ));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }).catchError((e, stacktrace) {
        _log.shout(
            "[_onAppBarConvertBasicPressed] Failed while converting to basic album",
            e,
            stacktrace);
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(exception_util.toUserString(e, context)),
          duration: k.snackBarDurationNormal,
        ));
      });
    });
  }

  void _onSelectionAppBarDeletePressed() async {
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)
          .deleteSelectedProcessingNotification(selectedListItems.length)),
      duration: k.snackBarDurationShort,
    ));

    final selectedIndexes =
        selectedListItems.map((e) => itemStreamListItems.indexOf(e)).toList();
    final selectedFiles = _backingFiles.takeIndex(selectedIndexes).toList();
    setState(() {
      clearSelectedItems();
    });

    final fileRepo = FileRepo(FileCachedDataSource());
    final albumRepo = AlbumRepo(AlbumCachedDataSource());
    final failures = <File>[];
    for (final f in selectedFiles) {
      try {
        await Remove(fileRepo, albumRepo).call(widget.account, f);
      } catch (e, stacktrace) {
        _log.shout(
            "[_onSelectionAppBarDeletePressed] Failed while removing file" +
                (kDebugMode ? ": ${f.path}" : ""),
            e,
            stacktrace);
        failures.add(f);
      }
    }

    if (failures.isEmpty) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(
            AppLocalizations.of(context).deleteSelectedSuccessNotification),
        duration: k.snackBarDurationNormal,
      ));
    } else {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)
            .deleteSelectedFailureNotification(failures.length)),
        duration: k.snackBarDurationNormal,
      ));
    }
    final successes =
        selectedFiles.where((element) => !failures.containsIdentical(element));
    if (successes.isNotEmpty) {
      setState(() {
        _backingFiles
            .removeWhere((element) => successes.containsIdentical(element));
        _onBackingFilesUpdated();
      });
    }
  }

  void _transformItems(List<AlbumItem> items) {
    _backingFiles = items
        .whereType<AlbumFileItem>()
        .map((e) => e.file)
        .where((element) => file_util.isSupportedFormat(element))
        .sorted(compareFileDateTimeDescending);
    _onBackingFilesUpdated();
  }

  void _onBackingFilesUpdated() {
    itemStreamListItems = () sync* {
      for (int i = 0; i < _backingFiles.length; ++i) {
        final f = _backingFiles[i];

        final previewUrl = api_util.getFilePreviewUrl(widget.account, f,
            width: thumbSize, height: thumbSize);
        if (file_util.isSupportedImageFormat(f)) {
          yield _ImageListItem(
            file: f,
            account: widget.account,
            previewUrl: previewUrl,
            onTap: () => _onItemTap(i),
          );
        } else if (file_util.isSupportedVideoFormat(f)) {
          yield _VideoListItem(
            account: widget.account,
            previewUrl: previewUrl,
            onTap: () => _onItemTap(i),
          );
        } else {
          _log.shout(
              "[_onBackingFilesUpdated] Unsupported file format: ${f.contentType}");
        }
      }
    }();
  }

  Album _album;
  List<AlbumItem> _items;
  var _backingFiles = <File>[];

  final _editFormKey = GlobalKey<FormState>();

  static final _log =
      Logger("widget.dynamic_album_viewer._DynamicAlbumViewerState");
  static const _menuValueConvertBasic = 0;
}

class _ImageListItem extends SelectableItemStreamListItem {
  _ImageListItem({
    @required this.file,
    @required this.account,
    @required this.previewUrl,
    VoidCallback onTap,
  }) : super(onTap: onTap, isSelectable: true);

  @override
  buildWidget(BuildContext context) {
    return PhotoListImage(
      account: account,
      previewUrl: previewUrl,
      isGif: file.contentType == "image/gif",
    );
  }

  final File file;
  final Account account;
  final String previewUrl;
}

class _VideoListItem extends SelectableItemStreamListItem {
  _VideoListItem({
    @required this.account,
    @required this.previewUrl,
    VoidCallback onTap,
  }) : super(onTap: onTap, isSelectable: true);

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

enum _SelectionAppBarOption {
  delete,
}
