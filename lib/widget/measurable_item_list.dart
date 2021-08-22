import 'package:flutter/widgets.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/widget/measureable_sliver_staggered_grid.dart';
import 'package:uuid/uuid.dart';

abstract class MeasurableItemListState {
  void updateListHeight();
}

class MeasurableItemList extends StatefulWidget {
  MeasurableItemList({
    Key? key,
    required this.maxCrossAxisExtent,
    required this.itemCount,
    required this.itemBuilder,
    required this.staggeredTileBuilder,
    this.mainAxisSpacing = 0,
    this.onMaxExtentChanged,
  }) : super(key: key);

  @override
  createState() => _MeasurableItemListState();

  final double maxCrossAxisExtent;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedStaggeredTileBuilder staggeredTileBuilder;
  final double mainAxisSpacing;
  final ValueChanged<double?>? onMaxExtentChanged;
}

class _MeasurableItemListState extends State<MeasurableItemList>
    with WidgetsBindingObserver
    implements MeasurableItemListState {
  @override
  initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _prevOrientation = MediaQuery.of(context).orientation;
      WidgetsBinding.instance!.addObserver(this);
    });
  }

  @override
  dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  didChangeMetrics() {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      final orientation = MediaQuery.of(context).orientation;
      if (orientation != _prevOrientation) {
        _log.info(
            "[didChangeMetrics] updateListHeight: orientation changed: $orientation");
        _prevOrientation = orientation;
        updateListHeight();
      }
    });
  }

  @override
  build(BuildContext context) {
    // on mobile, LayoutBuilder conflicts with TextFields.
    // See https://github.com/flutter/flutter/issues/63919
    return SliverLayoutBuilder(builder: (context, constraints) {
      if (_prevListWidth == null) {
        _prevListWidth = constraints.crossAxisExtent;
      }
      if (constraints.crossAxisExtent != _prevListWidth) {
        _log.info("[build] updateListHeight: list viewport width changed");
        WidgetsBinding.instance!
            .addPostFrameCallback((_) => updateListHeight());
        _prevListWidth = constraints.crossAxisExtent;
      }

      // need to rebuild grid after cell size changed
      final cellSize = widget.maxCrossAxisExtent;
      if (_prevCellSize == null) {
        _prevCellSize = cellSize;
      }
      if (cellSize != _prevCellSize) {
        _log.info("[build] updateListHeight: cell size changed");
        WidgetsBinding.instance!
            .addPostFrameCallback((_) => updateListHeight());
        _prevCellSize = cellSize;
      }
      _gridKey = _GridKey("$_uniqueToken $cellSize");
      return MeasurableSliverStaggeredGrid.extentBuilder(
        key: _gridKey,
        maxCrossAxisExtent: widget.maxCrossAxisExtent,
        itemCount: widget.itemCount,
        itemBuilder: widget.itemBuilder,
        staggeredTileBuilder: widget.staggeredTileBuilder,
        mainAxisSpacing: widget.mainAxisSpacing,
      );
    });
  }

  @override
  updateListHeight() {
    double? newMaxExtent;
    try {
      final renderObj = _gridKey.currentContext!.findRenderObject()
          as RenderMeasurableSliverStaggeredGrid;
      final maxExtent = renderObj.calculateExtent();
      _log.info("[updateListHeight] Max extent: $maxExtent");
      if (maxExtent == 0) {
        // ?
        newMaxExtent = null;
      } else {
        newMaxExtent = maxExtent;
      }
    } catch (e, stacktrace) {
      _log.shout("[updateListHeight] Failed while calculateMaxScrollExtent", e,
          stacktrace);
      newMaxExtent = null;
    }

    if (newMaxExtent != _maxExtent) {
      _maxExtent = newMaxExtent;
      widget.onMaxExtentChanged?.call(newMaxExtent);
    }
  }

  double? _prevListWidth;
  double? _prevCellSize;
  double? _maxExtent;
  Orientation? _prevOrientation;

  // this unique token is there to keep the global key unique
  final _uniqueToken = Uuid().v4();
  late GlobalObjectKey _gridKey;

  static final _log =
      Logger("widget.measurable_item_list._MeasurableItemListState");
}

class _GridKey extends GlobalObjectKey {
  const _GridKey(Object value) : super(value);
}
