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
        _BlocListenerT<MapCoord?>(
          selector: (state) => state.initialPoint,
          listener: (context, initialPoint) {
            if (initialPoint != null) {
              _controller?.setPosition(initialPoint);
            }
          },
        ),
      ],
      child: _BlocBuilder(
        buildWhen: (previous, current) => previous.data != current.data,
        builder: (context, state) {
          final prevPosition =
              context.read<PrefController>().mapBrowserPrevPositionValue;
          return InteractiveMap(
            providerHint: GpsMapProvider.google,
            initialPosition: prevPosition ?? const MapCoord(0, 0),
            initialZoom: prevPosition == null ? 2.5 : 10,
            dataPoints: state.data,
            onClusterTap: (dataPoints) {
              final c = Collection(
                name: "",
                contentProvider: CollectionAdHocProvider(
                  account: context.bloc.account,
                  fileIds: dataPoints
                      .cast<_DataPoint>()
                      .map((e) => e.fileId)
                      .toList(),
                ),
              );
              Navigator.of(context).pushNamed(
                CollectionBrowser.routeName,
                arguments: CollectionBrowserArguments(c),
              );
            },
            googleClusterBuilder: (context, dataPoints) =>
                _GoogleMarkerBuilder(context).build(dataPoints),
            contentPadding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            onMapCreated: (controller) {
              _controller = controller;
              if (state.initialPoint != null) {
                controller.setPosition(state.initialPoint!);
              }
            },
          );
        },
      ),
    );
  }

  InteractiveMapController? _controller;
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
            firstDate: DateTime.fromMillisecondsSinceEpoch(0),
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
