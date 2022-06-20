import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/entity/file.dart' as app;
import 'package:nc_photos/entity/local_file.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/android/content_uri_image_provider.dart';
import 'package:nc_photos/widget/cached_network_image_mod.dart' as mod;

class LocalImageViewer extends StatefulWidget {
  const LocalImageViewer({
    Key? key,
    required this.file,
    required this.canZoom,
    this.onLoaded,
    this.onHeightChanged,
    this.onZoomStarted,
    this.onZoomEnded,
  }) : super(key: key);

  @override
  createState() => _LocalImageViewerState();

  final LocalFile file;
  final bool canZoom;
  final VoidCallback? onLoaded;
  final ValueChanged<double>? onHeightChanged;
  final VoidCallback? onZoomStarted;
  final VoidCallback? onZoomEnded;
}

class _LocalImageViewerState extends State<LocalImageViewer> {
  @override
  build(BuildContext context) {
    final ImageProvider provider;
    if (widget.file is LocalUriFile) {
      provider = ContentUriImage((widget.file as LocalUriFile).uri);
    } else {
      throw ArgumentError("Invalid file");
    }

    return _ImageViewer(
      canZoom: widget.canZoom,
      onHeightChanged: widget.onHeightChanged,
      onZoomStarted: widget.onZoomStarted,
      onZoomEnded: widget.onZoomEnded,
      child: Image(
        image: provider,
        fit: BoxFit.contain,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onItemLoaded();
          });
          return child;
        },
      ),
    );
  }

  void _onItemLoaded() {
    if (!_isLoaded) {
      _log.info("[_onItemLoaded] ${widget.file.logTag}");
      _isLoaded = true;
      widget.onLoaded?.call();
    }
  }

  var _isLoaded = false;

  static final _log = Logger("widget.image_viewer._LocalImageViewerState");
}

class RemoteImageViewer extends StatefulWidget {
  const RemoteImageViewer({
    Key? key,
    required this.account,
    required this.file,
    required this.canZoom,
    this.onLoaded,
    this.onHeightChanged,
    this.onZoomStarted,
    this.onZoomEnded,
  }) : super(key: key);

  @override
  createState() => _RemoteImageViewerState();

  static void preloadImage(Account account, app.File file) {
    LargeImageCacheManager.inst.getFileStream(
      _getImageUrl(account, file),
      headers: {
        "Authorization": Api.getAuthorizationHeaderValue(account),
      },
    );
  }

  final Account account;
  final app.File file;
  final bool canZoom;
  final VoidCallback? onLoaded;
  final ValueChanged<double>? onHeightChanged;
  final VoidCallback? onZoomStarted;
  final VoidCallback? onZoomEnded;
}

class _RemoteImageViewerState extends State<RemoteImageViewer> {
  @override
  build(BuildContext context) => _ImageViewer(
        canZoom: widget.canZoom,
        onHeightChanged: widget.onHeightChanged,
        onZoomStarted: widget.onZoomStarted,
        onZoomEnded: widget.onZoomEnded,
        child: mod.CachedNetworkImage(
          cacheManager: LargeImageCacheManager.inst,
          imageUrl: _getImageUrl(widget.account, widget.file),
          httpHeaders: {
            "Authorization": Api.getAuthorizationHeaderValue(widget.account),
          },
          fit: BoxFit.contain,
          fadeInDuration: const Duration(),
          filterQuality: FilterQuality.high,
          imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
          imageBuilder: (context, child, imageProvider) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _onItemLoaded();
            });
            const SizeChangedLayoutNotification().dispatch(context);
            return child;
          },
        ),
      );

  void _onItemLoaded() {
    if (!_isLoaded) {
      _log.info("[_onItemLoaded]");
      _isLoaded = true;
      widget.onLoaded?.call();
    }
  }

  var _isLoaded = false;

  static final _log = Logger("widget.image_viewer._RemoteImageViewerState");
}

class _ImageViewer extends StatefulWidget {
  const _ImageViewer({
    Key? key,
    required this.child,
    required this.canZoom,
    this.onHeightChanged,
    this.onZoomStarted,
    this.onZoomEnded,
  }) : super(key: key);

  @override
  createState() => _ImageViewerState();

  final Widget child;
  final bool canZoom;
  final ValueChanged<double>? onHeightChanged;
  final VoidCallback? onZoomStarted;
  final VoidCallback? onZoomEnded;
}

