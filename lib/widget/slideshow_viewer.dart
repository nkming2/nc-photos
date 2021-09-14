import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/animated_visibility.dart';
import 'package:nc_photos/widget/disposable.dart';
import 'package:nc_photos/widget/horizontal_page_viewer.dart';
import 'package:nc_photos/widget/image_viewer.dart';
import 'package:nc_photos/widget/slideshow_dialog.dart';
import 'package:nc_photos/widget/video_viewer.dart';
import 'package:nc_photos/widget/viewer_mixin.dart';
import 'package:nc_photos/widget/wakelock_util.dart';

class SlideshowViewerArguments {
  SlideshowViewerArguments(
    this.account,
    this.streamFiles,
    this.startIndex,
    this.config,
  );

  final Account account;
  final List<File> streamFiles;
  final int startIndex;
  final SlideshowConfig config;
}

class SlideshowViewer extends StatefulWidget {
  static const routeName = "/slideshow-viewer";

  static Route buildRoute(SlideshowViewerArguments args) => MaterialPageRoute(
        builder: (context) => SlideshowViewer.fromArgs(args),
      );

  SlideshowViewer({
    Key? key,
    required this.account,
    required this.streamFiles,
    required this.startIndex,
    required this.config,
  }) : super(key: key);

  SlideshowViewer.fromArgs(SlideshowViewerArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
          streamFiles: args.streamFiles,
          startIndex: args.startIndex,
          config: args.config,
        );

  @override
  createState() => _SlideshowViewerState();

  final Account account;
  final List<File> streamFiles;
  final int startIndex;
  final SlideshowConfig config;
}

class _SlideshowViewerState extends State<SlideshowViewer>
    with
        DisposableManagerMixin<SlideshowViewer>,
        ViewerControllersMixin<SlideshowViewer> {
  @override
  initState() {
    super.initState();
    _shuffledIndex = () {
      final index = [for (var i = 0; i < widget.streamFiles.length; ++i) i];
      if (widget.config.isShuffle) {
        return index..shuffle();
      } else {
        return index;
      }
    }();
    _initSlideshow();
    SystemChrome.setEnabledSystemUIOverlays([]);
  }

  @override
  initDisposables() {
    return [
      ...super.initDisposables(),
      WakelockControllerDisposable(),
    ];
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
          HorizontalPageViewer(
            pageCount:
                widget.config.isRepeat ? null : widget.streamFiles.length,
            pageBuilder: _buildPage,
            // the original order is meaningless after shuffled
            initialPage: widget.config.isShuffle ? 0 : widget.startIndex,
            controller: _viewerController,
            viewportFraction: _viewportFraction,
            canSwitchPage: false,
          ),
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
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPage(BuildContext context, int index) {
    final itemIndex = _transformIndex(index);
    _log.info("[_buildPage] Page: $index, item: $itemIndex");
    return FractionallySizedBox(
      widthFactor: 1 / _viewportFraction,
      child: _buildItemView(context, itemIndex),
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
      return Container();
    }
  }

  Widget _buildImageView(BuildContext context, int index) {
    return ImageViewer(
      account: widget.account,
      file: widget.streamFiles[index],
      canZoom: false,
      onLoaded: () => _onImageLoaded(index),
    );
  }

  Widget _buildVideoView(BuildContext context, int index) {
    return VideoViewer(
      account: widget.account,
      file: widget.streamFiles[index],
      onLoadFailure: () {
        // error, next
        Future.delayed(const Duration(seconds: 2), _onSlideshowTick);
      },
      onPause: () {
        // video ended
        Future.delayed(const Duration(seconds: 2), _onSlideshowTick);
      },
      isControlVisible: false,
    );
  }

  void _onImageLoaded(int index) {
    // currently pageview doesn't pre-load pages, we do it manually
    // don't pre-load if user already navigated away
    if (_viewerController.currentPage == index) {
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
  }

  void _initSlideshow() {
    _setupSlideTransition(widget.startIndex);
  }

  void _onSlideshowTick() async {
    if (!mounted) {
      return;
    }
    _log.info("[_onSlideshowTick] Next item");
    final page = _viewerController.currentPage;
    await _viewerController.nextPage(
        duration: k.animationDurationLong, curve: Curves.easeInOut);
    final newPage = _viewerController.currentPage;
    if (page == newPage) {
      // end reached
      _log.info("[_onSlideshowTick] Reached the end");
      return;
    }
    _setupSlideTransition(newPage);
  }

  void _setupSlideTransition(int index) {
    final itemIndex = _transformIndex(index);
    final item = widget.streamFiles[itemIndex];
    if (file_util.isSupportedVideoFormat(item)) {
      // for videos, we need to wait until it's ended
    } else {
      Future.delayed(widget.config.duration, _onSlideshowTick);
    }
  }

  void _setShowActionBar(bool flag) {
    _isShowAppBar = flag;
  }

  /// Return the page index to the corresponding item index
  int _transformIndex(int pageIndex) =>
      _shuffledIndex[pageIndex % widget.streamFiles.length];

  var _isShowAppBar = false;

  final _viewerController = HorizontalPageViewerController();
  // late final _SlideshowController _slideshowController;
  late final List<int> _shuffledIndex;

  static final _log = Logger("widget.slideshow_viewer._SlideshowViewerState");

  static const _viewportFraction = 1.05;
}
