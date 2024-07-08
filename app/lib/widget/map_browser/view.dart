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
  }) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint1 = Paint()..color = Theme.of(context).colorScheme.primary;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, paint1);

    if (text != null) {
      TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
      painter.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size / 3,
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.normal,
        ),
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
      );
    }

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ImageByteFormat.png) as ByteData;

    return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
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
      icon: await _getClusterBitmap(cluster.isMultiple ? 125 : 50,
          text: cluster.isMultiple ? cluster.count.toString() : null),
    ),
  );
  GoogleMapController? _mapController;
}
