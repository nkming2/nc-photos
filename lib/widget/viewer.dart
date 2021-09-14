import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/notification.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/share_handler.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/download_file.dart';
import 'package:nc_photos/use_case/remove.dart';
import 'package:nc_photos/widget/animated_visibility.dart';
import 'package:nc_photos/widget/disposable.dart';
import 'package:nc_photos/widget/horizontal_page_viewer.dart';
import 'package:nc_photos/widget/image_viewer.dart';
import 'package:nc_photos/widget/slideshow_dialog.dart';
import 'package:nc_photos/widget/slideshow_viewer.dart';
import 'package:nc_photos/widget/video_viewer.dart';
import 'package:nc_photos/widget/viewer_bottom_app_bar.dart';
import 'package:nc_photos/widget/viewer_detail_pane.dart';
import 'package:nc_photos/widget/viewer_mixin.dart';

class ViewerArguments {
  ViewerArguments(
    this.account,
    this.streamFiles,
    this.startIndex, {
    this.album,
  });

  final Account account;
  final List<File> streamFiles;
  final int startIndex;
  final Album? album;
}

class Viewer extends StatefulWidget {
  static const routeName = "/viewer";

  static Route buildRoute(ViewerArguments args) => MaterialPageRoute(
        builder: (context) => Viewer.fromArgs(args),
      );

  Viewer({
    Key? key,
    required this.account,
    required this.streamFiles,
    required this.startIndex,
    this.album,
  }) : super(key: key);

  Viewer.fromArgs(ViewerArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
          streamFiles: args.streamFiles,
          startIndex: args.startIndex,
          album: args.album,
        );

  @override
  createState() => _ViewerState();

  final Account account;
  final List<File> streamFiles;
  final int startIndex;

  /// The album these files belongs to, or null
  final Album? album;
}

