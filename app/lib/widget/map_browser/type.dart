part of '../map_browser.dart';

class _DataPoint extends DataPoint {
  const _DataPoint({
    required super.position,
    required this.fileId,
  });

  factory _DataPoint.fromImageLatLng(ImageLatLng src) => _DataPoint(
        position: MapCoord(src.latitude, src.longitude),
        fileId: src.fileId,
      );

  final int fileId;
}

class _MarkerBuilder {
  _MarkerBuilder(this.context);

  String _getMarkerCountString(int count) {
    switch (count) {
      case >= 10000:
        return "10000+";
      case >= 1000:
        return "${count ~/ 1000 * 1000}+";
      case >= 100:
        return "${count ~/ 100 * 100}+";
      case >= 10:
        return "${count ~/ 10 * 10}+";
      default:
        return count.toString();
    }
  }

  double _getMarkerRatio(int count) {
    const step = 1 / 4;
    final double r;
    switch (count) {
      case >= 10000:
        r = 1;
      case >= 1000:
        r = (count ~/ 1000) / 10 * step + step * 3;
      case >= 100:
        r = (count ~/ 100) / 10 * step + step * 2;
      case >= 10:
        r = (count ~/ 10) / 10 * step + step;
      default:
        r = (count / 10) * step;
    }
    return r;
  }

  final BuildContext context;
}

class _OsmMarkerBuilder extends _MarkerBuilder {
  _OsmMarkerBuilder(
    super.context, {
    required this.account,
  });

  Widget build(List<_DataPoint> dataPoints) {
    final text = _getMarkerCountString(dataPoints.length);
    return _OsmMarker(
      account: account,
      fileId: dataPoints.first.fileId,
      size: _getMarkerSize(dataPoints.length),
      color: Theme.of(context).colorScheme.primaryContainer,
      text: text,
      textSize: _getMarkerTextSize(dataPoints.length),
      textColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  double _getMarkerSize(int count) {
    final r = _getMarkerRatio(count);
    return (r * 30).toInt() + 55;
  }

  double _getMarkerTextSize(int count) {
    final r = _getMarkerRatio(count);
    return (r * 3) + 7;
  }

  final Account account;
}

@npLog
class _GoogleMarkerBuilder extends _MarkerBuilder {
  _GoogleMarkerBuilder(
    super.context, {
    required this.account,
  });

  Future<BitmapDescriptor> build(List<_DataPoint> dataPoints) async {
    final size = MediaQuery.sizeOf(context);
    return _GoogleMarkerBitmapBuilder(
      imagePath: await _getImagePath(dataPoints),
      size: _getMarkerSize(dataPoints.length) / 450 * size.width,
      color: Theme.of(context).colorScheme.primaryContainer,
      text: _getMarkerCountString(dataPoints.length),
      textSize: _getMarkerTextSize(dataPoints.length) / 450 * size.width,
      textColor: Theme.of(context).colorScheme.onPrimaryContainer,
    ).build();
  }

  Future<String?> _getImagePath(List<_DataPoint> dataPoints) async {
    try {
      final url = NetworkRectThumbnail.imageUrlForFileId(
          account, dataPoints.first.fileId);
      final fileInfo = await ThumbnailCacheManager.inst.getSingleFile(
        url,
        headers: {
          "authorization": AuthUtil.fromAccount(account).toHeaderValue(),
        },
      );
      return fileInfo.absolute.path;
    } catch (e, stackTrace) {
      _log.severe(
          "[_getImagePath] Failed to get file path for fileId: ${dataPoints.first.fileId}",
          e,
          stackTrace);
      return null;
    }
  }

  double _getMarkerSize(int count) {
    final r = _getMarkerRatio(count);
    return (r * 105).toInt() + 192;
  }

  double _getMarkerTextSize(int count) {
    final r = _getMarkerRatio(count);
    return (r * 10.5) + 24.5;
  }

  final Account account;
}

@npLog
class _GoogleMarkerBitmapBuilder {
  _GoogleMarkerBitmapBuilder({
    required this.imagePath,
    required this.size,
    required this.color,
    required this.text,
    required this.textSize,
    required this.textColor,
  });

  Future<BitmapDescriptor> build() async {
    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    _drawBackgroundShadow(canvas);
    canvas.clipPath(_makeBackgroundPath());
    _drawBackground(canvas);
    if (imagePath != null) {
      await _drawImage(canvas);
    }
    _drawText(canvas);
    _drawBorder(canvas);

    final img =
        await pictureRecorder.endRecording().toImage(size.ceil(), size.ceil());
    final data = await img.toByteData(format: ImageByteFormat.png) as ByteData;
    return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
  }

  void _drawBackgroundShadow(Canvas canvas) {
    final shadowPath = _makeBackgroundPath();
    canvas.drawShadow(shadowPath, Colors.black, 1, false);
  }

  void _drawBackground(Canvas canvas) {
    canvas.drawColor(color, BlendMode.src);
  }

  Future<void> _drawImage(Canvas canvas) async {
    try {
      final imageData = await File(imagePath!).readAsBytes();
      final imageDescriptor = await ImageDescriptor.encoded(
        await ImmutableBuffer.fromUint8List(imageData),
      );
      final codec = await imageDescriptor.instantiateCodec();
      final frame = await codec.getNextFrame();
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTRB(0, 0, size - _shadowPadding, size - _shadowPadding),
        image: frame.image,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
      );
    } catch (e, stackTrace) {
      _log.severe(
          "[_drawImage] Failed to draw image: $imagePath", e, stackTrace);
    }
  }

  void _drawText(Canvas canvas) {
    final textPaint = TextPainter(textDirection: TextDirection.ltr);
    textPaint.text = TextSpan(
      text: text,
      style: TextStyle(fontSize: textSize, color: textColor),
    );
    textPaint.layout();
    final y = size - textPaint.height - _shadowPadding - size * .07;

    final fillPaint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTRB(0, y - size * .04, size, size), fillPaint);

    textPaint.paint(
      canvas,
      Offset(size / 2 - textPaint.width / 2 - _shadowPaddingHalf, y),
    );
  }

  void _drawBorder(Canvas canvas) {
    final outlinePaint = Paint()
      ..color = Color.alphaBlend(Colors.white.withOpacity(.75), color)
      ..strokeWidth = size * .04
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      Offset(size / 2 - _shadowPaddingHalf, size / 2 - _shadowPaddingHalf),
      size / 2 - _shadowPaddingHalf - (size * .04 / 2),
      outlinePaint,
    );
  }

  Path _makeBackgroundPath() {
    return Path()
      ..addOval(
          Rect.fromLTWH(0, 0, size - _shadowPadding, size - _shadowPadding));
  }

  final String? imagePath;
  final double size;
  final Color color;
  final String text;
  final double textSize;
  final Color textColor;

  static const _shadowPadding = 6.0;
  static const _shadowPaddingHalf = _shadowPadding / 2;
}

enum _DateRangeType {
  thisMonth,
  prevMonth,
  thisYear,
  custom,
  ;

  String toDisplayString() {
    switch (this) {
      case thisMonth:
        return L10n.global().mapBrowserDateRangeThisMonth;
      case prevMonth:
        return L10n.global().mapBrowserDateRangePrevMonth;
      case thisYear:
        return L10n.global().mapBrowserDateRangeThisYear;
      case custom:
        return L10n.global().mapBrowserDateRangeCustom;
    }
  }
}
