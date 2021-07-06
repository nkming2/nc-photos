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
import 'package:nc_photos/widget/measurable_item_list.dart';
import 'package:nc_photos/widget/selectable.dart';

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

mixin SelectableItemStreamListMixin<T extends StatefulWidget> on State<T> {
  @override
  initState() {
    super.initState();
    _keyboardFocus.requestFocus();
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
  Widget buildItemStreamList({
    @required double maxCrossAxisExtent,
    ValueChanged<double> onMaxExtentChanged,
  }) {
    return MeasurableItemList(
      key: _listKey,
      maxCrossAxisExtent: maxCrossAxisExtent,
      itemCount: _items.length,
      itemBuilder: _buildItem,
      staggeredTileBuilder: (index) => _items[index].staggeredTile,
      onMaxExtentChanged: onMaxExtentChanged,
    );
  }

  @protected
  void clearSelectedItems() {
    _selectedItems.clear();
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
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        (_listKey.currentState as MeasurableItemListState)?.updateListHeight());
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _items[index];
    final content = Padding(
      padding: const EdgeInsets.all(2),
      child: item.buildWidget(context),
    );
    if (item.isSelectable) {
      return Selectable(
        isSelected: _selectedItems.contains(item),
        iconSize: 32,
        onTap: () => _onItemTap(item, index),
        onLongPress: isSelectionMode && platform_k.isWeb
            ? null
            : () => _onItemLongPress(item, index),
        child: content,
      );
    } else {
      return content;
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

  final _items = <SelectableItemStreamListItem>[];
  final _selectedItems = <SelectableItemStreamListItem>{};

  final _listKey = GlobalKey();

  /// used to gain focus on web for keyboard support
  final _keyboardFocus = FocusNode();

  static final _log = Logger(
      "widget.selectable_item_stream_list_mixin.SelectableItemStreamListMixin");
}
