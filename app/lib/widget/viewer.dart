import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/download_handler.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/flutter_util.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/notified_action.dart';
import 'package:nc_photos/platform/features.dart' as features;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/share_handler.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/inflate_file_descriptor.dart';
import 'package:nc_photos/use_case/remove_from_album.dart';
import 'package:nc_photos/use_case/update_property.dart';
import 'package:nc_photos/widget/animated_visibility.dart';
import 'package:nc_photos/widget/disposable.dart';
import 'package:nc_photos/widget/handler/archive_selection_handler.dart';
import 'package:nc_photos/widget/handler/remove_selection_handler.dart';
import 'package:nc_photos/widget/handler/unarchive_selection_handler.dart';
import 'package:nc_photos/widget/horizontal_page_viewer.dart';
import 'package:nc_photos/widget/image_editor.dart';
import 'package:nc_photos/widget/image_enhancer.dart';
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
  final List<FileDescriptor> streamFiles;
  final int startIndex;
  final Album? album;
}

class Viewer extends StatefulWidget {
  static const routeName = "/viewer";

  static Route buildRoute(ViewerArguments args) =>
      CustomizableMaterialPageRoute(
        transitionDuration: k.heroDurationNormal,
        reverseTransitionDuration: k.heroDurationNormal,
        builder: (_) => Viewer.fromArgs(args),
      );

