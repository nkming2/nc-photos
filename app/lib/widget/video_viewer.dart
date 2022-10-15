import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/use_case/request_public_link.dart';
import 'package:nc_photos/widget/animated_visibility.dart';
import 'package:nc_photos/widget/disposable.dart';
import 'package:nc_photos/widget/wakelock_util.dart';
import 'package:video_player/video_player.dart';

class VideoViewer extends StatefulWidget {
  const VideoViewer({
    Key? key,
    required this.account,
    required this.file,
    this.onLoaded,
    this.onLoadFailure,
    this.onHeightChanged,
    this.onPlay,
    this.onPause,
    this.isControlVisible = false,
    this.canPlay = true,
  }) : super(key: key);

  @override
  createState() => _VideoViewerState();

  final Account account;
  final FileDescriptor file;
  final VoidCallback? onLoaded;
  final VoidCallback? onLoadFailure;
  final ValueChanged<double>? onHeightChanged;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final bool isControlVisible;
  final bool canPlay;
}

class _VideoViewerState extends State<VideoViewer>
    with DisposableManagerMixin<VideoViewer> {
  @override
  initState() {
    super.initState();
    _getVideoUrl().then((url) {
      setState(() {
        _initController(url);
      });
    }).onError((e, stacktrace) {
      _log.shout("[initState] Failed while _getVideoUrl", e, stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
      widget.onLoadFailure?.call();
    });
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
    Widget content;
    if (_isControllerInitialized && _controller.value.isInitialized) {
      content = _buildPlayer(context);
    } else {
      content = Container();
    }

    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      alignment: Alignment.center,
      child: content,
    );
  }

  @override
  dispose() {
    super.dispose();
    _controller.dispose();
  }

  Future<void> _initController(String url) async {
    try {
      _controller = VideoPlayerController.network(
        url,
        httpHeaders: {
          "Authorization": Api.getAuthorizationHeaderValue(widget.account),
        },
      );
      await _controller.initialize();
      widget.onLoaded?.call();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_key.currentContext != null) {
          widget.onHeightChanged?.call(_key.currentContext!.size!.height);
        }
      });
      _controller.addListener(_onControllerChanged);
      _isControllerInitialized = true;
      setState(() {
        _play();
      });
    } catch (e, stackTrace) {
      _log.shout("[_initController] Failed while initialize", e, stackTrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
      widget.onLoadFailure?.call();
    }
  }

  Widget _buildPlayer(BuildContext context) {
    if (_controller.value.isPlaying && !widget.canPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pause();
      });
    }

    return Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: AspectRatio(
            key: _key,
            aspectRatio: _controller.value.aspectRatio,
            child: IgnorePointer(
              child: VideoPlayer(_controller),
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedVisibility(
            opacity: widget.isControlVisible ? 1.0 : 0.0,
            duration: k.animationDurationNormal,
            child: Container(
              color: Colors.black45,
              child: Center(
                child: IconButton(
                  icon: Icon(_controller.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled),
                  iconSize: 48,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  onPressed: () => _controller.value.isPlaying
                      ? _onPausePressed()
                      : _onPlayPressed(),
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(
                bottom: kToolbarHeight + 8, left: 8, right: 8),
            child: AnimatedVisibility(
              opacity: widget.isControlVisible ? 1.0 : 0.0,
              duration: k.animationDurationNormal,
              child: Material(
                type: MaterialType.transparency,
                child: Row(
                  children: [
                    ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (context, VideoPlayerValue value, child) => Text(
                        _durationToString(value.position),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(.87),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        colors: const VideoProgressColors(
                          backgroundColor: Colors.white24,
                          bufferedColor: Colors.white38,
                          playedColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_controller.value.duration != Duration.zero)
                      Text(
                        _durationToString(_controller.value.duration),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(.87),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: _controller.value.volume == 0
                          ? L10n.global().unmuteTooltip
                          : L10n.global().muteTooltip,
                      child: InkWell(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(32)),
                        onTap: _onVolumnPressed,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            _controller.value.volume == 0
                                ? Icons.volume_mute_outlined
                                : Icons.volume_up_outlined,
                            color: Colors.white.withOpacity(.87),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onPlayPressed() {
    if (_controller.value.position == _controller.value.duration) {
      _controller.seekTo(const Duration()).then((_) {
        setState(() {
          _play();
        });
      });
    } else {
      setState(() {
        _play();
      });
    }
  }

  void _onPausePressed() {
    setState(() {
      _pause();
    });
  }

  void _onControllerChanged() {
    if (!_controller.value.isInitialized) {
      return;
    }
    if (!_isFinished &&
        _controller.value.position == _controller.value.duration) {
      _isFinished = true;
      setState(() {
        _pause();
      });
    }
  }

  void _onVolumnPressed() {
    setState(() {
      if (_controller.value.volume == 0) {
        _controller.setVolume(1);
      } else {
        _controller.setVolume(0);
      }
    });
  }

  void _play() {
    if (widget.canPlay) {
      _isFinished = false;
      _controller.play();
      widget.onPlay?.call();
    }
  }

  void _pause() {
    _controller.pause();
    widget.onPause?.call();
  }

  Future<String> _getVideoUrl() async {
    if (platform_k.isWeb) {
      return RequestPublicLink()(widget.account, widget.file);
    } else {
      return api_util.getFileUrl(widget.account, widget.file);
    }
  }

  final _key = GlobalKey();
  bool _isControllerInitialized = false;
  late VideoPlayerController _controller;
  var _isFinished = false;

  static final _log = Logger("widget.video_viewer._VideoViewerState");
}

String _durationToString(Duration duration) {
  String product = "";
  if (duration.inHours > 0) {
    product += "${duration.inHours}:";
  }
  final minStr = (duration.inMinutes % 60).toString().padLeft(2, "0");
  final secStr = (duration.inSeconds % 60).toString().padLeft(2, "0");
  product += "$minStr:$secStr";
  return product;
}
