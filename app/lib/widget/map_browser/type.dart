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

  late final _minColorHsl =
      HSLColor.fromColor(Theme.of(context).colorScheme.primary)
          .withSaturation(
              Theme.of(context).brightness == Brightness.light ? .9 : .7)
          .withLightness(
              Theme.of(context).brightness == Brightness.light ? .4 : .3);
  late final _maxColorHsl =
      HSLColor.fromColor(Theme.of(context).colorScheme.primary)
          .withSaturation(
              Theme.of(context).brightness == Brightness.light ? .9 : .7)
          .withLightness(
              Theme.of(context).brightness == Brightness.light ? .3 : .2);
}

class _OsmMarkerBuilder extends _MarkerBuilder {
  _OsmMarkerBuilder(super.context);

  Widget build(List<DataPoint> dataPoints) {
    final text = _getMarkerCountString(dataPoints.length);
    return _OsmMarker(
      size: _getMarkerSize(dataPoints.length),
      text: text,
      textSize: _getMarkerTextSize(text, dataPoints.length),
      color: _getMarkerColor(dataPoints.length),
    );
  }

  double _getMarkerSize(int count) {
    final r = _getMarkerRatio(count);
    return (r * 28).toInt() + 28;
  }

  double _getMarkerTextSize(String text, int count) {
    final r = _getMarkerRatio(count);
    return (r * 3) + 9 - ((text.length / 6) * 1);
  }

  Color _getMarkerColor(int count) {
    final r = _getMarkerRatio(count);
    return HSLColor.lerp(_minColorHsl, _maxColorHsl, r)!.toColor();
  }
}

class _GoogleMarkerBuilder extends _MarkerBuilder {
  _GoogleMarkerBuilder(super.context);

  Future<BitmapDescriptor> build(List<DataPoint> dataPoints) {
    return _getClusterBitmap(
      _getMarkerSize(dataPoints.length),
      text: _getMarkerCountString(dataPoints.length),
      color: _getMarkerColor(dataPoints.length),
    );
  }

  double _getMarkerSize(int count) {
    final r = _getMarkerRatio(count);
    return (r * 75).toInt() + 100;
  }

  Color _getMarkerColor(int count) {
    final r = _getMarkerRatio(count);
    return HSLColor.lerp(_minColorHsl, _maxColorHsl, r)!.toColor();
  }

  Future<BitmapDescriptor> _getClusterBitmap(
    double size, {
    String? text,
    required Color color,
  }) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final fillPaint = Paint()..color = color;
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(.75)
      ..strokeWidth = size / 28
      ..style = PaintingStyle.stroke;
    const shadowPadding = 6.0;
    const shadowPaddingHalf = shadowPadding / 2;
    final shadowPath = Path()
      ..addOval(
          Rect.fromLTWH(0, 0, size - shadowPadding, size - shadowPadding));
    canvas.drawShadow(shadowPath, Colors.black, 1, false);
    canvas.drawCircle(
      Offset(size / 2 - shadowPaddingHalf, size / 2 - shadowPaddingHalf),
      size / 2 - shadowPaddingHalf,
      fillPaint,
    );
    canvas.drawCircle(
      Offset(size / 2 - shadowPaddingHalf, size / 2 - shadowPaddingHalf),
      size / 2 - shadowPaddingHalf - (size / 28 / 2),
      outlinePaint,
    );
    if (text != null) {
      TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
      painter.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size / 3 - ((text.length / 6) * (size * 0.1)),
          color: Colors.white.withOpacity(.75),
          fontWeight: FontWeight.normal,
        ),
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(
          size / 2 - painter.width / 2 - shadowPaddingHalf,
          size / 2 - painter.height / 2 - shadowPaddingHalf,
        ),
      );
    }
    final img =
        await pictureRecorder.endRecording().toImage(size.ceil(), size.ceil());
    final data = await img.toByteData(format: ImageByteFormat.png) as ByteData;
    return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
  }
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