class _ViewerState extends State<Viewer>
    with DisposableManagerMixin<Viewer>, ViewerControllersMixin<Viewer> {
  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: Builder(
          builder: _buildContent,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _setShowActionBar(!_isShowAppBar);
        });
      },
      child: Stack(
        children: [
          Container(color: Colors.black),
          if (!_isViewerLoaded ||
              _pageStates[_viewerController.currentPage]?.hasLoaded != true)
            Align(
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
          HorizontalPageViewer(
            pageCount: widget.streamFiles.length,
            pageBuilder: _buildPage,
            initialPage: widget.startIndex,
            controller: _viewerController,
            viewportFraction: _viewportFraction,
            canSwitchPage: _canSwitchPage(),
            onPageChanged: (_) {
              setState(() {});
            },
          ),
          _buildBottomAppBar(context),
          _buildAppBar(context),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Wrap(
      children: [
        AnimatedVisibility(
          opacity: _isShowAppBar ? 1.0 : 0.0,
          duration: k.animationDurationNormal,
          child: Stack(
            children: [
              Container(
                // + status bar height
                height: kToolbarHeight + MediaQuery.of(context).padding.top,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(0, -1),
                    end: const Alignment(0, 1),
                    colors: [
                      Color.fromARGB(192, 0, 0, 0),
                      Color.fromARGB(0, 0, 0, 0),
                    ],
                  ),
                ),
              ),
              AppBar(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                brightness: Brightness.dark,
                iconTheme: Theme.of(context).iconTheme.copyWith(
                      color: Colors.white.withOpacity(.87),
                    ),
                actionsIconTheme: Theme.of(context).iconTheme.copyWith(
                      color: Colors.white.withOpacity(.87),
                    ),
                actions: [
                  if (!_isDetailPaneActive && _canOpenDetailPane())
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      tooltip: L10n.global().detailsTooltip,
                      onPressed: _onDetailsPressed,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAppBar(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedVisibility(
          opacity: (_isShowAppBar && !_isDetailPaneActive) ? 1.0 : 0.0,
          duration: !_isDetailPaneActive
              ? k.animationDurationNormal
              : const Duration(milliseconds: 1),
          child: ViewerBottomAppBar(
            children: [
              if (platform_k.isAndroid)
                IconButton(
                  icon: Icon(
                    Icons.share_outlined,
                    color: Colors.white.withOpacity(.87),
                  ),
                  tooltip: L10n.global().shareTooltip,
                  onPressed: () => _onSharePressed(context),
                ),
              IconButton(
                icon: Icon(
                  Icons.download_outlined,
                  color: Colors.white.withOpacity(.87),
                ),
                tooltip: L10n.global().downloadTooltip,
                onPressed: _onDownloadPressed,
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outlined,
                  color: Colors.white.withOpacity(.87),
                ),
                tooltip: L10n.global().deleteTooltip,
                onPressed: () => _onDeletePressed(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, int index) {
    if (_pageStates[index] == null) {
      _onCreateNewPage(context, index);
    } else if (!_pageStates[index]!.scrollController.hasClients) {
      // the page has been moved out of view and is now coming back
      _log.fine("[_buildPage] Recreating page#$index");
      _onRecreatePageAfterMovedOut(context, index);
    }

    if (kDebugMode) {
      _log.info("[_buildPage] $index");
    }

    return FractionallySizedBox(
      widthFactor: 1 / _viewportFraction,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notif) => _onPageContentScrolled(notif, index),
        child: SingleChildScrollView(
          controller: _pageStates[index]!.scrollController,
          physics:
              _isDetailPaneActive ? null : const NeverScrollableScrollPhysics(),
          child: Stack(
            children: [
              _buildItemView(context, index),
              Visibility(
                visible: _isDetailPaneActive,
                child: AnimatedOpacity(
                  opacity: _isShowDetailPane ? 1 : 0,
                  duration: k.animationDurationNormal,
                  onEnd: () {
                    if (!_isShowDetailPane) {
                      setState(() {
                        _isDetailPaneActive = false;
                      });
                    }
                  },
                  child: Container(
                    alignment: Alignment.topLeft,
                    constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                          top: const Radius.circular(4)),
                    ),
                    margin: EdgeInsets.only(top: _calcDetailPaneOffset(index)),
                    child: ViewerDetailPane(
                      account: widget.account,
                      file: widget.streamFiles[index],
                      album: widget.album,
                      onSlideshowPressed: _onSlideshowPressed,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemView(BuildContext context, int index) {
    final file = widget.streamFiles[index];
    if (file_util.isSupportedImageFormat(file)) {
      return _buildImageView(context, index);
    } else if (file_util.isSupportedVideoFormat(file)) {
      return _buildVideoView(context, index);
    } else {
      _log.shout("[_buildItemView] Unknown file format: ${file.contentType}");
      _pageStates[index]!.itemHeight = 0;
      return Container();
    }
  }

  Widget _buildImageView(BuildContext context, int index) {
    return ImageViewer(
      account: widget.account,
      file: widget.streamFiles[index],
      canZoom: _canZoom(),
      onLoaded: () => _onImageLoaded(index),
      onHeightChanged: (height) => _updateItemHeight(index, height),
      onZoomStarted: () {
        setState(() {
          _isZoomed = true;
        });
      },
      onZoomEnded: () {
        setState(() {
          _isZoomed = false;
        });
      },
    );
  }

  Widget _buildVideoView(BuildContext context, int index) {
    return VideoViewer(
      account: widget.account,
      file: widget.streamFiles[index],
      onLoaded: () => _onVideoLoaded(index),
      onHeightChanged: (height) => _updateItemHeight(index, height),
      onPlay: _onVideoPlay,
      onPause: _onVideoPause,
      isControlVisible: _isShowAppBar && !_isDetailPaneActive,
      canPlay: !_isDetailPaneActive,
    );
  }

  bool _onPageContentScrolled(ScrollNotification notification, int index) {
    if (!_canOpenDetailPane()) {
      return false;
    }
    if (notification is ScrollEndNotification) {
      final scrollPos = _pageStates[index]!.scrollController.position;
      if (scrollPos.pixels == 0) {
        setState(() {
          _onDetailPaneClosed();
        });
      } else if (scrollPos.pixels <
          _calcDetailPaneOpenedScrollPosition(index) - 1) {
        if (scrollPos.userScrollDirection == ScrollDirection.reverse) {
          // upward, open the pane to its minimal size
          Future.delayed(Duration.zero, () {
            setState(() {
              _openDetailPane(_viewerController.currentPage,
                  shouldAnimate: true);
            });
          });
        } else if (scrollPos.userScrollDirection == ScrollDirection.forward) {
          // downward, close the pane
          Future.delayed(Duration.zero, () {
            _closeDetailPane(_viewerController.currentPage,
                shouldAnimate: true);
          });
        }
      }
    }
    return false;
  }

  void _onImageLoaded(int index) {
    // currently pageview doesn't pre-load pages, we do it manually
    // don't pre-load if user already navigated away
    if (_viewerController.currentPage == index &&
        !_pageStates[index]!.hasLoaded) {
      _log.info("[_onImageLoaded] Pre-loading nearby images");
      if (index > 0) {
        final prevFile = widget.streamFiles[index - 1];
        if (file_util.isSupportedImageFormat(prevFile)) {
          ImageViewer.preloadImage(widget.account, prevFile);
        }
      }
      if (index + 1 < widget.streamFiles.length) {
        final nextFile = widget.streamFiles[index + 1];
        if (file_util.isSupportedImageFormat(nextFile)) {
          ImageViewer.preloadImage(widget.account, nextFile);
        }
      }
    }
    setState(() {
      _pageStates[index]!.hasLoaded = true;
      _isViewerLoaded = true;
    });
  }

  void _onVideoLoaded(int index) {
    setState(() {
      _pageStates[index]!.hasLoaded = true;
      _isViewerLoaded = true;
    });
  }

  void _onVideoPlay() {
    setState(() {
      _setShowActionBar(false);
    });
  }

  void _onVideoPause() {
    setState(() {
      _setShowActionBar(true);
    });
  }

  /// Called when the page is being built for the first time
  void _onCreateNewPage(BuildContext context, int index) {
    _pageStates[index] = _PageState(ScrollController(
        initialScrollOffset: _isShowDetailPane && !_isClosingDetailPane
            ? _calcDetailPaneOpenedScrollPosition(index)
            : 0));
  }

  /// Called when the page is being built after previously moved out of view
  void _onRecreatePageAfterMovedOut(BuildContext context, int index) {
    if (_isShowDetailPane && !_isClosingDetailPane) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        if (_pageStates[index]!.itemHeight != null) {
          setState(() {
            _openDetailPane(index);
          });
        }
      });
    } else {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        _pageStates[index]!.scrollController.jumpTo(0);
      });
    }
  }

  void _onDetailsPressed() {
    if (!_isDetailPaneActive) {
      setState(() {
        _openDetailPane(_viewerController.currentPage, shouldAnimate: true);
      });
    }
  }

  void _onSharePressed(BuildContext context) {
    assert(platform_k.isAndroid);
    final file = widget.streamFiles[_viewerController.currentPage];
    ShareHandler().shareFiles(context, widget.account, [file]);
  }

  void _onDownloadPressed() async {
    final file = widget.streamFiles[_viewerController.currentPage];
    _log.info("[_onDownloadPressed] Downloading file: ${file.path}");
    var controller = SnackBarManager().showSnackBar(SnackBar(
      content: Text(L10n.global().downloadProcessingNotification),
      duration: k.snackBarDurationShort,
    ));
    controller?.closed.whenComplete(() {
      controller = null;
    });
    dynamic result;
    try {
      final fileRepo = FileRepo(FileCachedDataSource());
      result = await DownloadFile(fileRepo)(widget.account, file);
      controller?.close();
    } on PermissionException catch (_) {
      _log.warning("[_onDownloadPressed] Permission not granted");
      controller?.close();
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().downloadFailureNoPermissionNotification),
        duration: k.snackBarDurationNormal,
      ));
      return;
    } catch (e, stacktrace) {
      _log.shout(
          "[_onDownloadPressed] Failed while downloadFile", e, stacktrace);
      controller?.close();
      SnackBarManager().showSnackBar(SnackBar(
        content: Text("${L10n.global().downloadFailureNotification}: "
            "${exception_util.toUserString(e)}"),
        duration: k.snackBarDurationNormal,
      ));
      return;
    }

    _onDownloadSuccessful(file, result);
  }

  void _onDownloadSuccessful(File file, dynamic result) {
    var notif;
    if (platform_k.isAndroid) {
      notif = AndroidItemDownloadSuccessfulNotification(
          [result], [file.contentType]);
    }
    if (notif != null) {
      try {
        notif.notify();
        return;
      } catch (e, stacktrace) {
        _log.shout(
            "[_onDownloadSuccessful] Failed showing platform notification",
            e,
            stacktrace);
      }
    }

    // fallback
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(L10n.global().downloadSuccessNotification),
      duration: k.snackBarDurationShort,
    ));
  }

  void _onDeletePressed(BuildContext context) async {
    final file = widget.streamFiles[_viewerController.currentPage];
    _log.info("[_onDeletePressed] Removing file: ${file.path}");
    var controller = SnackBarManager().showSnackBar(SnackBar(
      content: Text(L10n.global().deleteProcessingNotification),
      duration: k.snackBarDurationShort,
    ));
    controller?.closed.whenComplete(() {
      controller = null;
    });
    try {
      await Remove(FileRepo(FileCachedDataSource()),
          AlbumRepo(AlbumCachedDataSource()))(widget.account, file);
      controller?.close();
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().deleteSuccessNotification),
        duration: k.snackBarDurationNormal,
      ));
      Navigator.of(context).pop();
    } catch (e, stacktrace) {
      _log.shout(
          "[_onDeletePressed] Failed while remove" +
              (shouldLogFileName ? ": ${file.path}" : ""),
          e,
          stacktrace);
      controller?.close();
      SnackBarManager().showSnackBar(SnackBar(
        content: Text("${L10n.global().deleteFailureNotification}: "
            "${exception_util.toUserString(e)}"),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  void _onSlideshowPressed() async {
    final result = await showDialog<SlideshowConfig>(
      context: context,
      builder: (_) => SlideshowDialog(
        duration: Duration(seconds: Pref.inst().getSlideshowDurationOr(5)),
        isShuffle: Pref.inst().isSlideshowShuffleOr(false),
        isRepeat: Pref.inst().isSlideshowRepeatOr(false),
      ),
    );
    if (result == null) {
      return;
    }
    Pref.inst()
      ..setSlideshowDuration(result.duration.inSeconds)
      ..setSlideshowShuffle(result.isShuffle)
      ..setSlideshowRepeat(result.isRepeat);
    Navigator.of(context).pushNamed(
      SlideshowViewer.routeName,
      arguments: SlideshowViewerArguments(widget.account, widget.streamFiles,
          _viewerController.currentPage, result),
    );
  }

  double _calcDetailPaneOffset(int index) {
    if (_pageStates[index]?.itemHeight == null) {
      return MediaQuery.of(context).size.height;
    } else {
      return _pageStates[index]!.itemHeight! +
          (MediaQuery.of(context).size.height -
                  _pageStates[index]!.itemHeight!) /
              2 -
          4;
    }
  }

  double _calcDetailPaneOpenedScrollPosition(int index) {
    // distance of the detail pane from the top edge
    const distanceFromTop = 196;
    return max(_calcDetailPaneOffset(index) - distanceFromTop, 0);
  }

  void _updateItemHeight(int index, double height) {
    if (_pageStates[index]!.itemHeight != height) {
      _log.fine("[_updateItemHeight] New height of item#$index: $height");
      setState(() {
        _pageStates[index]!.itemHeight = height;
        if (_isDetailPaneActive) {
          _openDetailPane(index);
        }
      });
    }
  }

  void _setShowActionBar(bool flag) {
    _isShowAppBar = flag;
    if (flag) {
      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    } else {
      SystemChrome.setEnabledSystemUIOverlays([]);
    }
  }

  void _openDetailPane(int index, {bool shouldAnimate = false}) {
    if (!_canOpenDetailPane()) {
      _log.warning("[_openDetailPane] Can't open detail pane right now");
      return;
    }

    _isShowDetailPane = true;
    _isDetailPaneActive = true;
    if (shouldAnimate) {
      _pageStates[index]!.scrollController.animateTo(
          _calcDetailPaneOpenedScrollPosition(index),
          duration: k.animationDurationNormal,
          curve: Curves.easeOut);
    } else {
      _pageStates[index]!
          .scrollController
          .jumpTo(_calcDetailPaneOpenedScrollPosition(index));
    }
  }

  void _closeDetailPane(int index, {bool shouldAnimate = false}) {
    _isClosingDetailPane = true;
    if (shouldAnimate) {
      _pageStates[index]!.scrollController.animateTo(0,
          duration: k.animationDurationNormal, curve: Curves.easeOut);
    }
  }

  void _onDetailPaneClosed() {
    _isShowDetailPane = false;
    _isClosingDetailPane = false;
  }

  bool _canSwitchPage() => !_isZoomed;
  bool _canOpenDetailPane() => !_isZoomed;
  bool _canZoom() => !_isDetailPaneActive;

  var _isShowAppBar = true;

  var _isShowDetailPane = false;
  var _isDetailPaneActive = false;
  var _isClosingDetailPane = false;

  var _isZoomed = false;

  final _viewerController = HorizontalPageViewerController();
  bool _isViewerLoaded = false;
  final _pageStates = <int, _PageState>{};

  static final _log = Logger("widget.viewer._ViewerState");

  static const _viewportFraction = 1.05;
}

class _PageState {
  _PageState(this.scrollController);

  ScrollController scrollController;
  double? itemHeight;
  bool hasLoaded = false;
}
