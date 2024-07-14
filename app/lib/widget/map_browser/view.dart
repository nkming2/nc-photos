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
      return HSLColor.fromAHSL(
        1,
        _colorHsl.hue,
        r * .8 + .2,
        (_colorHsl.lightness - (.1 - r * .1)).clamp(0, 1),
      ).toColor();
    } else {
      return HSLColor.fromAHSL(
        1,
        _colorHsl.hue,
        r * .65 + .35,
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
    return (r * 85).toInt() + 75;
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

  late final _colorHsl =
      HSLColor.fromColor(Theme.of(context).colorScheme.primaryContainer);
}

class _PanelContainer extends StatefulWidget {
  const _PanelContainer({
    required this.isShow,
    required this.child,
  });

  @override
  State<StatefulWidget> createState() => _PanelContainerState();

  final bool isShow;
  final Widget child;
}

class _PanelContainerState extends State<_PanelContainer>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: k.animationDurationNormal,
      vsync: this,
      value: 0,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PanelContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isShow != widget.isShow) {
      if (widget.isShow) {
        _animationController.animateTo(1);
      } else {
        _animationController.animateBack(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MatrixTransition(
      animation: _animation,
      onTransform: (animationValue) => Matrix4.identity()
        ..translate(0.0, -(_size.height / 2) * (1 - animationValue), 0.0)
        ..scale(1.0, animationValue, 1.0),
      child: MeasureSize(
        onChange: (size) => setState(() {
          _size = size;
        }),
        child: widget.child,
      ),
    );
  }

  late AnimationController _animationController;
  late Animation<double> _animation;
  var _size = Size.zero;
}

class _DateRangeToggle extends StatelessWidget {
  const _DateRangeToggle();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      onPressed: () {
        context.addEvent(const _OpenDataRangeControlPanel());
      },
      child: const Icon(Icons.date_range_outlined),
    );
  }
}

class _DateRangeControlPanel extends StatelessWidget {
  const _DateRangeControlPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.elevate(theme.colorScheme.surface, 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            offset: Offset(0, 2),
            color: Colors.black26,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    L10n.global().mapBrowserDateRangeLabel,
                    style: Theme.of(context).listTileTheme.titleTextStyle,
                  ),
                ),
                Expanded(
                  child: _BlocSelector<_DateRangeType>(
                    selector: (state) => state.dateRangeType,
                    builder: (context, dateRangeType) =>
                        DropdownButtonFormField<_DateRangeType>(
                      items: _DateRangeType.values
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.toDisplayString()),
                              ))
                          .toList(),
                      value: dateRangeType,
                      onChanged: (value) {
                        if (value != null) {
                          context.addEvent(_SetDateRangeType(value));
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: _BlocSelector<DateRange>(
                    selector: (state) => state.localDateRange,
                    builder: (context, localDateRange) => _DateField(
                      localDateRange.from!,
                      onChanged: (value) {
                        context.addEvent(_SetLocalDateRange(
                            localDateRange.copyWith(from: value.toDate())));
                      },
                    ),
                  ),
                ),
                const Text(" - "),
                Expanded(
                  child: _BlocSelector<DateRange>(
                    selector: (state) => state.localDateRange,
                    builder: (context, localDateRange) => _DateField(
                      localDateRange.to!,
                      onChanged: (value) {
                        context.addEvent(_SetLocalDateRange(
                            localDateRange.copyWith(to: value.toDate())));
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatefulWidget {
  const _DateField(
    this.date, {
    this.onChanged,
  });

  @override
  State<StatefulWidget> createState() => _DateFieldState();

  final Date date;
  final ValueChanged<DateTime>? onChanged;
}

class _DateFieldState extends State<_DateField> {
  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  void didUpdateWidget(covariant _DateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.date != oldWidget.date) {
      _controller.text = _stringify(widget.date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () async {
          final result = await showDatePicker(
            context: context,
            firstDate: DateTime(1970),
            lastDate: clock.now(),
            currentDate: widget.date.toLocalDateTime(),
          );
          if (result == null) {
            return;
          }
          widget.onChanged?.call(result);
        },
        child: IgnorePointer(
          child: ExcludeFocus(
            child: TextFormField(
              controller: _controller,
            ),
          ),
        ),
      ),
    );
  }

  String _stringify(Date date) {
    return intl.DateFormat(intl.DateFormat.YEAR_ABBR_MONTH_DAY,
            Localizations.localeOf(context).languageCode)
        .format(date.toLocalDateTime());
  }

  late final _controller = TextEditingController(text: _stringify(widget.date));
}
