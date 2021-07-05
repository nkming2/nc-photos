import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/session_storage.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/measureable_sliver_staggered_grid.dart';
import 'package:uuid/uuid.dart';

abstract class SelectableItemStreamListItem {
  const SelectableItemStreamListItem({
    this.onTap,
    this.isSelectable = false,
    this.staggeredTile = const StaggeredTile.count(1, 1),
  });

  Widget buildWidget(BuildContext context);

  final VoidCallback onTap;
  final bool isSelectable;
  final StaggeredTile staggeredTile;
}

mixin SelectableItemStreamListMixin<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  @override
  initState() {
    super.initState();
    _keyboardFocus.requestFocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prevOrientation = MediaQuery.of(context).orientation;
      WidgetsBinding.instance.addObserver(this);
    });
  }

  @override
  dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orientation = MediaQuery.of(context).orientation;
      if (orientation != _prevOrientation) {
        _log.info(
            "[didChangeMetrics] updateListHeight: orientation changed: $orientation");
        _prevOrientation = orientation;
        updateListHeight();
      }
    });
  }

  @protected
  Widget buildItemStreamListOuter(
    BuildContext context, {
    @required Widget child,
  }) {
    if (platform_k.isWeb) {
      // support shift+click group selection on web
      return RawKeyboardListener(
        onKey: (ev) {
          _isRangeSelectionMode = ev.isShiftPressed;
        },
        focusNode: _keyboardFocus,
        child: child,
      );
    } else {
      return child;
    }
  }

  @protected
  Widget buildItemStreamList(BuildContext context) {
    // need to rebuild grid after cell size changed
    final cellSize = itemStreamListCellSize;
    if (cellSize != _prevItemStreamListCellSize) {
      _log.info("[buildItemStreamList] updateListHeight: cell size changed");
      WidgetsBinding.instance.addPostFrameCallback((_) => updateListHeight());
      _prevItemStreamListCellSize = cellSize;
    }
    _gridKey = _GridKey("$_uniqueToken $cellSize");
    return MeasurableSliverStaggeredGrid.extentBuilder(
      key: _gridKey,
      maxCrossAxisExtent: itemStreamListCellSize.toDouble(),
      itemCount: _items.length,
      itemBuilder: _buildItem,
      staggeredTileBuilder: (index) => _items[index].staggeredTile,
    );
  }

  @protected
  void onMaxExtentChanged(double newExtent) {}

  @protected
  void clearSelectedItems() {
    _selectedItems.clear();
  }

  @protected
  void updateListHeight() {
    try {
      final renderObj = _gridKey.currentContext.findRenderObject()
          as RenderMeasurableSliverStaggeredGrid;
      final maxExtent = renderObj.calculateExtent();
      _log.info("[updateListHeight] Max extent: $maxExtent");
      if (maxExtent == 0) {
        // ?
        _calculatedMaxExtent = null;
      } else {
        _calculatedMaxExtent = maxExtent;
        onMaxExtentChanged(maxExtent);
      }
    } catch (e, stacktrace) {
      _log.shout("[updateListHeight] Failed while calculateMaxScrollExtent", e,
          stacktrace);
      _calculatedMaxExtent = null;
    }
  }

  @protected
  bool get isSelectionMode => _selectedItems.isNotEmpty;

  @protected
  Iterable<SelectableItemStreamListItem> get selectedListItems =>
      _selectedItems;

  @protected
  List<SelectableItemStreamListItem> get itemStreamListItems =>
      UnmodifiableListView(_items);

  @protected
  set itemStreamListItems(Iterable<SelectableItemStreamListItem> newItems) {
    final lastSelectedItem =
        _lastSelectPosition != null ? _items[_lastSelectPosition] : null;

    _items.clear();
    _items.addAll(newItems);

    _transformSelectedItems();

    // Keep _lastSelectPosition if no changes, drop otherwise
    int newLastSelectPosition;
    try {
      if (lastSelectedItem != null &&
          lastSelectedItem == _items[_lastSelectPosition]) {
        newLastSelectPosition = _lastSelectPosition;
      }
    } catch (_) {}
    _lastSelectPosition = newLastSelectPosition;

    _log.info("[itemStreamListItems] updateListHeight: list item changed");
    WidgetsBinding.instance.addPostFrameCallback((_) => updateListHeight());
  }

  @protected
  int get itemStreamListCellSize;

  @protected
  double get calculatedMaxExtent => _calculatedMaxExtent;

  Widget _buildItem(BuildContext context, int index) {
    final item = _items[index];
    if (item.isSelectable) {
      return _SelectableItemWidget(
        isSelected: _selectedItems.contains(item),
        onTap: () => _onItemTap(item, index),
        onLongPress: isSelectionMode && platform_k.isWeb
            ? null
            : () => _onItemLongPress(item, index),
        child: item.buildWidget(context),
      );
    } else {
      return item.buildWidget(context);
    }
  }

  void _onItemTap(SelectableItemStreamListItem item, int index) {
    if (isSelectionMode) {
      if (!_items.contains(item)) {
        _log.warning("[_onItemTap] Item not found in backing list, ignoring");
        return;
      }
      if (_selectedItems.contains(item)) {
        // unselect
        setState(() {
          _selectedItems.remove(item);
          _lastSelectPosition = null;
        });
      } else {
        // select
        if (_isRangeSelectionMode && _lastSelectPosition != null) {
          setState(() {
            _selectedItems.addAll(_items
                .sublist(math.min(_lastSelectPosition, index),
                    math.max(_lastSelectPosition, index) + 1)
                .where((e) => e.isSelectable));
            _lastSelectPosition = index;
          });
        } else {
          setState(() {
            _lastSelectPosition = index;
            _selectedItems.add(item);
          });
        }
      }
    } else {
      item.onTap?.call();
    }
  }

  void _onItemLongPress(SelectableItemStreamListItem item, int index) {
    if (!_items.contains(item)) {
      _log.warning(
          "[_onItemLongPress] Item not found in backing list, ignoring");
      return;
    }
    final wasSelectionMode = isSelectionMode;
    if (!platform_k.isWeb && wasSelectionMode && _lastSelectPosition != null) {
      setState(() {
        _selectedItems.addAll(_items
            .sublist(math.min(_lastSelectPosition, index),
                math.max(_lastSelectPosition, index) + 1)
            .where((e) => e.isSelectable));
        _lastSelectPosition = index;
      });
    } else {
      setState(() {
        _lastSelectPosition = index;
        _selectedItems.add(item);
      });
    }

    // show notification on first entry to selection mode each session
    if (!wasSelectionMode) {
      if (!SessionStorage().hasShowRangeSelectNotification) {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(platform_k.isWeb
              ? AppLocalizations.of(context).webSelectRangeNotification
              : AppLocalizations.of(context).mobileSelectRangeNotification),
          duration: k.snackBarDurationNormal,
        ));
        SessionStorage().hasShowRangeSelectNotification = true;
      }
    }
  }

  /// Map selected items to the new item list
  void _transformSelectedItems() {
    // TODO too slow!
    final newSelectedItems = _selectedItems
        .map((from) {
          try {
            return _items
                .where((e) => e.isSelectable)
                .firstWhere((to) => from == to);
          } catch (_) {
            return null;
          }
        })
        .where((element) => element != null)
        .toList();
    _selectedItems
      ..clear()
      ..addAll(newSelectedItems);
  }

  int _lastSelectPosition;
  bool _isRangeSelectionMode = false;
  int _prevItemStreamListCellSize;
  double _calculatedMaxExtent;
  Orientation _prevOrientation;

  final _items = <SelectableItemStreamListItem>[];
  final _selectedItems = <SelectableItemStreamListItem>{};

  // this unique token is there to keep the global key unique
  final _uniqueToken = Uuid().v4();
  GlobalObjectKey _gridKey;

  /// used to gain focus on web for keyboard support
  final _keyboardFocus = FocusNode();

  static final _log = Logger(
      "widget.selectable_item_stream_list_mixin.SelectableItemStreamListMixin");
}

class _GridKey extends GlobalObjectKey {
  const _GridKey(Object value) : super(value);
}

class _SelectableItemWidget extends StatelessWidget {
  _SelectableItemWidget({
    Key key,
    @required this.child,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: const EdgeInsets.all(2),
          child: child,
        ),
        if (isSelected)
          Positioned.fill(
            child: Container(
              color: AppTheme.getSelectionOverlayColor(context),
            ),
          ),
        if (isSelected)
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Icon(
                Icons.check_circle_outlined,
                size: 32,
                color: AppTheme.getSelectionCheckColor(context),
              ),
            ),
          ),
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
            ),
          ),
        )
      ],
    );
  }

  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Widget child;
}
