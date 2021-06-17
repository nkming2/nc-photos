import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/widget/animated_visibility.dart';
import 'package:video_player/video_player.dart';

class VideoViewer extends StatefulWidget {
  VideoViewer({
    @required this.account,
    @required this.file,
    this.onLoaded,
    this.onHeightChanged,
    this.onPlay,
    this.onPause,
    this.isControlVisible = false,
    this.canPlay = true,
  });

  @override
  createState() => _VideoViewerState();

  final Account account;
  final File file;
  final VoidCallback onLoaded;
  final void Function(double height) onHeightChanged;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final bool isControlVisible;
  final bool canPlay;
}

class _VideoViewerState extends State<VideoViewer> {
  @override
  initState() {
    super.initState();
    _controller = VideoPlayerController.network(
      api_util.getFileUrl(widget.account, widget.file),
      httpHeaders: {
        "Authorization": Api.getAuthorizationHeaderValue(widget.account),
      },
    )..initialize().then((_) {
        widget.onLoaded?.call();
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_key.currentContext != null) {
            widget.onHeightChanged?.call(_key.currentContext.size.height);
          }
        });
      }).catchError((e, stacktrace) {
        _log.shout("[initState] Filed while initialize", e, stacktrace);
      });
    _controller.addListener(_onControllerChanged);
  }

  @override
  build(BuildContext context) {
    Widget content;
    if (_controller.value.isInitialized) {
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
    _controller?.dispose();
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
            child: VideoPlayer(_controller),
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
        Container(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: kToolbarHeight + 8, left: 16, right: 16),
              child: AnimatedVisibility(
                opacity: widget.isControlVisible ? 1.0 : 0.0,
                duration: k.animationDurationNormal,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  colors: VideoProgressColors(
                    backgroundColor: Colors.white24,
                    bufferedColor: Colors.white38,
                    playedColor: Colors.white,
                  ),
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

  final _key = GlobalKey();
  VideoPlayerController _controller;
  var _isFinished = false;

  static final _log = Logger("widget.video_viewer._VideoViewerState");
}
