import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/local_file.dart';
import 'package:nc_photos/flutter_util.dart' as flutter_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/android/content_uri_image_provider.dart';
import 'package:nc_photos/np_api_util.dart';
import 'package:nc_photos/widget/cached_network_image_mod.dart' as mod;
import 'package:nc_photos/widget/network_thumbnail.dart';
import 'package:np_codegen/np_codegen.dart';

part 'image_viewer.g.dart';

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

@npLog
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

  static void preloadImage(Account account, FileDescriptor file) {
    LargeImageCacheManager.inst.getFileStream(
      _getImageUrl(account, file),
      headers: {
        "Authorization": AuthUtil.fromAccount(account).toHeaderValue(),
      },
    );
  }

  final Account account;
  final FileDescriptor file;
  final bool canZoom;
  final VoidCallback? onLoaded;
  final ValueChanged<double>? onHeightChanged;
  final VoidCallback? onZoomStarted;
  final VoidCallback? onZoomEnded;
}

@npLog
class _RemoteImageViewerState extends State<RemoteImageViewer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // needed to get rid of the large image blinking during Hero animation
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ImageViewer(
      canZoom: widget.canZoom,
      onHeightChanged: widget.onHeightChanged,
      onZoomStarted: widget.onZoomStarted,
      onZoomEnded: widget.onZoomEnded,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: flutter_util.getImageHeroTag(widget.file),
            flightShuttleBuilder: (flightContext, animation, flightDirection,
                fromHeroContext, toHeroContext) {
              _isHeroDone = false;
              animation.addStatusListener(_animationListener);
              return flutter_util.defaultHeroFlightShuttleBuilder(
                flightContext,
                animation,
                flightDirection,
                fromHeroContext,
                toHeroContext,
              );
            },
            child: CachedNetworkImage(
              fit: BoxFit.contain,
              cacheManager: ThumbnailCacheManager.inst,
              imageUrl: NetworkRectThumbnail.imageUrlForFile(
                  widget.account, widget.file),
              httpHeaders: {
                "Authorization":
                    AuthUtil.fromAccount(widget.account).toHeaderValue(),
              },
              fadeInDuration: const Duration(),
              filterQuality: FilterQuality.high,
              imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
            ),
          ),
          if (_isHeroDone)
            mod.CachedNetworkImage(
              fit: BoxFit.contain,
              cacheManager: LargeImageCacheManager.inst,
              imageUrl: _getImageUrl(widget.account, widget.file),
              httpHeaders: {
                "Authorization":
                    AuthUtil.fromAccount(widget.account).toHeaderValue(),
              },
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
        ],
      ),
    );
  }

  void _onItemLoaded() {
    if (!_isLoaded) {
      _log.info("[_onItemLoaded]");
      _isLoaded = true;
      widget.onLoaded?.call();
    }
  }

  void _animationListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _isHeroDone = true;
      if (mounted) {
        setState(() {});
      }
    }
  }

  var _isLoaded = false;
  // initially set to true such that the large image will show when hero didn't
  // run (i.e., when swiping in viewer)
  var _isHeroDone = true;
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

@npLog
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
            child: IntrinsicHeight(child: widget.child),
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
}

String _getImageUrl(Account account, FileDescriptor file) {
  if (file.fdMime == "image/gif") {
    return api_util.getFileUrl(account, file);
  } else {
    return api_util.getFilePreviewUrl(
      account,
      file,
      width: k.photoLargeSize,
      height: k.photoLargeSize,
      isKeepAspectRatio: true,
    );
  }
}