  const Viewer({
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
  final List<FileDescriptor> streamFiles;
  final int startIndex;

  /// The album these files belongs to, or null
  final Album? album;
}

class _ViewerState extends State<Viewer>
    with DisposableManagerMixin<Viewer>, ViewerControllersMixin<Viewer> {
  @override
  initState() {
    super.initState();
    _streamFilesView = widget.streamFiles;
  }

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
            const Align(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            ),
          HorizontalPageViewer(
            pageCount: _streamFilesView.length,
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
    final index =
        _isViewerLoaded ? _viewerController.currentPage : widget.startIndex;
    final file = _streamFilesView[index];
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(0, -1),
                    end: Alignment(0, 1),
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
                foregroundColor: Colors.white.withOpacity(.87),
                actions: [
                  if (!_isDetailPaneActive && _canOpenDetailPane()) ...[
                    (_pageStates[index]?.favoriteOverride ??
                                file.fdIsFavorite) ==
                            true
                        ? IconButton(
                            icon: const Icon(Icons.star),
                            tooltip: L10n.global().unfavoriteTooltip,
                            onPressed: () => _onUnfavoritePressed(index),
                          )
                        : IconButton(
                            icon: const Icon(Icons.star_border),
                            tooltip: L10n.global().favoriteTooltip,
                            onPressed: () => _onFavoritePressed(index),
                          ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      tooltip: L10n.global().detailsTooltip,
                      onPressed: _onDetailsPressed,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAppBar(BuildContext context) {
    final index =
        _isViewerLoaded ? _viewerController.currentPage : widget.startIndex;
    final file = _streamFilesView[index];
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
              IconButton(
                icon: Icon(
                  Icons.share_outlined,
                  color: Colors.white.withOpacity(.87),
                ),
                tooltip: L10n.global().shareTooltip,
                onPressed: () => _onSharePressed(context),
              ),
              if (features.isSupportEnhancement &&
                  ImageEnhancer.isSupportedFormat(file)) ...[
                IconButton(
                  icon: Icon(
                    Icons.tune_outlined,
                    color: Colors.white.withOpacity(.87),
                  ),
                  tooltip: L10n.global().editTooltip,
                  onPressed: () => _onEditPressed(context),
                ),
                IconButton(
                  icon: Icon(
                    Icons.auto_fix_high_outlined,
                    color: Colors.white.withOpacity(.87),
                  ),
                  tooltip: L10n.global().enhanceTooltip,
                  onPressed: () => _onEnhancePressed(context),
                ),
              ],
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
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            controller: _pageStates[index]!.scrollController,
            physics: !_isZoomed ? null : const NeverScrollableScrollPhysics(),
            child: Stack(
              children: [
                _buildItemView(context, index),
                IgnorePointer(
                  ignoring: !_isShowDetailPane,
                  child: Visibility(
                    visible: !_isZoomed,
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
                              top: Radius.circular(4)),
                        ),
                        margin:
                            EdgeInsets.only(top: _calcDetailPaneOffset(index)),
                        // this visibility widget avoids loading the detail pane
                        // until it's actually opened, otherwise swiping between
                        // photos will slow down severely
                        child: Visibility(
                          visible: _isShowDetailPane,
                          child: ViewerDetailPane(
                            account: widget.account,
                            fd: _streamFilesView[index],
                            album: widget.album,
                            onRemoveFromAlbumPressed: _onRemoveFromAlbumPressed,
                            onArchivePressed: _onArchivePressed,
                            onUnarchivePressed: _onUnarchivePressed,
                            onSlideshowPressed: _onSlideshowPressed,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemView(BuildContext context, int index) {
    final file = _streamFilesView[index];
    if (file_util.isSupportedImageFormat(file)) {
      return _buildImageView(context, index);
    } else if (file_util.isSupportedVideoFormat(file)) {
      return _buildVideoView(context, index);
    } else {
      _log.shout("[_buildItemView] Unknown file format: ${file.fdMime}");
      _pageStates[index]!.itemHeight = 0;
      return Container();
    }
  }

  Widget _buildImageView(BuildContext context, int index) {
    return RemoteImageViewer(
      account: widget.account,
      file: _streamFilesView[index],
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
      file: _streamFilesView[index],
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
    if (notification is ScrollStartNotification) {
      _scrollStartPosition =
          _pageStates[index]?.scrollController.position.pixels;
    }
    if (notification is ScrollEndNotification) {
      _scrollStartPosition = null;
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
    } else if (notification is ScrollUpdateNotification) {
      if (!_isShowDetailPane) {
        Future.delayed(Duration.zero, () {
          setState(() {
            _isShowDetailPane = true;
            _isDetailPaneActive = true;
          });
        });
      }
    }

    if (notification is OverscrollNotification) {
      if (_scrollStartPosition == 0) {
        // start at top
        _overscrollSum += notification.overscroll;
        if (_overscrollSum < -144) {
          // and scroll downwards
          Navigator.of(context).pop();
        }
      }
    } else {
      _overscrollSum = 0;
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
        final prevFile = _streamFilesView[index - 1];
        if (file_util.isSupportedImageFormat(prevFile)) {
          RemoteImageViewer.preloadImage(widget.account, prevFile);
        }
      }
      if (index + 1 < _streamFilesView.length) {
        final nextFile = _streamFilesView[index + 1];
        if (file_util.isSupportedImageFormat(nextFile)) {
          RemoteImageViewer.preloadImage(widget.account, nextFile);
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
          : 0,
    ));
  }

  /// Called when the page is being built after previously moved out of view
  void _onRecreatePageAfterMovedOut(BuildContext context, int index) {
    _pageStates[index]!.setScrollController(ScrollController(
      initialScrollOffset: _isShowDetailPane && !_isClosingDetailPane
          ? _calcDetailPaneOpenedScrollPosition(index)
          : 0,
    ));
    if (_isShowDetailPane && !_isClosingDetailPane) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageStates[index]!.itemHeight != null) {
          setState(() {
            _openDetailPane(index);
          });
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageStates[index]!.scrollController.jumpTo(0);
      });
    }
  }

  Future<void> _onFavoritePressed(int index) async {
    if (_pageStates[index]!.isProcessingFavorite) {
      _log.fine("[_onFavoritePressed] Process ongoing, ignored");
      return;
    }

    final fd = _streamFilesView[_viewerController.currentPage];
    final c = KiwiContainer().resolve<DiContainer>();
    final file = (await InflateFileDescriptor(c)(widget.account, [fd])).first;
    setState(() {
      _pageStates[index]!.favoriteOverride = true;
    });
    _pageStates[index]!.isProcessingFavorite = true;
    try {
      await NotifiedAction(
        () => UpdateProperty(c.fileRepo)(
          widget.account,
          file,
          favorite: true,
        ),
        null,
        L10n.global().favoriteSuccessNotification,
        failureText: L10n.global().favoriteFailureNotification,
      )();
    } catch (e, stackTrace) {
      _log.shout(
          "[_onFavoritePressed] Failed while UpdateProperty", e, stackTrace);
      setState(() {
        _pageStates[index]!.favoriteOverride = false;
      });
    }
    _pageStates[index]!.isProcessingFavorite = false;
  }

  Future<void> _onUnfavoritePressed(int index) async {
    if (_pageStates[index]!.isProcessingFavorite) {
      _log.fine("[_onUnfavoritePressed] Process ongoing, ignored");
      return;
    }

    final fd = _streamFilesView[_viewerController.currentPage];
    final c = KiwiContainer().resolve<DiContainer>();
    final file = (await InflateFileDescriptor(c)(widget.account, [fd])).first;
    setState(() {
      _pageStates[index]!.favoriteOverride = false;
    });
    _pageStates[index]!.isProcessingFavorite = true;
    try {
      await NotifiedAction(
        () => UpdateProperty(c.fileRepo)(
          widget.account,
          file,
          favorite: false,
        ),
        null,
        L10n.global().unfavoriteSuccessNotification,
        failureText: L10n.global().unfavoriteFailureNotification,
      )();
    } catch (e, stackTrace) {
      _log.shout(
          "[_onUnfavoritePressed] Failed while UpdateProperty", e, stackTrace);
      setState(() {
        _pageStates[index]!.favoriteOverride = true;
      });
    }
    _pageStates[index]!.isProcessingFavorite = false;
  }

  void _onDetailsPressed() {
    if (!_isDetailPaneActive) {
      setState(() {
        _openDetailPane(_viewerController.currentPage, shouldAnimate: true);
      });
    }
  }

  void _onSharePressed(BuildContext context) {
    final c = KiwiContainer().resolve<DiContainer>();
    final file = _streamFilesView[_viewerController.currentPage];
    ShareHandler(
      c,
      context: context,
    ).shareFiles(widget.account, [file]);
  }

  void _onEditPressed(BuildContext context) {
    final file = _streamFilesView[_viewerController.currentPage];
    if (!file_util.isSupportedImageFormat(file)) {
      _log.shout("[_onEditPressed] Video file not supported");
      return;
    }

    _log.info("[_onEditPressed] Edit file: ${file.fdPath}");
    Navigator.of(context).pushNamed(ImageEditor.routeName,
        arguments: ImageEditorArguments(widget.account, file));
  }

  void _onEnhancePressed(BuildContext context) {
    final file = _streamFilesView[_viewerController.currentPage];
    if (!file_util.isSupportedImageFormat(file)) {
      _log.shout("[_onEnhancePressed] Video file not supported");
      return;
    }
    final c = KiwiContainer().resolve<DiContainer>();

    _log.info("[_onEnhancePressed] Enhance file: ${file.fdPath}");
    Navigator.of(context).pushNamed(ImageEnhancer.routeName,
        arguments: ImageEnhancerArguments(
            widget.account, file, c.pref.isSaveEditResultToServerOr()));
  }

  void _onDownloadPressed() {
    final c = KiwiContainer().resolve<DiContainer>();
    final file = _streamFilesView[_viewerController.currentPage];
    _log.info("[_onDownloadPressed] Downloading file: ${file.fdPath}");
    DownloadHandler(c).downloadFiles(widget.account, [file]);
  }

  void _onDeletePressed(BuildContext context) {
    final index = _viewerController.currentPage;
    final c = KiwiContainer().resolve<DiContainer>();
    final file = _streamFilesView[index];
    _log.info("[_onDeletePressed] Removing file: ${file.fdPath}");
    unawaited(RemoveSelectionHandler(c)(
      account: widget.account,
      selection: [file],
      isRemoveOpened: true,
      isMoveToTrash: true,
      shouldShowProcessingText: false,
    ));
    _removeCurrentItemFromStream(context, index);
  }

  void _onArchivePressed(BuildContext context) {
    final index = _viewerController.currentPage;
    final c = KiwiContainer().resolve<DiContainer>();
    final file = _streamFilesView[index];
    _log.info("[_onArchivePressed] Archive file: ${file.fdPath}");
    unawaited(ArchiveSelectionHandler(c)(
      account: widget.account,
      selection: [file],
      shouldShowProcessingText: false,
    ));
    _removeCurrentItemFromStream(context, index);
  }

  void _onUnarchivePressed(BuildContext context) {
    final index = _viewerController.currentPage;
    final c = KiwiContainer().resolve<DiContainer>();
    final file = _streamFilesView[index];
    _log.info("[_onUnarchivePressed] Unarchive file: ${file.fdPath}");
    unawaited(UnarchiveSelectionHandler(c)(
      account: widget.account,
      selection: [file],
      shouldShowProcessingText: false,
    ));
    _removeCurrentItemFromStream(context, index);
  }

  void _onRemoveFromAlbumPressed(BuildContext context) {
    assert(widget.album!.provider is AlbumStaticProvider);
    final index = _viewerController.currentPage;
    final c = KiwiContainer().resolve<DiContainer>();
    final file = _streamFilesView[index];
    _log.info("[_onRemoveFromAlbumPressed] Remove file: ${file.fdPath}");
    NotifiedAction(
      () async {
        final selectedFile =
            (await InflateFileDescriptor(c)(widget.account, [file])).first;
        final thisItem = AlbumStaticProvider.of(widget.album!)
            .items
            .whereType<AlbumFileItem>()
            .firstWhere((e) => e.file.compareServerIdentity(selectedFile));
        await RemoveFromAlbum(KiwiContainer().resolve<DiContainer>())(
            widget.account, widget.album!, [thisItem]);
      },
      null,
      L10n.global().removeSelectedFromAlbumSuccessNotification(1),
      failureText: L10n.global().removeSelectedFromAlbumFailureNotification,
    ).call().catchError((e, stackTrace) {
      _log.shout("[_onRemoveFromAlbumPressed] Failed while updating album", e,
          stackTrace);
    });
    _removeCurrentItemFromStream(context, index);
  }

  void _removeCurrentItemFromStream(BuildContext context, int index) {
    if (_streamFilesView.length == 1) {
      Navigator.of(context).pop();
    } else {
      if (index >= _streamFilesView.length - 1) {
        // last item, go back
        _viewerController
            .previousPage(
          duration: k.animationDurationNormal,
          curve: Curves.easeInOut,
        )
            .then((_) {
          if (mounted) {
            setState(() {
              _streamFilesEditable.removeAt(index);
            });
          }
        });
      } else {
        _viewerController
            .nextPage(
          duration: k.animationDurationNormal,
          curve: Curves.easeInOut,
        )
            .then((_) {
          if (mounted) {
            setState(() {
              _streamFilesEditable.removeAt(index);
            });
            // a page is removed, length - 1
            _viewerController.jumpToPage(index);
          }
        });
      }
    }
  }

  Future<void> _onSlideshowPressed() async {
    final result = await showDialog<SlideshowConfig>(
      context: context,
      builder: (_) => SlideshowDialog(
        duration: Duration(seconds: Pref().getSlideshowDurationOr(5)),
        isShuffle: Pref().isSlideshowShuffleOr(false),
        isRepeat: Pref().isSlideshowRepeatOr(false),
        isReverse: Pref().isSlideshowReverseOr(false),
      ),
    );
    if (result == null) {
      return;
    }
    unawaited(Pref().setSlideshowDuration(result.duration.inSeconds));
    unawaited(Pref().setSlideshowShuffle(result.isShuffle));
    unawaited(Pref().setSlideshowRepeat(result.isRepeat));
    unawaited(Pref().setSlideshowReverse(result.isReverse));
    unawaited(
      Navigator.of(context).pushNamed(
        SlideshowViewer.routeName,
        arguments: SlideshowViewerArguments(widget.account, widget.streamFiles,
            _viewerController.currentPage, result),
      ),
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
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
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

  List<FileDescriptor> get _streamFilesEditable {
    if (!_isStreamFilesCopy) {
      _streamFilesView = List.of(_streamFilesView);
      _isStreamFilesCopy = true;
    }
    return _streamFilesView;
  }

  var _isShowAppBar = true;

  var _isShowDetailPane = false;
  var _isDetailPaneActive = false;
  var _isClosingDetailPane = false;

  var _isZoomed = false;

  final _viewerController = HorizontalPageViewerController();
  bool _isViewerLoaded = false;
  final _pageStates = <int, _PageState>{};

  double? _scrollStartPosition;
  var _overscrollSum = 0.0;

  late List<FileDescriptor> _streamFilesView;
  bool _isStreamFilesCopy = false;

  static final _log = Logger("widget.viewer._ViewerState");

  static const _viewportFraction = 1.05;
}

class _PageState {
  _PageState(this.scrollController);

  void setScrollController(ScrollController c) {
    scrollController = c;
  }

  ScrollController scrollController;
  double? itemHeight;
  bool hasLoaded = false;

  bool isProcessingFavorite = false;
  bool? favoriteOverride;
}
