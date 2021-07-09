import 'package:flutter/widgets.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nc_photos/widget/draggable.dart' as _;
import 'package:nc_photos/widget/measurable_item_list.dart';

abstract class DraggableItem {
  Widget buildWidget(BuildContext context);

  /// The widget to show under the pointer when a drag is under way.
  ///
  /// Return null if you wish to just use the same widget as display
  Widget buildDragFeedbackWidget(BuildContext context) => null;

  bool get isDraggable => false;
  DragTargetAccept<DraggableItem> get onDropBefore => null;
  DragTargetAccept<DraggableItem> get onDropAfter => null;
  VoidCallback get onDragStarted => null;
  VoidCallback get onDragEndedAny => null;
  StaggeredTile get staggeredTile => const StaggeredTile.count(1, 1);
}

mixin DraggableItemListMixin<T extends StatefulWidget> on State<T> {
  @protected
  Widget buildDraggableItemList({
    @required double maxCrossAxisExtent,
    ValueChanged<double> onMaxExtentChanged,
  }) {
    _maxCrossAxisExtent = maxCrossAxisExtent;
    return MeasurableItemList(
      maxCrossAxisExtent: maxCrossAxisExtent,
      itemCount: _items.length,
      itemBuilder: _buildItem,
      staggeredTileBuilder: (index) => _items[index].staggeredTile,
      onMaxExtentChanged: onMaxExtentChanged,
    );
  }

  @protected
  set draggableItemList(List<DraggableItem> newItems) {
    _items = newItems;
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _items[index];
    return _.Draggable(
      data: item,
      child: item.buildWidget(context),
      feedback: item.buildDragFeedbackWidget(context),
      onDropBefore: item.onDropBefore,
      onDropAfter: item.onDropAfter,
      onDragStarted: item.onDragStarted,
      onDragEndedAny: item.onDragEndedAny,
      feedbackSize: _maxCrossAxisExtent != null
          ? Size(_maxCrossAxisExtent * .65, _maxCrossAxisExtent * .65)
          : null,
    );
  }

  var _items = <DraggableItem>[];
  double _maxCrossAxisExtent;
}