class _ImageViewerState extends State<_ImageViewer>
    with TickerProviderStateMixin {
  @override
  build(BuildContext context) {
    final content = InteractiveViewer(
      minScale: 1.0,
      maxScale: 3.5,
      transformationController: _transformationController,
      panEnabled: widget.canZoom && _isZoomed,
      scaleEnabled: widget.canZoom,
      // allow the image to be zoomed to fill the whole screen
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        alignment: Alignment.center,
        child: NotificationListener<SizeChangedLayoutNotification>(
          onNotification: (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_key.currentContext != null) {
                widget.onHeightChanged?.call(_key.currentContext!.size!.height);
              }
            });
            return false;
          },
          child: SizeChangedLayoutNotifier(
            key: _key,
            child: widget.child,
          ),
        ),
      ),
    );
    if (widget.canZoom) {
      return Listener(
        onPointerDown: (_) {
          ++_finger;
          if (_finger >= 2) {
            _setIsZooming(true);
          }
        },
        onPointerUp: (event) {
          --_finger;
          if (_finger < 2) {
            _setIsZooming(false);
          }
          _prevFingerPosition = event.position;
        },
        onPointerCancel: (event) {
          --_finger;
          if (_finger < 2) {
            _setIsZooming(false);
          }
        },
        onPointerSignal: (event) {
          if (event is PointerScrollEvent &&
              event.kind == PointerDeviceKind.mouse) {
            if (event.scrollDelta.dy < 0) {
              // scroll up
              _setIsZooming(true);
            } else if (event.scrollDelta.dy > 0) {
              // scroll down
              _setIsZooming(false);
            }
          }
        },
        child: GestureDetector(
          onDoubleTap: () {
            if (_isZoomed) {
              // restore transformation
              _autoZoomOut();
            } else {
              _autoZoomIn();
            }
          },
          child: content,
        ),
      );
    } else {
      return content;
    }
  }

  @override
  dispose() {
    super.dispose();
    _transformationController.dispose();
  }

  void _setIsZooming(bool flag) {
    _isZooming = flag;
    final next = _isZoomed;
    if (next != _wasZoomed) {
      _wasZoomed = next;
      _log.info("[_setIsZooming] Is zoomed: $next");
      if (next) {
        widget.onZoomStarted?.call();
      } else {
        widget.onZoomEnded?.call();
      }
    }
  }

  bool get _isZoomed =>
      _isZooming || _transformationController.value.getMaxScaleOnAxis() != 1.0;

  /// Called when double tapping the image to zoom in to the default level
  void _autoZoomIn() {
    final animController =
        AnimationController(duration: k.animationDurationShort, vsync: this);
    final originX = -_prevFingerPosition.dx / 2;
    final originY = -_prevFingerPosition.dy / 2;
    final anim = Matrix4Tween(
            begin: Matrix4.identity(),
            end: Matrix4.identity()
              ..scale(2.0)
              ..translate(originX, originY))
        .animate(animController);
    animController
      ..addListener(() {
        _transformationController.value = anim.value;
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _setIsZooming(false);
        }
      })
      ..forward();
    _setIsZooming(true);
  }

  /// Called when double tapping the zoomed image to zoom out
  void _autoZoomOut() {
    final animController =
        AnimationController(duration: k.animationDurationShort, vsync: this);
    final anim = Matrix4Tween(
            begin: _transformationController.value, end: Matrix4.identity())
        .animate(animController);
    animController
      ..addListener(() {
        _transformationController.value = anim.value;
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _setIsZooming(false);
        }
      })
      ..forward();
    _setIsZooming(true);
  }

  final _key = GlobalKey();
  final _transformationController = TransformationController();

  var _isZooming = false;
  var _wasZoomed = false;

  int _finger = 0;
  var _prevFingerPosition = const Offset(0, 0);

  static final _log = Logger("widget.image_viewer._ImageViewerState");
}

String _getImageUrl(Account account, app.File file) {
  if (file.contentType == "image/gif") {
    return api_util.getFileUrl(account, file);
  } else {
    return api_util.getFilePreviewUrl(
      account,
      file,
      width: k.photoLargeSize,
      height: k.photoLargeSize,
      a: true,
    );
  }
}
