part of '../map_browser.dart';

class _MapView extends StatefulWidget {
  const _MapView();

  @override
  State<StatefulWidget> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        _BlocListenerT<List<_DataPoint>>(
          selector: (state) => state.data,
          listener: (context, data) {
            _clusterManager.setItems(data);
          },
        ),
        _BlocListenerT<LatLng?>(
          selector: (state) => state.initialPoint,
          listener: (context, initialPoint) {
            if (initialPoint != null) {
              _mapController
                  ?.animateCamera(CameraUpdate.newLatLngZoom(initialPoint, 10));
            }
          },
        ),
      ],
      child: _BlocBuilder(
        buildWhen: (previous, current) => previous.markers != current.markers,
        builder: (context, state) => GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: const CameraPosition(target: LatLng(0, 0)),
          markers: state.markers,
          onMapCreated: (controller) {
            _clusterManager.setMapId(controller.mapId);
            _mapController = controller;
            if (state.initialPoint != null) {
              controller.animateCamera(
                  CameraUpdate.newLatLngZoom(state.initialPoint!, 10));
            }
          },
          onCameraMove: _clusterManager.onCameraMove,
          onCameraIdle: _clusterManager.updateMap,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            bottom: MediaQuery.of(context).padding.bottom,
          ),
        ),
      ),
    );
  }

  Future<BitmapDescriptor> _getClusterBitmap(
    int size, {
    String? text,
    required Color color,
  }) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint1 = Paint()..color = color;

    const shadowPadding = 6.0;
    const shadowPaddingHalf = shadowPadding / 2;
    final shadowPath = Path()
      ..addOval(
          Rect.fromLTWH(0, 0, size - shadowPadding, size - shadowPadding));
    canvas.drawShadow(shadowPath, Colors.black, 1, false);
    canvas.drawCircle(
      Offset(size / 2 - shadowPaddingHalf, size / 2 - shadowPaddingHalf),
      size / 2 - shadowPaddingHalf,
      paint1,
    );

    if (text != null) {
      TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
      painter.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size / 3.5,
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
      final tone = (r * 30 + 65).toInt();
      return Color(_colorTonalPalette.get(tone));
    } else {
      final tone = (60 - r * 30).toInt();
      return Color(_colorTonalPalette.get(tone));
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
    return (r * 50).toInt() + 90;
  }

  late final _clusterManager = ClusterManager<_DataPoint>(
    const [],
    (markers) {
      if (mounted) {
        context.addEvent(_SetMarkers(markers));
      }
    },
    markerBuilder: (cluster) async => Marker(
      markerId: MarkerId(cluster.getId()),
      position: cluster.location,
      onTap: () {
        final c = Collection(
          name: "",
          contentProvider: CollectionAdHocProvider(
            account: context.bloc.account,
            fileIds: cluster.items.map((e) => e.fileId).toList(),
          ),
        );
        Navigator.of(context).pushNamed(
          CollectionBrowser.routeName,
          arguments: CollectionBrowserArguments(c),
        );
      },
      icon: await _getClusterBitmap(
        _getMarkerSize(cluster.count * 1),
        text: _getMarkerCountString(cluster.count * 1),
        color: _getMarkerColor(cluster.count * 1),
      ),
    ),
  );
  GoogleMapController? _mapController;

  late final _colorTonalPalette = () {
    final hct = Hct.fromInt(Theme.of(context).colorScheme.primary.value);
    return FlexTonalPalette.of(hct.hue, hct.chroma);
  }();
}
