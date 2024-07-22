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

class _GoogleMarkerBuilder {
  _GoogleMarkerBuilder(this.context);

  Future<BitmapDescriptor> build(List<DataPoint> dataPoints) {
    return _getClusterBitmap(
      _getMarkerSize(dataPoints.length),
      text: _getMarkerCountString(dataPoints.length),
      color: _getMarkerColor(dataPoints.length),
    );
  }

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

  Color _getMarkerColor(int count) {
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
    if (Theme.of(context).brightness == Brightness.light) {
      return HSLColor.fromAHSL(
        1,
        _colorHsl.hue,
        r * .7 + .3,
        (_colorHsl.lightness - (.1 - r * .1)).clamp(0, 1),
      ).toColor();
    } else {
      return HSLColor.fromAHSL(
        1,
        _colorHsl.hue,
        r * .6 + .4,
        (_colorHsl.lightness - (.1 - r * .1)).clamp(0, 1),
      ).toColor();
    }
  }

  int _getMarkerSize(int count) {
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
    return (r * 85).toInt() + 85;
  }

  Future<BitmapDescriptor> _getClusterBitmap(
    int size, {
    String? text,
    required Color color,
  }) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final fillPaint = Paint()..color = color;
    final outlinePaint = Paint()
      ..color = Theme.of(context).brightness == Brightness.light
          ? Colors.black.withOpacity(.28)
          : Colors.white.withOpacity(.6)
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
          color: Theme.of(context).colorScheme.onPrimaryContainer,
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
    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ImageByteFormat.png) as ByteData;
    return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
  }

  final BuildContext context;

  late final _colorHsl =
      HSLColor.fromColor(Theme.of(context).colorScheme.primaryContainer);
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
